#!/bin/sh
# Offline checks. No real Git writes, network or credential inspection.
set -u
unset NURTURE_API_KEY COMPANION_STARTUP_KEY
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P) || exit 1
cd "$root" || exit 1
scratch=$(mktemp -d "${TMPDIR:-/tmp}/companion-tests.XXXXXX") || exit 1
trap 'rm -rf "$scratch"' EXIT HUP INT TERM
passed=0; failed=0
check() {
  label=$1; shift
  if "$@"; then printf 'PASS %s\n' "$label"; passed=$((passed+1))
  else printf 'FAIL %s\n' "$label"; failed=$((failed+1)); fi
}
has() { printf '%s\n' "$1" | grep -F "$2" >/dev/null; }
absent() { ! has "$1" "$2"; }
is() { [ "$1" = "$2" ]; }
for path in scripts/*.sh tests/*.sh; do check "$path Bash syntax" bash -n "$path"; done
for path in tests/*.sh; do check "$path POSIX syntax" sh -n "$path"; done
check 'settings strict JSON' awk -f scripts/json.awk .claude/settings.json
check 'CLAUDE.md only imports AGENTS.md' is "$(cat CLAUDE.md)" '@AGENTS.md'
check 'release version uses numeric x.y.z' sh -c 'grep -Ex "[0-9]+\.[0-9]+\.[0-9]+" VERSION >/dev/null && [ "$(wc -l < VERSION | tr -d " ")" -eq 1 ]'
check 'changelog contains current release heading' grep -Fxq "## $(cat VERSION)" CHANGELOG.md
check 'product drift scan' sh tests/drift.sh
check 'personal folders and skill aliases ignored' sh -c '
  for name in my-notes downloads .agents/skills; do
    git check-ignore -q --no-index "$name/check" || exit 1
    [ -z "$(git ls-files -- "$name")" ] || exit 1
  done'
check 'no tracked Git symlinks' sh -c '! git ls-files --stage | grep "^120000 "'
check 'server ask rule, no Nurture allow or tool rules' sh -c '
  grep -F "\"mcp__nurture\"" .claude/settings.json >/dev/null &&
  ! grep -E "mcp__nurture__" .claude/settings.json >/dev/null &&
  grep -F "\"allow\": []" .claude/settings.json >/dev/null'
while IFS= read -r rule; do
  check "preserved protection $rule" grep -Fq "$rule" .claude/settings.json
done < tests/key-denials.txt
check 'startup, resume and guarded prompt hooks use documented fields' sh -c '
  grep -F "\"matcher\": \"startup\"" .claude/settings.json >/dev/null &&
  grep -F "scripts/startup.sh" .claude/settings.json >/dev/null &&
  grep -F "scripts/startup.sh\\\" resume" .claude/settings.json >/dev/null &&
  grep -F "scripts/prompt.sh" .claude/settings.json >/dev/null &&
  grep -F "\"onFailure\": \"block\"" .claude/settings.json >/dev/null &&
  grep -F "\"UserPromptSubmit\"" .claude/settings.json >/dev/null &&
  grep -F "\"disableBypassPermissionsMode\": \"disable\"" .claude/settings.json >/dev/null &&
  grep -F "\"disableAutoMode\": \"disable\"" .claude/settings.json >/dev/null'
check 'all commands have fallback and confirmation instructions' sh -c '
  for file in .claude/skills/*/SKILL.md; do
    grep -F "guides/browser.md" "$file" >/dev/null || exit 1
    grep -i "confirmation:" "$file" >/dev/null || exit 1
  done'
check 'ordinary split preserves linking before cancellation' sh -c '
  grep -F "Only after all replacements exist" .claude/skills/split-task/SKILL.md >/dev/null &&
  grep -F "Never cancel early" .claude/skills/split-task/SKILL.md >/dev/null'
