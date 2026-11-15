#!/bin/sh
# Structural guard for operational prose and executable adapters.
# Synthetic mutation examples live in tests/run.sh, never a product-word blacklist.
set -u
root=${1:-$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)}
count=0
failed=0
scan() {
  path=$1
  count=$((count+1))
  if ! LC_ALL=C awk '
    function flag(kind) { printf "DRIFT %s:%d: %s\n", FILENAME, FNR, kind; bad=1 }
    {
      lower=tolower($0)
      if($0 ~ /mcp__[a-zA-Z0-9_-]+__[a-zA-Z0-9_]+/) flag("per-tool permission inventory")
      if($0 ~ /"(properties|enum|required)"[ \t]*:[ \t]*[\[{]/) flag("copied JSON Schema structure")
      if(lower ~ /\|[ \t]*(field|parameter)[ \t]*\|/) flag("copied field table")
      if(lower ~ /[0-9]+[ \t]*(kib|mib|gib|kb|mb|gb|bytes|minutes)([^a-z]|$)/) flag("copied numeric product bound")
      if(lower ~ /limit[ \t]*:[ \t]*[0-9]+/) flag("copied numeric product bound")
      if(lower ~ /(click|choose|press)[^:]*button[ \t]*"/) flag("quoted UI control")
      if(lower ~ /(top|bottom)[ -](left|right)|nth-(child|of-type)|position[ \t]*:[ \t]*[0-9]+/) flag("layout dependency")
      if($0 ~ /"error"[ \t]*:[ \t]*"[^"]+"/) flag("copied service error example")
      if(FILENAME ~ /\/scripts\//) {
        if(lower ~ /case.*\$(reason|message|error)[^a-z_]/) flag("matching error wording")
        if($0 ~ /printf.*\{"/ && $0 !~ /"jsonrpc"/) flag("hardcoded application payload")
        rest=$0
        while(match(rest,/(vals|types|sizes)\["\/[^"]*"\]/)) {
          token=substr(rest,RSTART,RLENGTH)
          sub(/^[^"]*"/,"",token); sub(/"\]$/,"",token)
          if(token !~ /^\/(jsonrpc|id|session_id|error(\/message)?|result(\/tools|\/nextCursor|\/isError|\/content\/0\/text)?)$/)
            flag("application field in protocol parser")
          rest=substr(rest,RSTART+RLENGTH)
        }
      }
    }
    END { exit bad ? 1 : 0 }
  ' "$path"; then
    failed=$((failed+1))
  fi
}
for path in "$root/AGENTS.md" "$root/CLAUDE.md" "$root/README.md" "$root/CHANGELOG.md" \
  "$root"/guides/*.md "$root"/install/*.md "$root"/install/*.txt \
  "$root"/.claude/skills/*/SKILL.md "$root/.claude/settings.json" \
  "$root"/scripts/*.sh "$root"/scripts/*.awk; do
  [ ! -f "$path" ] || scan "$path"
done
printf 'RESULT %s files checked, %s violations\n' "$count" "$failed"
[ "$failed" -eq 0 ]
