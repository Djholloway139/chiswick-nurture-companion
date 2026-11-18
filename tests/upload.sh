#!/bin/sh
# Disabled-byte-helper and doctor checks. Synthetic data and fake transports only.
set -u
unset NURTURE_API_KEY
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P) || exit 1
cd "$root" || exit 1
scratch=$(mktemp -d "${TMPDIR:-/tmp}/companion-transport-tests.XXXXXX") || exit 1
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
mkdir -p "$scratch/bin" "$scratch/tmp" "$scratch/git-tmp"
kit="$scratch/doctor kit"
mkdir -p "$kit/scripts" "$kit/.git/objects" "$kit/.git/refs" "$kit/.claude"
cp scripts/doctor.sh scripts/transport.sh scripts/key.sh scripts/nurture-headers.sh scripts/json.awk "$kit/scripts/"
cp .mcp.json "$kit/"
cp -R .claude/skills "$kit/.claude/"
printf 'ref: refs/heads/main\n' > "$kit/.git/HEAD"
export COMPANION_TEST_GIT="$(command -v git)"
export COMPANION_TEST_ICONV="$(command -v iconv)"
export TEST_DOCTOR_KIT="$(cd "$kit" && pwd -P)"
export TEST_HELPER_COMMAND="$(awk -v mode=string-at-path -v target_path=/mcpServers/nurture/headersHelper -f scripts/json.awk .mcp.json)"
export COMPANION_TEST_DIR="$scratch" TMPDIR="$scratch/tmp"
export NURTURE_API_KEY='synthetic-test-marker'
cat > "$scratch/bin/curl" <<'CURL'
#!/bin/sh
set -u
[ -z "${NURTURE_API_KEY:-}" ] || exit 89
[ "$1" = --disable ] || exit 90
header=0; request=''; url=''; proto=0; bound=0
for arg do case "$arg" in *synthetic-test-marker*) exit 91 ;; esac; done
printf 'call\n' >> "$COMPANION_TEST_DIR/calls"
printf '%s\n' "$@" > "$COMPANION_TEST_DIR/argv"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --header) shift; [ "$1" != @- ] || header=1 ;;
    --data-binary) shift; request=${1#@} ;;
    --proto) shift; [ "$1" != '=https' ] || proto=1 ;;
    --max-time) shift; bound=1 ;;
    --location*|--retry*|--insecure|--verbose|--trace*) exit 92 ;;
    https://*) url=$1 ;;
  esac
  shift
done
[ "$header:$proto:$bound" = 1:1:1 ] && [ -r "$request" ] || exit 93
authorization=$(cat)
[ "$authorization" = 'Authorization: Bearer synthetic-test-marker' ] || exit 94
printf 'matched\n' > "$COMPANION_TEST_DIR/header"
cat "$request" > "$COMPANION_TEST_DIR/request"
[ "$url" = https://app.nurtureoutreach.com/mcp ] || exit 95
case "${TEST_MODE:-ok}" in
 offline) printf 'synthetic-test-marker\n' >&2; exit 7 ;;
 refused) printf '{"error":"Synthetic discovery refusal."}\n403' ;;
 rpc) printf '{"jsonrpc":"2.0","id":1,"error":{"message":"Synthetic RPC refusal."}}\n200' ;;
 embedded) printf '{"jsonrpc":"2.0","id":1,"result":{"isError":true,"content":[{"type":"text","text":"Synthetic bridge refusal."}]}}\n200' ;;
 reflect) printf '{"error":"synthetic-test-marker"}\n403' ;;
 control) printf '{"error":"Synthetic \\u001b[31m refusal."}\n403' ;;
 newline) printf '{"error":"Synthetic first line.\\nSynthetic second line."}\n403' ;;
 malformed) printf '{synthetic-malformed}\n200' ;;
 duplicate) printf '{"jsonrpc":"2.0","id":1,"id":1,"result":{"tools":[]}}\n200' ;;
 wrongid) printf '{"jsonrpc":"2.0","id":2,"result":{"tools":[]}}\n200' ;;
 wrongtype) printf '{"jsonrpc":"2.0","id":"1","result":{"tools":[]}}\n200' ;;
 pointer) printf '{"jsonrpc":"2.0","id":1,"result/tools":[]}\n200' ;;
 partial) printf '{"jsonrpc":"2.0","id":1,"result":{"tools":[],"nextCursor":"synthetic-next"}}\n200' ;;
 *) printf '{"jsonrpc":"2.0","id":1,"result":{"tools":[{"name":"synthetic_capability","description":"Synthetic capability.","inputSchema":{"type":"object"}}]}}\n200' ;;