check 'human exceptions and dedicated deferral remain explicit' sh -c '
  grep -F "Accepting a review and closing an audit are always" AGENTS.md >/dev/null &&
  grep -F "Never emulate either action with generic task status or labels" .claude/skills/complete-audit/SKILL.md >/dev/null'
check 'owned prose and scripts use LF and no forbidden prose' sh -c '
  dash=$(printf "\342\200\224"); cr=$(printf "\r")
  ! grep -En "$dash|$cr|[q]uietly" AGENTS.md CLAUDE.md README.md CHANGELOG.md guides/*.md install/*.md scripts/*.sh .claude/skills/*/SKILL.md'
# Clearly synthetic mutations exercise structure, including install/.
mkdir -p "$scratch/drift/install" "$scratch/drift/scripts"
for fixture in \
  'mcp__synthetic_server__synthetic_operation' \
  '"properties": {"synthetic_field": {}}' \
  '| parameter | synthetic_field |' \
  'limit: 37' \
  '37 KiB' \
  '{"error":"Synthetic refusal for structural testing."}' \
  'Click the button "Synthetic control".' \
  'position: 37'; do
  printf '%s\n' "$fixture" > "$scratch/drift/install/synthetic.md"
  if sh tests/drift.sh "$scratch/drift" >/dev/null; then check "drift rejects synthetic structure: $fixture" false
  else check "drift rejects synthetic structure: $fixture" true; fi
