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
mkdir -p "$scratch/bin" "$scratch/tmp"
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
[ "$1" != -C ] || shift 2
case "$1" in
 symbolic-ref) printf 'main\n' ;;
 remote) printf 'https://github.com/Djholloway139/chiswick-nurture-companion.git\n' ;;
 rev-parse|check-ignore|ls-files) exit 0 ;;
 *) exit 96 ;;
esac
GIT
chmod +x "$scratch/bin/curl" "$scratch/bin/claude" "$scratch/bin/uname" "$scratch/bin/git"
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
doctor() { bash scripts/doctor.sh; }
output=$(unset NURTURE_API_KEY; doctor)
check 'doctor missing key never calls transport' test ! -e "$scratch/calls"
check 'doctor missing key visible' has "$output" 'MISSING NURTURE_API_KEY:'
output=$(doctor)
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
check 'doctor failure cleanup' cleaned
unset NURTURE_API_KEY
printf 'RESULT %s passed, %s failed\n' "$passed" "$failed"
[ "$failed" -eq 0 ]