esac
CURL
cat > "$scratch/bin/claude" <<'CLAUDE'
#!/bin/sh
printf '%s (Claude Code)\n' "${TEST_CLAUDE_VERSION:-2.1.296}"
CLAUDE
cat > "$scratch/bin/uname" <<'UNAME'
#!/bin/sh
printf '%s\n' "${TEST_OS:-Darwin}"
UNAME
cat > "$scratch/bin/git" <<'GIT'
#!/bin/sh
if [ "$1" = -c ]; then
  case "${TEST_HELPER_MODE:-ok}" in
    fail) printf 'synthetic-test-marker' >&2; exit 1 ;;
    malformed) printf 'synthetic-test-marker'; exit 0 ;;
    empty) printf '{}'; exit 0 ;;
    array) printf '[{"Authorization":"synthetic-test-marker"}]'; exit 0 ;;
    duplicate) printf '{"Authorization":"synthetic-test-marker","Authorization":"synthetic-test-marker"}'; exit 0 ;;
    utf16) printf '\377\376{\000"\000A\000u\000t\000h\000o\000r\000i\000z\000a\000t\000i\000o\000n\000"\000:\000"\000s\000"\000}\000'; exit 0 ;;
  esac
  # Apple Git may create an xcrun cache. Keep Git's own temporary files apart
  # from the directory whose doctor request cleanup is checked below.
  TMPDIR="$COMPANION_TEST_DIR/git-tmp" exec "$COMPANION_TEST_GIT" "$@"
fi
[ "$1" != -C ] || shift 2
case "$1" in
 symbolic-ref) printf 'main\n' ;;
 remote) printf 'https://github.com/Djholloway139/chiswick-nurture-companion.git\n' ;;
 rev-parse|check-ignore|ls-files) exit 0 ;;
 *) exit 96 ;;