done
rm "$scratch/drift/install/synthetic.md"
printf '%s\n' 'print vals["/synthetic_receipt_field"]' > "$scratch/drift/scripts/json.awk"
if sh tests/drift.sh "$scratch/drift" >/dev/null; then check 'drift rejects application fields in protocol parser' false
else check 'drift rejects application fields in protocol parser' true; fi
rm "$scratch/drift/scripts/json.awk"
printf '%s\n' 'Use the synthetic_capability after live discovery.' > "$scratch/drift/install/synthetic.md"
check 'drift allows a capability reference' sh tests/drift.sh "$scratch/drift"
check 'read-only jobs do not require comments' sh -c '
  grep -F "Reads need no recording and no tracking task" guides/recording.md >/dev/null &&
  grep -F "A successful write needs no extra result comment" guides/recording.md >/dev/null &&
  ! grep -E "Before a job, agree|without a recorded, verified result|and result comment|and the tracking comment" AGENTS.md .claude/skills/*/SKILL.md guides/*.md'
# Windows key box tests use only a scratch kit and a synthetic password.
keykit="$scratch/key kit"
mkdir -p "$keykit/scripts" "$scratch/keybin"
cp scripts/save-key.sh scripts/key.sh scripts/nurture-headers.sh scripts/json.awk "$keykit/scripts/"
cp .mcp.json "$keykit/"
cat > "$scratch/keybin/uname" <<'UNAME'
#!/bin/sh
printf '%s\n' "${TEST_KEY_OS:-MINGW64_NT-10.0}"
UNAME
cat > "$scratch/keybin/powershell.exe" <<'POWERSHELL'
#!/bin/sh
[ "$#" -eq 3 ] && [ "$1" = -NoProfile ] && [ "$2" = -EncodedCommand ] || exit 90
[ "${NURTURE_KEY_PROMPT:-}" = 'Paste your Nurture key, then click Save. Claude cannot see what you type here.' ] || exit 91
case "$3" in ''|*[!A-Za-z0-9+/=]*) exit 94 ;; esac
decoded=$(printf '%s' "$3" | base64 -d | iconv -f UTF-16LE -t UTF-8) || exit 94
[ "$(printf '%s\n' "$decoded" | wc -l | tr -d ' ')" = 1 ] || exit 95
case "$decoded" in *'$env:NURTURE_KEY_PROMPT'*) ;; *) exit 92 ;; esac
case "$decoded" in *'$args'*|*-NonInteractive*) exit 93 ;; esac
printf 'matched\n' > "$TEST_KEY_KIT/prompt-contract"
case "${TEST_KEY_MODE:-saved}" in
  saved) printf 'synthetic-popup-marker'; exit 0 ;;
  cancel) exit 3 ;;
  error) printf 'Synthetic box failure.\r\nSynthetic detail to omit.'; exit 2 ;;
  launch) printf 'synthetic-popup-marker'; printf 'synthetic-popup-marker' >&2; exit 127 ;;
esac
POWERSHELL
cat > "$scratch/keybin/osascript" <<'OSASCRIPT'
#!/bin/sh
[ "$#" -eq 9 ] || exit 90
for last do :; done
[ "$last" = 'Paste your Nurture key, then click Save. Claude cannot see what you type here.' ] || exit 91
[ "${TEST_KEY_MODE:-saved}" != cancel ] || exit 1
printf 'synthetic-popup-marker'
OSASCRIPT
chmod +x "$scratch/keybin/uname" "$scratch/keybin/powershell.exe" "$scratch/keybin/osascript"
export TEST_KEY_KIT="$keykit"
key_bash=$(command -v bash)
keybox() { PATH="${TEST_KEY_PATH:-$scratch/keybin:$PATH}" "$key_bash" "$keykit/scripts/save-key.sh"; }
output=$(keybox); rc=$?
check 'Windows prompt succeeds through the environment message contract' is "$rc" 0
check 'Windows prompt decodes to one line with no positional message or NonInteractive' is "$(cat "$keykit/prompt-contract")" matched
check 'saved prompt reports only status' is "$output" 'SAVED: key stored in this folder only'
check 'saved prompt stores only the synthetic key in scratch' is "$(cat "$keykit/.env")" 'NURTURE_API_KEY=synthetic-popup-marker'
output=$(TEST_KEY_MODE=cancel keybox); rc=$?
check 'real prompt cancellation fails without saving' is "$rc" 1
check 'real prompt cancellation has its own message' is "$output" 'NOT SAVED: cancelled'
output=$(TEST_KEY_MODE=error keybox); rc=$?
check 'prompt error fails without saving' is "$rc" 1
check 'prompt error reports only its first line' is "$output" 'NOT SAVED: the key box failed: Synthetic box failure.; send this line to Dan'
output=$(TEST_KEY_MODE=launch keybox 2>&1); rc=$?
check 'unknown PowerShell failure fails without saving' is "$rc" 1
check 'unknown PowerShell failure is distinct from cancel' has "$output" 'NOT SAVED: the key box failed:'
check 'unknown PowerShell stdout and stderr remain private' absent "$output" synthetic-popup-marker
for missing in iconv base64; do
  toolbin="$scratch/missing-$missing"
  mkdir -p "$toolbin"
  cp "$scratch/keybin/uname" "$toolbin/"
  ln -s "$(command -v dirname)" "$toolbin/dirname"
  case "$missing" in iconv) other=base64 ;; base64) other=iconv ;; esac
  ln -s "$(command -v "$other")" "$toolbin/$other"
  output=$(TEST_KEY_PATH="$toolbin" keybox 2>&1); rc=$?
  check "missing $missing stops the key box" is "$rc" 1
  check "missing $missing gives the required safe message" is "$output" 'NOT SAVED: the key box failed: Git Bash tools missing; send this line to Dan'
done
check 'cancel and failures preserve the previous synthetic key' is "$(cat "$keykit/.env")" 'NURTURE_API_KEY=synthetic-popup-marker'
output=$(TEST_KEY_OS=Darwin keybox); rc=$?
check 'Mac prompt still saves' is "$rc" 0
output=$(TEST_KEY_OS=Darwin TEST_KEY_MODE=cancel keybox); rc=$?
check 'Mac cancellation message is unchanged' is "$output" 'NOT SAVED: cancelled'
# A minimal repository fixture allows real read-only Git aliases without init.
mkdir -p "$keykit/.git/objects" "$keykit/.git/refs"
printf 'ref: refs/heads/main\n' > "$keykit/.git/HEAD"
helper_command=$(awk -v mode=string-at-path -v target_path=/mcpServers/nurture/headersHelper -f scripts/json.awk .mcp.json)
check 'MCP config is strict JSON' awk -f scripts/json.awk .mcp.json
check 'header command extraction decodes JSON quotes' is "$helper_command" 'git -c "alias.nurture-headers=!bash scripts/nurture-headers.sh" nurture-headers'
helper_started=$(date +%s)
helper_output=$(cd "$keykit" && /bin/sh -c "$helper_command" 2>"$scratch/helper-stderr"); rc=$?
helper_elapsed=$(($(date +%s)-helper_started))
check 'configured helper runs via sh in scratch project' is "$rc" 0
check 'configured helper yields an Authorization JSON object' sh -c '
  printf "%s" "$1" | awk -v mode=object-member -v member=Authorization -f scripts/json.awk' sh "$helper_output"
check 'configured helper reads the synthetic scratch key' is "$helper_output" '{"Authorization":"Bearer synthetic-popup-marker"}'
check 'configured helper produces no stderr' test ! -s "$scratch/helper-stderr"
check 'configured helper finishes inside ten seconds' test "$helper_elapsed" -lt 10
helper_output=$(cd "$keykit/scripts" && /bin/sh -c "$helper_command" 2>/dev/null)
check 'Git alias runs from repository top level' is "$helper_output" '{"Authorization":"Bearer synthetic-popup-marker"}'
rm "$keykit/.env"
helper_output=$(cd "$keykit" && /bin/sh -c "$helper_command" 2>/dev/null)
check 'configured helper with no scratch key yields empty object' is "$helper_output" '{}'
unset TEST_KEY_KIT
# Link tests run against a path containing spaces and a simulated checkout replacement.
mkdir -p "$scratch/kit space/scripts" "$scratch/kit space/.claude/skills/demo"
cp scripts/sync-skills.sh "$scratch/kit space/scripts/"
printf 'first\n' > "$scratch/kit space/.claude/skills/demo/SKILL.md"
check 'create local skill links' bash "$scratch/kit space/scripts/sync-skills.sh"
check 'both names identify one file, with no symlink' bash -c '
  [ "$1/.claude/skills/demo/SKILL.md" -ef "$1/.agents/skills/demo/SKILL.md" ] &&
  [ ! -L "$1/.agents/skills/demo/SKILL.md" ]' bash "$scratch/kit space"
printf 'second\n' > "$scratch/replacement"
mv "$scratch/replacement" "$scratch/kit space/.claude/skills/demo/SKILL.md"
check 'refresh links after source inode replacement' bash "$scratch/kit space/scripts/sync-skills.sh"
check 'refreshed alias sees release content' is "$(cat "$scratch/kit space/.agents/skills/demo/SKILL.md")" second
rm "$scratch/kit space/.claude/skills/demo/SKILL.md"
check 'retired skill aliases removed' bash "$scratch/kit space/scripts/sync-skills.sh"
check 'retired alias directory removed' test ! -e "$scratch/kit space/.agents/skills/demo"
mkdir -p "$scratch/linkbin"
printf 'third\n' > "$scratch/kit space/.claude/skills/demo/SKILL.md"
printf '%s\n' '#!/bin/sh' 'cp "$1" "$2"' > "$scratch/linkbin/ln"
chmod +x "$scratch/linkbin/ln"
output=$(PATH="$scratch/linkbin:$PATH" bash "$scratch/kit space/scripts/sync-skills.sh"); rc=$?
check 'link creation refuses a filesystem copy' is "$rc" 1
check 'copy fallback is explained' has "$output" 'link became a copy'
check 'failed link leaves no false alias' test ! -e "$scratch/kit space/.agents/skills/demo/SKILL.md"
# Fake Git records intended calls, never invokes real Git.
mkdir -p "$scratch/bin" "$scratch/repo/scripts" "$scratch/repo/.git"
cp scripts/update.sh "$scratch/repo/scripts/"
export COMPANION_TEST_DIR="$scratch"
export CLAUDE_PROJECT_DIR="$scratch/repo"
printf '1.0.0\n' > "$scratch/repo/VERSION"
printf '# Changes\n\n## 1.2.0\n\n- New job.\n\n## 1.1.0\n\n- Another job.\n\n## 1.0.0\n\n- Old job.\n' > "$scratch/new-changelog"
printf 'keep me\n' > "$scratch/repo/personal-note"
cat > "$scratch/bin/git" <<'GIT'
#!/bin/sh
[ -z "${NURTURE_API_KEY:-}" ] || exit 99
printf '%s\n' "$*" >> "$COMPANION_TEST_DIR/git-calls"
while [ "$#" -gt 0 ]; do
  case "$1" in -c|-C) shift 2 ;; *) break ;; esac
done
case "$1" in
 rev-parse)
  case "$2" in --show-prefix) [ "${TEST_PREFIX:-ok}" != fail ] || exit 1 ;;
    --git-dir) printf '.git\n' ;;
    HEAD) printf 'old\n' ;;
    origin/main) printf '%s\n' "${TEST_REMOTE:-new}" ;;
  esac ;;
 symbolic-ref) printf '%s\n' "${TEST_BRANCH:-main}" ;;
 remote) printf '%s\n' "${TEST_ORIGIN:-https://github.com/Djholloway139/chiswick-nurture-companion.git}" ;;
 fetch) [ "${TEST_FETCH:-ok}" = ok ] ;;
 ls-tree) [ "${TEST_RESERVED:-no}" != yes ] || printf 'my-notes/file\n' ;;
 show) printf '%s\n' "${TEST_VERSION:-1.2.0}" ;;
 cat-file|diff) exit 0 ;;
 reset)
  [ "$2" = --hard ] || exit 1
  [ "${TEST_RESET:-ok}" = ok ] || exit 1
  printf '1.2.0\n' > VERSION
  cp "$COMPANION_TEST_DIR/new-changelog" CHANGELOG.md ;;
 *) exit 98 ;;
esac
GIT
chmod +x "$scratch/bin/git"
export PATH="$scratch/bin:$PATH"
updater() { bash "$scratch/repo/scripts/update.sh" "$1"; }
output=$(updater resume)
check 'resume announces ready' has "$output" 'update ready, restart to apply'
check 'resume leaves version unchanged' is "$(cat "$scratch/repo/VERSION")" 1.0.0
check 'resume never resets' absent "$(cat "$scratch/git-calls")" 'reset --hard'
check 'check time stored in .git' test -f "$scratch/repo/.git/companion-last-check"
: > "$scratch/git-calls"
output=$(updater daily)
check 'daily within interval does not fetch' absent "$(cat "$scratch/git-calls")" 'fetch'
check 'daily repeats pending restart notice' has "$output" 'update ready, restart to apply'
printf '1\n' > "$scratch/repo/.git/companion-last-check"
: > "$scratch/git-calls"
output=$(updater daily)
check 'daily after interval fetches' has "$(cat "$scratch/git-calls")" 'fetch'
check 'daily never resets' absent "$(cat "$scratch/git-calls")" 'reset --hard'
output=$(updater startup)
check 'startup applies release' is "$(cat "$scratch/repo/VERSION")" 1.2.0
check 'update says old and new versions' has "$output" 'Companion updated from 1.0.0 to 1.2.0'
check 'all new changelog sections shown' has "$output" 'Another job.'
check 'old changelog excluded' absent "$output" 'Old job.'
check 'personal file preserved' is "$(cat "$scratch/repo/personal-note")" 'keep me'
check 'pending notice removed' test ! -f "$scratch/repo/.git/companion-update-ready"
: > "$scratch/git-calls"
output=$(TEST_FETCH=offline updater startup)
check 'offline preserves version and reports skipped' has "$output" 'current version kept'
check 'offline never resets' absent "$(cat "$scratch/git-calls")" 'reset --hard'
for variant in origin branch reserved prefix version; do
  : > "$scratch/git-calls"
  case "$variant" in
    origin) output=$(TEST_ORIGIN=wrong updater startup) ;;
    branch) output=$(TEST_BRANCH=other updater startup) ;;
    reserved) output=$(TEST_RESERVED=yes updater startup) ;;
    prefix) output=$(TEST_PREFIX=fail updater startup) ;;
    version) output=$(TEST_VERSION=bad updater startup) ;;
  esac
  check "$variant refusal visible" has "$output" 'Companion update skipped:'
  check "$variant refusal never resets" absent "$(cat "$scratch/git-calls")" 'reset --hard'
done
output=$(TEST_RESET=fail updater startup 2>&1); rc=$?
check 'apply failure returns failure' is "$rc" 1
check 'apply failure does not promise unchanged files' has "$output" 'apply outcome unknown; stop and ask Dan'
check 'apply failure does not claim current version kept' absent "$output" 'current version kept'
mkdir "$scratch/repo/.git/companion-update.lock"
touch -t 200001010000 "$scratch/repo/.git/companion-update.lock"
output=$(updater resume)
check 'empty stale lock recovered' test ! -e "$scratch/repo/.git/companion-update.lock"
mkdir "$scratch/repo/.git/companion-update.lock"
printf 'busy\n' > "$scratch/repo/.git/companion-update.lock/busy"
output=$(updater startup)
check 'populated update lock is preserved' test -f "$scratch/repo/.git/companion-update.lock/busy"
check 'lock conflict visible' has "$output" 'lock needs Dan'
# SessionStart records state; UserPromptSubmit, not SessionStart, blocks prompts.
kit="$scratch/startup-guard"
mkdir -p "$kit/scripts" "$kit/.git"
cp scripts/startup.sh scripts/session-state.sh scripts/json.awk scripts/prompt-guard.sh scripts/prompt.sh scripts/start-codex.sh "$kit/scripts/"
cat > "$kit/scripts/update.sh" <<'UPDATE'
#!/bin/sh
printf '%s\n' "$1" >> "$COMPANION_TEST_DIR/startup-update-calls"
case "${TEST_STARTUP_UPDATE:-ok}" in
 fail) printf 'Synthetic update failure.\n' >&2; exit 1 ;;
 applied)
  if [ -n "${COMPANION_STARTUP_KEY:-}" ]; then
    printf 'applied\n' > "$CLAUDE_PROJECT_DIR/.git/companion-startup/$COMPANION_STARTUP_KEY.applied"
  fi ;;
esac
UPDATE
cat > "$kit/scripts/sync-skills.sh" <<'LINKS'
#!/bin/sh
[ "${TEST_LINKS:-ok}" = ok ] || exit 1
printf 'called\n' >> "$COMPANION_TEST_DIR/startup-link-calls"
LINKS
cat > "$scratch/bin/codex" <<'CODEX'
#!/bin/sh
printf 'called\n' > "$COMPANION_TEST_DIR/codex-called"
CODEX
chmod +x "$scratch/bin/codex"
start() {
  printf '%s' "$1" | CLAUDE_PROJECT_DIR="$kit" bash "$kit/scripts/startup.sh" "${2:-startup}" 2>"$scratch/startup-stderr"
}
guard() {
  printf '%s' "$1" | bash "$kit/scripts/prompt-guard.sh" 2>"$scratch/guard-stderr"
}
prompt() {
  printf '%s' "$1" | CLAUDE_PROJECT_DIR="$kit" bash "$kit/scripts/prompt.sh" 2>"$scratch/guard-stderr"
}
payload='{"session_id":"synthetic-session"}'
output=$(guard "$payload"); rc=$?
check 'missing startup state blocks with exit 2' is "$rc" 2
check 'blocking message is on stderr' has "$(cat "$scratch/guard-stderr")" 'startup did not finish safely'
check 'guard failure prints no stdout' is "$output" ''
output=$(start '{"session_id":"synthetic-no-startup","source":"resume"}' resume); rc=$?
check 'resume without any startup record fails' is "$rc" 1
check 'resume without startup records failed state' is "$(cat "$kit/.git/companion-startup/sid-synthetic-no-startup.state")" failed
output=$(guard '{"session_id":"synthetic-no-startup"}'); rc=$?
check 'resume without startup record blocks prompt' is "$rc" 2
check 'resume cannot create latest startup outcome' test ! -e "$kit/.git/companion-startup/last-startup.state"
output=$(TEST_STARTUP_UPDATE=fail start "$payload"); rc=$?
check 'startup failure returns error' is "$rc" 1
check 'startup failure persists failed state' is "$(cat "$kit/.git/companion-startup/sid-synthetic-session.state")" failed
check 'startup failure skips optional linking' test ! -e "$scratch/startup-link-calls"
check 'latest startup records failure' is "$(cat "$kit/.git/companion-startup/last-startup.state")" failed
: > "$scratch/startup-update-calls"
output=$(start '{"session_id":"synthetic-clear-after-failure","source":"clear"}' resume); rc=$?
check 'clear with new ID after failed startup fails' is "$rc" 1
check 'unsafe clear persists failed state' is "$(cat "$kit/.git/companion-startup/sid-synthetic-clear-after-failure.state")" failed
output=$(guard '{"session_id":"synthetic-clear-after-failure"}'); rc=$?
check 'clear with new ID after failed startup blocks prompt' is "$rc" 2
check 'unsafe clear never runs updater' is "$(cat "$scratch/startup-update-calls")" ''
output=$(guard "$payload"); rc=$?
check 'failed startup blocks the next prompt' is "$rc" 2
output=$(start "$payload" resume); rc=$?
check 'resume cannot clear failed state' is "$rc" 1
output=$(start "$payload"); rc=$?
check 'completed startup succeeds' is "$rc" 0
check 'only completed startup records ready' is "$(cat "$kit/.git/companion-startup/sid-synthetic-session.state")" ready
output=$(guard "$payload"); rc=$?
check 'ready session permits prompts' is "$rc" 0
check 'latest startup records ready' is "$(cat "$kit/.git/companion-startup/last-startup.state")" ready
: > "$scratch/startup-update-calls"
output=$(start '{"session_id":"synthetic-clear-after-ready","source":"clear"}' resume); rc=$?
check 'clear with new ID after ready startup succeeds' is "$rc" 0
check 'safe clear persists ready state for new ID' is "$(cat "$kit/.git/companion-startup/sid-synthetic-clear-after-ready.state")" ready
check 'safe clear invokes only fetch-only resume mode' is "$(cat "$scratch/startup-update-calls")" resume
output=$(guard '{"session_id":"synthetic-clear-after-ready"}'); rc=$?
check 'clear with new ID after ready startup permits prompt' is "$rc" 0
check 'resume leaves latest startup outcome unchanged' is "$(cat "$kit/.git/companion-startup/last-startup.state")" ready
output=$(guard '{"session_id":"another-synthetic-session"}'); rc=$?
check 'ready state cannot authorise another session' is "$rc" 2
printf 'pending\n' > "$kit/.git/companion-startup/sid-synthetic-session.state"
output=$(guard "$payload"); rc=$?
check 'interrupted or timed-out startup blocks' is "$rc" 2
: > "$scratch/startup-update-calls"
output=$(prompt "$payload"); rc=$?
check 'prompt wrapper preserves guard block' is "$rc" 2
check 'blocked prompt never runs daily update' is "$(cat "$scratch/startup-update-calls")" ''
output=$(TEST_STARTUP_UPDATE=applied start "$payload"); rc=$?
check 'applied update completes hook without pretending SessionStart blocks' is "$rc" 0
check 'applied update records restart required' is "$(cat "$kit/.git/companion-startup/sid-synthetic-session.state")" restart
check 'latest startup records restart requirement' is "$(cat "$kit/.git/companion-startup/last-startup.state")" restart
: > "$scratch/startup-update-calls"
output=$(start '{"session_id":"synthetic-resume-after-update","source":"resume"}' resume); rc=$?
check 'resume with new ID after applied update fails' is "$rc" 1
check 'unsafe new resume persists failed state' is "$(cat "$kit/.git/companion-startup/sid-synthetic-resume-after-update.state")" failed
output=$(guard '{"session_id":"synthetic-resume-after-update"}'); rc=$?
check 'resume with new ID after applied update blocks prompt' is "$rc" 2
check 'inherited update block retains restart message' has "$(cat "$scratch/guard-stderr")" 'Restart Claude Code'
check 'blocked new resume never invokes updater' is "$(cat "$scratch/startup-update-calls")" ''
check 'blocked resume preserves latest startup restart' is "$(cat "$kit/.git/companion-startup/last-startup.state")" restart
output=$(guard "$payload"); rc=$?
check 'restart required blocks prompts' is "$rc" 2
check 'restart reason goes to stderr' has "$(cat "$scratch/guard-stderr")" 'Restart Claude Code'
output=$(start "$payload" resume); rc=$?
check 'resume cannot clear restart requirement' is "$rc" 1
output=$(start "$payload"); rc=$?
check 'fresh completed start clears restart state' is "$rc" 0
output=$(TEST_LINKS=fail start "$payload"); rc=$?
check 'Codex link failure does not block Claude startup' is "$rc" 0
check 'Codex failure warning is plain stderr' is "$(cat "$scratch/startup-stderr")" 'Codex skills unavailable in this folder'
output=$(TEST_LINKS=fail start "$payload" resume)
check 'Codex link failure warns once per session' is "$(cat "$scratch/startup-stderr")" ''
output=$(guard "$payload"); rc=$?
check 'Claude prompt still passes without Codex aliases' is "$rc" 0
: > "$scratch/startup-update-calls"
output=$(prompt "$payload"); rc=$?
check 'ready prompt runs daily fetch check' has "$(cat "$scratch/startup-update-calls")" daily
check 'ready prompt succeeds' is "$rc" 0
output=$(start ''); rc=$?
check 'hook without session ID uses per-start fallback' is "$rc" 0
output=$(guard ''); rc=$?
check 'per-start readiness is read by guard' is "$rc" 0
output=$(TEST_STARTUP_UPDATE=fail start ''); rc=$?
output=$(guard ''); rc=$?
check 'failed next fallback start cannot reuse prior readiness' is "$rc" 2
output=$(guard '{"session_id":"../synthetic-unsafe"}'); rc=$?
check 'unsafe session ID fails closed' is "$rc" 2
output=$(guard '{synthetic-malformed}'); rc=$?
check 'malformed hook input fails closed' is "$rc" 2
output=$(CLAUDE_PROJECT_DIR="$kit" TEST_LINKS=fail bash "$kit/scripts/start-codex.sh" 2>&1); rc=$?
check 'Codex launcher stops when aliases fail' is "$rc" 1
check 'Codex is never launched with missing skills' test ! -e "$scratch/codex-called"
check 'Codex stop points to its installation guide' has "$output" 'install/codex.md'
# The real updater must communicate an applied release without parsing its prose.
mkdir -p "$scratch/repo/.git/companion-startup"
rm -f "$scratch/repo/.git/companion-update.lock/busy"
rmdir "$scratch/repo/.git/companion-update.lock"
output=$(COMPANION_STARTUP_KEY=sid-synthetic-proof updater startup)
check 'updater writes an applied-release receipt' is "$(cat "$scratch/repo/.git/companion-startup/sid-synthetic-proof.applied")" applied
printf 'RESULT %s passed, %s failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
