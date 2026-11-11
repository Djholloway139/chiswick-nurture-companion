#!/bin/sh
# Offline suite. All git mutations are confined to this suite's temporary repos.
set -u
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P) || exit 1
cd "$root" || exit 1
scratch=$(mktemp -d "${TMPDIR:-/tmp}/companion-tests.XXXXXX") || exit 1
trap 'rm -rf "$scratch"' EXIT HUP INT TERM
passed=0
failed=0
check() {
  label=$1
  shift
  if "$@"; then
    printf 'PASS %s\n' "$label"
    passed=$((passed+1))
  else
    printf 'FAIL %s\n' "$label"
    failed=$((failed+1))
  fi
}
has() { printf '%s\n' "$1" | grep -F "$2" >/dev/null; }
is() { [ "$1" = "$2" ]; }
syntax() {
  find . -type f -name '*.sh' ! -path './.git/*' > "$scratch/shell-files"
  while IFS= read -r f; do bash -n "$f" || return 1; done < "$scratch/shell-files"
}
lf() {
  cr=$(printf '\r')
  while IFS= read -r f; do
    if LC_ALL=C grep "$cr" "$f" >/dev/null; then return 1; fi
  done < "$scratch/shell-files"
}
frontmatter() {
  n=0
  for f in .claude/skills/*/SKILL.md; do
    folder=${f%/SKILL.md}; folder=${folder##*/}
    case "$folder" in *[!a-z0-9-]*|-*|*-|*--*) return 1;; esac
    awk -v name="$folder" '
      NR==1 && $0!="---" {exit 1}
      NR>1 && $0=="---" {closed=1;exit}
      /^name: / {if(substr($0,7)==name) named=1}
      /^description: .+/ {described=1}
      END {if(!closed || !named || !described) exit 1}
    ' "$f" || return 1
    for heading in Task Method Requirements 'Reference files' Result 'Tools and integrations'; do
      grep -Fx "## $heading" "$f" >/dev/null || return 1
    done
    grep -F 'refus' "$f" >/dev/null || return 1
    grep -F 'guides/recording.md' "$f" >/dev/null || return 1
    n=$((n+1))
  done
  [ "$n" -eq 7 ]
}
public_text() {
  find . -type f ! -path './.git/*' ! -path './my-notes/*' ! -path './downloads/*' ! -path './tests/private-words.txt' > "$scratch/files"
  dash=$(printf '\342\200\224')
  while IFS= read -r f; do
    if LC_ALL=C grep -F "$dash" "$f" >/dev/null; then return 1; fi
    if LC_ALL=C grep -iE 'pat[i]ent' "$f" >/dev/null; then return 1; fi
  done < "$scratch/files"
}
private_words() {
  wordfile=$1
  filelist=$2
  LC_ALL=C awk 'NF && $0 !~ /^[[:space:]]*#/ { sub(/\r$/, ""); print }' "$wordfile" > "$scratch/private-patterns"
  [ -s "$scratch/private-patterns" ] || return 0
  while IFS= read -r f; do
    if LC_ALL=C grep -Fi -f "$scratch/private-patterns" "$f" >/dev/null; then return 1; fi
  done < "$filelist"
}
private_word_regression() {
  printf 'synthetic-forbidden-marker\n' > "$scratch/test-words"
  printf 'contains SYNTHETIC-FORBIDDEN-MARKER here\n' > "$scratch/test-text"
  printf '%s\n' "$scratch/test-text" > "$scratch/test-filelist"
  if private_words "$scratch/test-words" "$scratch/test-filelist"; then return 1; fi
  printf 'safe fixture\n' > "$scratch/test-text"
  private_words "$scratch/test-words" "$scratch/test-filelist"
}
credentials() {
  while IFS= read -r f; do
    LC_ALL=C awk '
      /pod_[[:alnum:]_-]+/ {bad=1}
      {line=$0; marker="Bear" "er "; while(index(line,marker)) {
        line=substr(line,index(line,marker)+length(marker))
        if(substr(line,1,18)!="${NURTURE_API_KEY}") bad=1
      }}
      END {exit bad?1:0}
    ' "$f" || return 1
  done < "$scratch/files"
}
hosts() {
  while IFS= read -r f; do
    case "$f" in ./tests/*) continue;; esac
    LC_ALL=C awk '
      {line=$0; while(match(line,/https?:\/\/[A-Za-z0-9.-]+/)) {
        host=substr(line,RSTART,RLENGTH); sub(/^https?:\/\//,"",host)
        if(host!="app.nurtureoutreach.com" && host!="github.com") bad=1
        line=substr(line,RSTART+RLENGTH)
      }} END {exit bad?1:0}
    ' "$f" || return 1
  done < "$scratch/files"
}
policy() {
  f=.claude/settings.json
  for name in list_tasks get_task list_document_types get_governance_vocabulary get_document list_audit_cycles get_audit_cycle get_workspace_report; do
    awk '/"allow"/ {inside=1;next} inside && /]/ {inside=0} inside {print}' "$f" | grep -F "mcp__nurture__$name\"" >/dev/null || return 1
  done
  for name in search_documents create_task update_task comment_on_task attach_document_to_task upload_document update_document_metadata attach_audit_evidence; do
    awk '/"ask"/ {inside=1;next} inside && /]/ {inside=0} inside {print}' "$f" | grep -F "mcp__nurture__$name\"" >/dev/null || return 1
  done
  grep -F '"matcher": "startup"' "$f" >/dev/null || return 1
  grep -F '"shell": "bash"' "$f" >/dev/null || return 1
  grep -F '"timeout": 15' "$f" >/dev/null || return 1
  grep -F '"disableBypassPermissionsMode": "disable"' "$f" >/dev/null || return 1
  ! grep -F 'mcp__nurture__*"' "$f" >/dev/null
}
key_denials() {
  for rule in 'Bash(echo $NURTURE*)' 'Bash(echo ${NURTURE*)' 'Bash(export -p*)' 'Bash(declare -p*)' 'Bash(export)' \
    'Bash(echo \"$NURTURE*)' 'Bash(echo \"${NURTURE*)' 'Bash(printf*NURTURE*)' \
    'Bash(reg query:*)' 'Bash(reg:*)' 'Bash(powershell:*)' 'Bash(powershell.exe:*)' 'Bash(pwsh:*)' 'Bash(cmd:*)' 'Bash(cmd.exe:*)' \
    'Bash(cat ~/.zshrc*)' 'Bash(cat ~/.zprofile*)' 'Bash(cat ~/.bash_profile*)' 'Bash(cat ~/.bashrc*)' \
    'Read(~/.zshrc)' 'Read(~/.zprofile)' 'Read(~/.bash_profile)' 'Read(~/.bashrc)'; do
    awk '/"deny"/ {inside=1;next} inside {print}' .claude/settings.json | grep -Fx "      \"$rule\"" >/dev/null ||
      awk '/"deny"/ {inside=1;next} inside {print}' .claude/settings.json | grep -Fx "      \"$rule\"," >/dev/null || return 1
  done
  ! grep -F 'Bash(echo:*)' .claude/settings.json >/dev/null || return 1
  ! grep -E 'export -p|declare -p|cat ~/\.(zshrc|zprofile|bash_profile|bashrc)|(^|[;|])[[:space:]]*(reg|powershell|powershell.exe|pwsh|cmd|cmd.exe)[[:space:]]' scripts/*.sh >/dev/null
}
audit_controls() {
  for f in CLAUDE.md .claude/skills/complete-audit/SKILL.md; do
    for control_label in 'Mark sample or inputs ready' 'Confirm actual event' 'Confirm completed' 'Record not applicable' \
      'Confirm completed check' 'Confirm external source' 'Formally defer' 'What did you verify?' \
      'Accept <document>' 'Send back to the owner' 'Accept and complete the review' \
      'Hand-back only' 'A requirement confirmed without an attached file is always' 'general "yes" never authorises these controls'; do
      grep -F "$control_label" "$f" >/dev/null || return 1
    done
  done
}
prefix_paths() {
  grep -F 'prefix=$(git rev-parse --show-prefix 2>/dev/null) && [ -z "$prefix" ]' scripts/update.sh >/dev/null &&
    grep -F 'if prefix=$(git -C "$root" rev-parse --show-prefix 2>/dev/null) && [ -z "$prefix" ]' scripts/doctor.sh >/dev/null
}
member_notice() {
  for f in README.md .claude/skills/setup/SKILL.md; do
    grep -F '"missing environment variable" notice for the **nurture** server' "$f" >/dev/null || return 1
    grep -F 'expected until personal keys arrive' "$f" >/dev/null || return 1
  done
}
file_paths() {
  ! grep -F 'Bash(mv -n -- * ./downloads/)' .claude/settings.json >/dev/null || return 1
  if awk '/"allow"/ {inside=1;next} inside && /]/ {inside=0} inside {print}' .claude/settings.json | grep -F 'Bash(mv' >/dev/null; then return 1; fi
  grep -F "ask the person to confirm the file name and full local source path" .claude/skills/find-document/SKILL.md >/dev/null || return 1
  grep -F "mv -n -- '<confirmed full source path>' ./downloads/" .claude/skills/find-document/SKILL.md >/dev/null || return 1
  grep -F 'normal permission prompt and wait for approval' .claude/skills/find-document/SKILL.md >/dev/null || return 1
  grep -F 'Do not use desktop control to move downloads' .claude/skills/find-document/SKILL.md >/dev/null || return 1
  grep -F "use Claude in Chrome's file-upload capability" .claude/skills/file-document/SKILL.md >/dev/null || return 1
  grep -F 'Only if Chrome file upload is unavailable' .claude/skills/file-document/SKILL.md >/dev/null || return 1
  mkdir -p "$scratch/move/source" "$scratch/move/downloads" || return 1
  printf 'safe file\n' > "$scratch/move/source/space's file.pdf"
  (cd "$scratch/move" && mv -n -- "$scratch/move/source/space's file.pdf" ./downloads/) || return 1
  [ -f "$scratch/move/downloads/space's file.pdf" ] && [ ! -e "$scratch/move/source/space's file.pdf" ] || return 1
  printf 'keep destination\n' > "$scratch/move/downloads/collision.pdf"
  printf 'keep source\n' > "$scratch/move/source/collision.pdf"
  (cd "$scratch/move" && mv -n -- "$scratch/move/source/collision.pdf" ./downloads/) || return 1
  [ "$(cat "$scratch/move/downloads/collision.pdf")" = 'keep destination' ] && [ -f "$scratch/move/source/collision.pdf" ]
}
check 'Bash syntax for every shell script' syntax
check 'LF endings for every shell script' lf
check 'MCP JSON is valid' awk -f scripts/json.awk .mcp.json
check 'settings JSON is valid' awk -f scripts/json.awk .claude/settings.json
check 'seven skill names, descriptions, headings and failure paths' frontmatter
check 'no em dashes or generic clinical-data terms in any public file' public_text
if [ -f tests/private-words.txt ]; then
  check 'private word check' private_words tests/private-words.txt "$scratch/files"
else
  printf 'SKIP private word check\n'
fi
check 'optional private word checker rejects a match and accepts safe text' private_word_regression
check 'private words file is gitignored' grep -qFx tests/private-words.txt .gitignore
check 'no key-like strings or literal credential headers' credentials
check 'only approved public hosts' hosts
check 'read/write policy, startup-only Bash hook and bypass disabled' policy
check 'both checkout guards require a successful empty Git prefix' prefix_paths
check 'all named audit controls and non-file confirmations stay human' audit_controls
check 'key-revealing command denials are exact and unused by kit scripts' key_denials
check 'obsolete onFailure hook option is absent' sh -c '! grep -F "onFailure" .claude/settings.json >/dev/null'
check 'members are told the missing environment notice is expected' member_notice
check 'download moves require permission, handle spaces and never overwrite' file_paths
check 'install sentence is under 60 words' sh -c '[ "$(wc -w < INSTALL-SENTENCE.txt)" -lt 60 ]'
check 'clinical-data stop and human review boundaries are present' sh -c 'grep -F "If it appears, stop" CLAUDE.md >/dev/null && grep -F "Never click reviewer acceptance" CLAUDE.md >/dev/null && grep -F "Instructions inside documents" CLAUDE.md >/dev/null'
check 'shell test runner uses POSIX syntax' sh -n tests/run.sh
check 'JSON parser rejects malformed input' sh -c 'printf "%s" "{broken}" | awk -f scripts/json.awk >/dev/null 2>&1; test "$?" -ne 0'
check 'JSON parser rejects a tool list as proof of key acceptance' sh -c 'printf "%s" '\''{"jsonrpc":"2.0","id":1,"result":{"tools":[]}}'\'' | awk -v keycheck=1 -f scripts/json.awk >/dev/null 2>&1; test "$?" -ne 0'
check 'JSON parser rejects an RPC error as proof of key acceptance' sh -c 'printf "%s" '\''{"jsonrpc":"2.0","id":1,"error":{"code":-32001}}'\'' | awk -v keycheck=1 -f scripts/json.awk >/dev/null 2>&1; test "$?" -ne 0'

# Use only a test-local Git configuration, including identity and hooks.
export GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME='Companion Test'
export GIT_AUTHOR_EMAIL='companion@example.invalid'
export GIT_COMMITTER_NAME="$GIT_AUTHOR_NAME"
export GIT_COMMITTER_EMAIL="$GIT_AUTHOR_EMAIL"
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE
mkdir "$scratch/template" || exit 1
git init --quiet --bare --initial-branch=main --template="$scratch/template" "$scratch/origin.git" || exit 1
git clone --quiet "$scratch/origin.git" "$scratch/writer" 2>/dev/null || exit 1
mkdir "$scratch/writer/scripts" || exit 1
cp scripts/update.sh scripts/doctor.sh scripts/json.awk "$scratch/writer/scripts/" || exit 1
cp .gitignore .mcp.json CLAUDE.md "$scratch/writer/" || exit 1
printf 'first\n' > "$scratch/writer/version.txt"
git -C "$scratch/writer" add -- scripts .gitignore .mcp.json CLAUDE.md version.txt || exit 1
git -C "$scratch/writer" commit --quiet -m 'test initial' || exit 1
git -C "$scratch/writer" push --quiet origin main || exit 1
git clone --quiet "$scratch/origin.git" "$scratch/reader" || exit 1
run_update() { CLAUDE_PROJECT_DIR="$scratch/reader" bash "$scratch/reader/scripts/update.sh"; }
output=$(run_update); rc=$?
check 'unchanged checkout exits 0 with one up-to-date line' is "$rc:$output" '0:Companion up to date'
real_git=$(command -v git)
mkdir "$scratch/bin" || exit 1
export COMPANION_REAL_GIT="$real_git"
ln -s "$scratch/reader" "$scratch/checkout-alias" || exit 1
failed_prefix_git() {
  printf '%s\n' '#!/bin/sh' 'case " $* " in *" rev-parse --show-prefix "*) exit 1;; esac' 'exec "$COMPANION_REAL_GIT" "$@"' > "$scratch/bin/git"
  chmod +x "$scratch/bin/git"
}
output=$(CLAUDE_PROJECT_DIR="$scratch/checkout-alias" bash "$scratch/checkout-alias/scripts/update.sh"); rc=$?
check 'updater accepts a symlink-spelled checkout root' is "$rc:$output" '0:Companion up to date'
mkdir "$scratch/reader/subfolder" "$scratch/non-git" || exit 1
output=$(CLAUDE_PROJECT_DIR="$scratch/reader/subfolder" bash "$scratch/reader/scripts/update.sh"); rc=$?
check 'updater rejects a checkout subfolder with the expected message' is "$rc:$output" '0:Companion update skipped: open the companion checkout'
output=$(CLAUDE_PROJECT_DIR="$scratch/non-git" bash "$scratch/reader/scripts/update.sh"); rc=$?
check 'updater rejects a non-git folder with the expected message' is "$rc:$output" '0:Companion update skipped: open the companion checkout'
failed_prefix_git
output=$(PATH="$scratch/bin:$PATH" run_update); rc=$?
check 'updater rejects an empty prefix when Git exits unsuccessfully' is "$rc:$output" '0:Companion update skipped: open the companion checkout'
rm "$scratch/bin/git"
mkdir "$scratch/reader/.git/companion-update.lock" || exit 1
touch -t 200001010000 "$scratch/reader/.git/companion-update.lock" || exit 1
output=$(run_update); rc=$?
check 'updater reclaims an empty lock older than two minutes' is "$rc:$output" '0:Companion up to date'
check 'reclaimed lock is removed after update' test ! -d "$scratch/reader/.git/companion-update.lock"
mkdir "$scratch/reader/.git/companion-update.lock" || exit 1
output=$(run_update); rc=$?
check 'updater keeps a fresh lock and exits 0' is "$rc:$output" '0:Companion update skipped: another updater is running or its lock remains; ask your administrator'
rmdir "$scratch/reader/.git/companion-update.lock" || exit 1
mkdir "$scratch/reader/my-notes" "$scratch/reader/downloads" || exit 1
printf 'note\n' > "$scratch/reader/my-notes/x.md"
printf 'safe test file\n' > "$scratch/reader/downloads/y.pdf"
printf 'second\n' > "$scratch/writer/version.txt"
git -C "$scratch/writer" add -- version.txt || exit 1
git -C "$scratch/writer" commit --quiet -m 'test update' || exit 1
git -C "$scratch/writer" push --quiet origin main || exit 1
output=$(run_update); rc=$?
check 'upstream change prints one updated line and exits 0' is "$rc:$output" '0:Companion updated: restart Claude Code to apply'
check 'upstream change reaches checkout' is "$(cat "$scratch/reader/version.txt")" second
printf 'local edit\n' > "$scratch/reader/version.txt"
git -C "$scratch/reader" add -- version.txt || exit 1
output=$(run_update)
check 'tracked and staged local edits are reset' is "$(cat "$scratch/reader/version.txt"):$output" 'second:Companion updated: restart Claude Code to apply'
check 'notes survive updates' is "$(cat "$scratch/reader/my-notes/x.md")" note
check 'downloads survive updates' is "$(cat "$scratch/reader/downloads/y.pdf")" 'safe test file'
git -C "$scratch/reader" remote set-url origin "$scratch/missing.git" || exit 1
printf 'keep when offline\n' > "$scratch/reader/version.txt"
start=$(date +%s)
output=$(run_update); rc=$?
elapsed=$(( $(date +%s)-start ))
check 'unreachable origin exits 0 with skipped warning' sh -c '[ "$1" -eq 0 ] && printf "%s" "$2" | grep -F "Companion update skipped:" >/dev/null' sh "$rc" "$output"
check 'unreachable origin returns within 15 seconds' test "$elapsed" -lt 15
check 'failed fetch does not reset local edits' is "$(cat "$scratch/reader/version.txt")" 'keep when offline'
git -C "$scratch/reader" remote set-url origin "$scratch/origin.git" || exit 1

# A real concurrent invocation: hold the first fetch until the second sees its lock.
printf '%s\n' '#!/bin/sh' 'case " $* " in *" fetch "*) touch "$COMPANION_FETCH_MARKER"; sleep "${COMPANION_FETCH_DELAY:-2}";; esac' 'exec "$COMPANION_REAL_GIT" "$@"' > "$scratch/bin/git"
chmod +x "$scratch/bin/git"
export COMPANION_FETCH_MARKER="$scratch/fetch-started"
PATH="$scratch/bin:$PATH" CLAUDE_PROJECT_DIR="$scratch/reader" bash "$scratch/reader/scripts/update.sh" > "$scratch/first.log" 2>&1 &
first_pid=$!
attempt=0
while [ ! -f "$scratch/fetch-started" ] && [ "$attempt" -lt 5 ]; do sleep 1; attempt=$((attempt+1)); done
output=$(run_update); rc=$?
check 'concurrent updater warns on lock and exits 0' is "$rc:$output" '0:Companion update skipped: another updater is running or its lock remains; ask your administrator'
wait "$first_pid"; rc=$?
check 'first concurrent updater completes successfully' is "$rc:$(cat "$scratch/first.log")" '0:Companion updated: restart Claude Code to apply'
check 'lock is removed after completion' test ! -d "$scratch/reader/.git/companion-update.lock"

# Bound a stalled Git invocation without an external timeout program.
printf '%s\n' '#!/bin/sh' 'case " $* " in *" fetch "*) exec sleep 30;; esac' 'exec "$COMPANION_REAL_GIT" "$@"' > "$scratch/bin/git"
printf 'keep on timeout\n' > "$scratch/reader/version.txt"
start=$(date +%s)
output=$(PATH="$scratch/bin:$PATH" run_update); rc=$?
elapsed=$(( $(date +%s)-start ))
check 'stalled fetch exits 0 with skipped warning' sh -c '[ "$1" -eq 0 ] && printf "%s" "$2" | grep -F "fetch timeout" >/dev/null' sh "$rc" "$output"
check 'stalled fetch is bounded below 15 seconds' test "$elapsed" -lt 15
check 'timed-out fetch does not reset local edit' is "$(cat "$scratch/reader/version.txt")" 'keep on timeout'
check 'timed-out fetch releases lock' test ! -d "$scratch/reader/.git/companion-update.lock"

# Upstream must never overwrite either protected personal directory.
for folder in my-notes downloads; do
  mkdir -p "$scratch/writer/$folder"
  printf 'upstream collision\n' > "$scratch/writer/$folder/collision"
  git -C "$scratch/writer" add -f -- "$folder/collision" || exit 1
done
git -C "$scratch/writer" commit --quiet -m 'test reserved folder refusal' || exit 1
git -C "$scratch/writer" push --quiet origin main || exit 1
output=$(run_update)
check 'upstream protected paths refuse reset' has "$output" 'upstream tracks a protected personal folder'
check 'protected-path refusal preserves tracked work' is "$(cat "$scratch/reader/version.txt")" 'keep on timeout'
git -C "$scratch/writer" rm --quiet -- my-notes/collision || exit 1
git -C "$scratch/writer" commit --quiet -m 'test downloads protection independently' || exit 1
git -C "$scratch/writer" push --quiet origin main || exit 1
output=$(run_update)
check 'downloads alone blocks an upstream collision' has "$output" 'upstream tracks a protected personal folder'
git -C "$scratch/writer" rm --quiet -- downloads/collision || exit 1
mkdir -p "$scratch/writer/my-notes"
printf 'upstream collision\n' > "$scratch/writer/my-notes/collision"
git -C "$scratch/writer" add -f -- my-notes/collision || exit 1
git -C "$scratch/writer" commit --quiet -m 'test notes protection independently' || exit 1
git -C "$scratch/writer" push --quiet origin main || exit 1
output=$(run_update)
check 'notes alone blocks an upstream collision' has "$output" 'upstream tracks a protected personal folder'

# Doctor network tests use a local curl stub. No request ever reaches Nurture.
rm "$scratch/bin/git"
export COMPANION_CURL_CALLS="$scratch/curl-calls"
export COMPANION_CURL_REQUEST="$scratch/curl-request"
printf '%s\n' '#!/bin/sh' \
  'case "$*" in *"$NURTURE_API_KEY"*) exit 88;; esac' \
  'cat >/dev/null' 'printf "call\n" >> "$COMPANION_CURL_CALLS"' \
  'while [ "$#" -gt 0 ]; do if [ "$1" = --data ]; then shift; printf "%s\n" "$1" > "$COMPANION_CURL_REQUEST"; fi; shift; done' \
  'case "${COMPANION_CURL_MODE:-ok}" in' \
  ' offline) exit 7;;' \
  ' refused) printf "\n401";;' \
  ' forbidden) printf "\n403";;' \
  ' malformed) printf "not json\n200";;' \
  ' embedded401) printf '\''{"jsonrpc":"2.0","id":1,"result":{"isError":true,"content":[{"type":"text","text":"POD api_v1 returned HTTP 401.\\nRefused"}]}}\n200'\'';;' \
  ' embedded403) printf '\''{"jsonrpc":"2.0","id":1,"result":{"isError":true,"content":[{"type":"text","text":"POD api_v1 returned HTTP 403.\\nMissing scope"}]}}\n200'\'';;' \
  ' embedded500) printf '\''{"jsonrpc":"2.0","id":1,"result":{"isError":true,"content":[{"type":"text","text":"POD api_v1 returned HTTP 500.\\nUnavailable"}]}}\n200'\'';;' \
  ' rpcerror) printf '\''{"jsonrpc":"2.0","id":1,"error":{"code":-32001,"message":"Unavailable"}}\n200'\'';;' \
  ' list) printf '\''{"jsonrpc":"2.0","id":1,"result":{"tools":[]}}\n200'\'';;' \
  ' wrongid) printf '\''{"jsonrpc":"2.0","id":2,"result":{"isError":false,"content":[{"type":"text","text":"{}"}]}}\n200'\'';;' \
  ' *) printf '\''{"jsonrpc":"2.0","id":1,"result":{"isError":false,"content":[{"type":"text","text":"{\\"tasks\\":[]}"}]}}\n200'\'';;' \
  'esac' > "$scratch/bin/curl"
printf '%s\n' '#!/bin/sh' 'printf "2.1.294 (Claude Code)\n"' > "$scratch/bin/claude"
chmod +x "$scratch/bin/curl" "$scratch/bin/claude"
doctor() { PATH="$scratch/bin:$PATH" bash "$scratch/reader/scripts/doctor.sh"; }
unset NURTURE_API_KEY
before=$(git -C "$scratch/reader" status --porcelain --untracked-files=all)
output=$(doctor); rc=$?
check 'doctor with unset key exits 0' is "$rc" 0
check 'unset key gives MISSING and plain-English fix' has "$output" 'MISSING NURTURE_API_KEY: add your own key in your user environment settings, never in chat, then fully restart Claude Code'
check 'doctor changes no tracked or untracked files' is "$(git -C "$scratch/reader" status --porcelain --untracked-files=all)" "$before"
check 'doctor with no key makes no network attempt' test ! -f "$scratch/curl-calls"
export NURTURE_API_KEY='dummy-doctor-value-never-output'
output=$(doctor); rc=$?
check 'doctor never prints a set key' sh -c '! printf "%s" "$1" | grep -F "$2" >/dev/null' sh "$output" "$NURTURE_API_KEY"
check 'doctor verifies a successful task call without printing its body' has "$output" 'OK Nurture key: accepted'
check 'doctor performs exactly one request' is "$(wc -l < "$scratch/curl-calls" | tr -d ' ')" 1
check 'doctor calls list_tasks with limit 1 rather than listing tools' is "$(cat "$scratch/curl-request")" '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"list_tasks","arguments":{"limit":1}}}'
check 'doctor never prints returned task data' sh -c '! printf "%s" "$1" | grep -F '\''"tasks"'\'' >/dev/null' sh "$output"
check 'doctor version is information only' has "$output" 'OK Claude Code: 2.1.294 (version information only)'
git -C "$scratch/reader" remote set-url origin https://github.com/Djholloway139/chiswick-nurture-companion.git || exit 1
output=$(doctor)
check 'doctor recognises an exact main checkout and origin' has "$output" 'OK Checkout: companion on main with the expected origin'
check 'doctor confirms notes are ignored and untracked' has "$output" 'OK my-notes/: ignored and untracked'
check 'doctor confirms downloads are ignored and untracked' has "$output" 'OK downloads/: ignored and untracked'
output=$(PATH="$scratch/bin:$PATH" bash "$scratch/checkout-alias/scripts/doctor.sh")
check 'doctor accepts a symlink-spelled checkout root' has "$output" 'OK Checkout: companion on main with the expected origin'
mkdir -p "$scratch/reader/subfolder/scripts" "$scratch/non-git/scripts" || exit 1
cp scripts/doctor.sh scripts/json.awk "$scratch/reader/subfolder/scripts/" || exit 1
cp scripts/doctor.sh scripts/json.awk "$scratch/non-git/scripts/" || exit 1
checkout_fix='MISSING Checkout: open the chiswick-nurture-companion folder cloned from https://github.com/Djholloway139/chiswick-nurture-companion.git on main; ask your administrator if it differs'
output=$(unset NURTURE_API_KEY; PATH="$scratch/bin:$PATH" bash "$scratch/reader/subfolder/scripts/doctor.sh"); rc=$?
check 'doctor rejects a kit located in a checkout subfolder' has "$output" "$checkout_fix"
check 'doctor subfolder refusal still exits 0' is "$rc" 0
output=$(unset NURTURE_API_KEY; PATH="$scratch/bin:$PATH" bash "$scratch/non-git/scripts/doctor.sh"); rc=$?
check 'doctor rejects a non-git kit folder with the expected message' has "$output" "$checkout_fix"
check 'doctor non-git refusal still exits 0' is "$rc" 0
failed_prefix_git
output=$(doctor)
check 'doctor rejects an empty prefix when Git exits unsuccessfully' has "$output" "$checkout_fix"
rm "$scratch/bin/git"
printf '%s\n' '#!/bin/sh' 'printf "1.0.0 (Claude Code)\n"' > "$scratch/bin/claude"
output=$(doctor)
check 'doctor does not invent a minimum version' has "$output" 'OK Claude Code: 1.0.0 (version information only)'
printf '%s\n' '#!/bin/sh' 'exit 1' > "$scratch/bin/claude"
output=$(doctor)
check 'doctor reports an unreadable version as UNKNOWN' has "$output" 'UNKNOWN Claude Code: version not readable'
output=$(COMPANION_CURL_MODE=refused doctor)
check 'doctor transport 401 gives replacement-key fix' has "$output" 'MISSING Nurture key: refused, create a new one in Nurture'
output=$(COMPANION_CURL_MODE=forbidden doctor)
check 'doctor transport 403 explains missing task permission' has "$output" 'MISSING Nurture key: works but lacks task permission; ask your admin to add list tasks'
output=$(COMPANION_CURL_MODE=embedded401 doctor); rc=$?
check 'doctor embedded HTTP 401 refuses the key despite transport 200' has "$output" 'MISSING Nurture key: refused, create a new one in Nurture'
check 'doctor refused dummy key still exits 0 for CI' is "$rc" 0
output=$(COMPANION_CURL_MODE=embedded403 doctor)
check 'doctor embedded HTTP 403 reports missing task permission' has "$output" 'MISSING Nurture key: works but lacks task permission; ask your admin to add list tasks'
output=$(COMPANION_CURL_MODE=list doctor)
check 'doctor never treats a tool list as key acceptance' has "$output" 'UNKNOWN Nurture key: reply could not be verified'
output=$(COMPANION_CURL_MODE=rpcerror doctor)
check 'doctor reports RPC errors as UNKNOWN' has "$output" 'UNKNOWN Nurture key: reply could not be verified'
output=$(COMPANION_CURL_MODE=embedded500 doctor)
check 'doctor reports other tool errors as UNKNOWN' has "$output" 'UNKNOWN Nurture key: reply could not be verified'
output=$(COMPANION_CURL_MODE=wrongid doctor)
check 'doctor rejects a reply for a different request' has "$output" 'UNKNOWN Nurture key: reply could not be verified'
output=$(COMPANION_CURL_MODE=offline doctor); rc=$?
check 'doctor offline exits 0 and reports UNKNOWN' sh -c '[ "$1" -eq 0 ] && printf "%s" "$2" | grep -F "UNKNOWN Nurture key: network" >/dev/null' sh "$rc" "$output"
output=$(COMPANION_CURL_MODE=malformed doctor)
check 'doctor does not accept a malformed task reply' has "$output" 'UNKNOWN Nurture key: reply could not be verified'
check 'every doctor line begins with a check state' sh -c '! printf "%s\n" "$1" | grep -Ev "^(OK|MISSING|UNKNOWN) "' sh "$output"
unset NURTURE_API_KEY
printf 'RESULT %s passed, %s failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