esac
GIT
cat > "$scratch/bin/cmd.exe" <<'CMD'
#!/bin/sh
[ "$#" -eq 3 ] && [ "$1" = //d ] && [ "$2" = //c ] || exit 91
[ "$3" = 'C:\synthetic batch folder\headers.cmd' ] || exit 92
[ "$PWD" = "$TEST_DOCTOR_KIT" ] || exit 93
batch=$(cat "$COMPANION_TEST_DIR/batch-path") || exit 94
[ -f "$batch" ] || exit 95
printf '@echo off\r\n%s\r\n' "$TEST_HELPER_COMMAND" > "$COMPANION_TEST_DIR/expected-batch"
cmp -s "$COMPANION_TEST_DIR/expected-batch" "$batch" || exit 96
printf 'matched\n' > "$COMPANION_TEST_DIR/cmd-contract"
[ "${TEST_CMD_MODE:-ok}" != fail ] || { printf 'synthetic-test-marker' >&2; exit 1; }
exec /bin/sh -c "$TEST_HELPER_COMMAND"
CMD
cat > "$scratch/bin/powershell.exe" <<'POWERSHELL'
#!/bin/sh
[ "$#" -eq 3 ] && [ "$1" = -NoProfile ] && [ "$2" = -EncodedCommand ] || exit 91
case "$3" in ''|*[!A-Za-z0-9+/=]*) exit 92 ;; esac
decoded=$(printf '%s' "$3" | base64 -d | iconv -f UTF-16LE -t UTF-8) || exit 92
[ "$decoded" = "$TEST_HELPER_COMMAND" ] || exit 92
[ "$PWD" = "$TEST_DOCTOR_KIT" ] || exit 93
printf 'matched\n' > "$COMPANION_TEST_DIR/powershell-contract"
[ "${TEST_POWERSHELL_MODE:-ok}" != fail ] || { printf 'synthetic-test-marker'; exit 1; }
exec /bin/sh -c "$decoded"
POWERSHELL
cat > "$scratch/bin/cygpath" <<'CYGPATH'
#!/bin/sh
[ "$#" -eq 2 ] && [ "$1" = -w ] && [ -f "$2" ] || exit 91
printf '%s\n' "$2" > "$COMPANION_TEST_DIR/batch-path"
[ "${TEST_CYGPATH_MODE:-ok}" != fail ] || { printf 'synthetic-test-marker' >&2; exit 1; }
printf '%s\n' 'C:\synthetic batch folder\headers.cmd'
CYGPATH
cat > "$scratch/bin/iconv" <<'ICONV'
#!/bin/sh
[ "${TEST_ICONV_MODE:-ok}" != fail ] || { printf 'synthetic-test-marker' >&2; exit 1; }
exec "$COMPANION_TEST_ICONV" "$@"
ICONV
chmod +x "$scratch/bin/curl" "$scratch/bin/claude" "$scratch/bin/uname" "$scratch/bin/git" "$scratch/bin/cmd.exe" "$scratch/bin/powershell.exe" "$scratch/bin/cygpath" "$scratch/bin/iconv"
export PATH="$scratch/bin:$PATH"
private() { absent "$output" 'synthetic-test-marker'; }
cleaned() { [ -z "$(ls -A "$scratch/tmp")" ]; }
output=$(bash scripts/upload.sh >"$scratch/upload-stdout" 2>"$scratch/upload-stderr"); rc=$?
check 'byte helper refuses while contract is unavailable' is "$rc" 1
check 'byte helper directs user to browser on stderr' has "$(cat "$scratch/upload-stderr")" 'confirmed Chrome workflow'
check 'byte helper emits no stdout' is "$(cat "$scratch/upload-stdout")" ''
check 'byte helper never calls curl' test ! -e "$scratch/calls"
check 'byte helper creates no temporary request' cleaned
output=$(bash scripts/upload.sh synthetic-reference "$scratch/synthetic-unreadable-file" synthetic/type 2>&1); rc=$?
check 'byte helper cannot be bypassed with arguments' is "$rc" 1
check 'byte helper never discloses the synthetic marker' private
check 'application payload and receipt field lists removed' sh -c '
 ! grep -E "printf.*\{|mode==\"receipt\"" scripts/upload.sh scripts/json.awk >/dev/null'
doctor() { bash "$kit/scripts/doctor.sh"; }
output=$(unset NURTURE_API_KEY; doctor)
check 'doctor missing key never calls transport' test ! -e "$scratch/calls"
check 'doctor missing key visible' has "$output" 'MISSING NURTURE_API_KEY:'
check 'doctor missing helper header is visible' has "$output" 'header helper: stdout is not a JSON object containing Authorization'
output=$(doctor)
check 'doctor configured helper passes with synthetic key' has "$output" 'header helper: OK'
check 'doctor version displayed' has "$output" 'OK Claude Code: 2.1.296'
check 'doctor uses tools/list only' is "$(cat "$scratch/request")" '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}'
check 'doctor does not treat discovery as access proof' has "$output" 'this does not verify key access'
check 'doctor identity stays unverified' has "$output" 'UNKNOWN Identity:'
check 'doctor reports every command' is "$(printf '%s\n' "$output" | grep -c '^COMMAND /')" "$(find .claude/skills -name SKILL.md | wc -l | tr -d ' ')"
check 'doctor reports unknown command access' has "$output" 'COMMAND /file-document: unknown'
check 'doctor keeps synthetic tool body private' absent "$output" 'synthetic_capability'
check 'authorization uses stdin and no curl environment key' is "$(cat "$scratch/header")" matched
check 'key absent from doctor output' private
check 'doctor temporary request cleaned' cleaned
output=$(TEST_MODE=refused doctor)
check 'new service error wording printed directly' has "$output" 'Synthetic discovery refusal.'
check 'refused discovery distinguished' has "$output" 'COMMAND /file-document: not allowed for this key'
output=$(TEST_MODE=rpc doctor)
check 'RPC error wording printed directly' has "$output" 'Synthetic RPC refusal.'
output=$(TEST_MODE=embedded doctor)
check 'bridge error wording printed directly' has "$output" 'Synthetic bridge refusal.'
output=$(TEST_MODE=offline doctor)
check 'offline command status' has "$output" 'COMMAND /calendar: offline'
for mode in malformed duplicate wrongid wrongtype pointer; do
  output=$(TEST_MODE=$mode doctor)
  check "$mode discovery remains unknown" has "$output" 'reply unverified'
done
output=$(TEST_MODE=reflect doctor)
check 'reflected marker suppressed' private
output=$(TEST_MODE=control doctor)
check 'unsafe terminal escapes suppressed' absent "$output" 'Synthetic'
output=$(TEST_MODE=newline doctor)
check 'safe newline normalised without copied matching' has "$output" 'Synthetic first line. Synthetic second line.'
output=$(TEST_MODE=partial doctor)
check 'incomplete discovery distinguished' has "$output" 'live schemas received (partial)'
output=$(TEST_OS=MINGW64_NT-10.0 doctor)
check 'Git Bash OS recognised' has "$output" 'OK OS: Windows Git Bash'
check 'doctor cmd helper passes' has "$output" 'header helper (cmd.exe): OK'
check 'doctor PowerShell helper passes' has "$output" 'header helper (PowerShell): OK'
check 'doctor batch file holds only echo off and the exact configured command' is "$(cat "$scratch/cmd-contract")" matched
check 'doctor PowerShell encoded command decodes to the exact configured command' is "$(cat "$scratch/powershell-contract")" matched
batch_dir=$(dirname "$(cat "$scratch/batch-path")")
check 'doctor removes the successful batch file and directory' test ! -e "$batch_dir"
check 'doctor Windows checks keep synthetic key private' private
for mode in fail malformed empty array duplicate utf16; do
  output=$(TEST_HELPER_MODE=$mode doctor)
  check "doctor $mode helper never passes" absent "$output" 'header helper: OK'
  check "doctor $mode helper gives a safe reason" has "$output" 'header helper:'
  check "doctor $mode helper output stays private" private
done
output=$(TEST_OS=MINGW64_NT-10.0 TEST_CMD_MODE=fail TEST_POWERSHELL_MODE=fail doctor)
check 'doctor cmd failure has a safe reason' has "$output" 'header helper (cmd.exe): command failed'
check 'doctor PowerShell failure has a safe reason' has "$output" 'header helper (PowerShell): command failed'
check 'doctor failed Windows checks keep output private' private
batch_dir=$(dirname "$(cat "$scratch/batch-path")")
check 'doctor removes the failed batch file and directory' test ! -e "$batch_dir"
output=$(TEST_OS=MINGW64_NT-10.0 TEST_CYGPATH_MODE=fail doctor)
check 'doctor path conversion failure has a safe reason' has "$output" 'header helper (cmd.exe): could not convert the batch file path to Windows form'
check 'doctor path conversion stderr stays private' private
batch_dir=$(dirname "$(cat "$scratch/batch-path")")
check 'doctor removes batch directory after path conversion failure' test ! -e "$batch_dir"
output=$(TEST_OS=MINGW64_NT-10.0 TEST_ICONV_MODE=fail doctor)
check 'doctor encoding failure has a safe reason' has "$output" 'header helper (PowerShell): could not encode the PowerShell command'
check 'doctor encoding stderr stays private' private
# Change the fixture config to prove doctor does not keep a second command.
printf '%s\n' '{"mcpServers":{"nurture":{"headersHelper":"exit 7 # %"}}}' > "$kit/.mcp.json"
rm "$scratch/cmd-contract"
output=$(TEST_OS=MINGW64_NT-10.0 doctor)
check 'doctor refuses percent expansion in batch commands' has "$output" 'header helper (cmd.exe): helper command contains %; batch check refused'
check 'doctor never runs cmd for a percent command' test ! -e "$scratch/cmd-contract"
printf '%s\n' '{"mcpServers":{"nurture":{"headersHelper":"exit 7"}}}' > "$kit/.mcp.json"
output=$(doctor)
check 'doctor executes command read from changed config' has "$output" 'header helper: command failed'
printf '{synthetic-malformed}\n' > "$kit/.mcp.json"
output=$(doctor)
check 'doctor malformed config fails safely' has "$output" 'header helper: cannot read the command from .mcp.json'
check 'doctor failure cleanup' cleaned
unset NURTURE_API_KEY
printf 'RESULT %s passed, %s failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
