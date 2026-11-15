#!/usr/bin/env bash
# Live discovery only. Tool presence never proves this key's effective access.
set +x
set -o pipefail
umask 077
main() {
  local root os version prefix branch origin reply code body verdict reason work state note file name
  root=$(cd "$(dirname "$0")/.." && pwd -P) || return 1
  . "$root/scripts/transport.sh"
  os=$(uname -s)
  case "$os" in Darwin) printf 'OK OS: macOS\n' ;; MINGW*|MSYS*) printf 'OK OS: Windows Git Bash\n' ;; *) printf 'UNKNOWN OS: use macOS or Git Bash\n' ;; esac
  version=$(claude --version 2>/dev/null)
  if [[ "$version" =~ ([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
    printf 'OK Claude Code: %s (version information only; verify client features in /setup)\n' "${BASH_REMATCH[0]}"
  else printf 'UNKNOWN Claude Code: version not readable; ask IT\n'; fi
  if command -v git >/dev/null 2>&1; then
    printf 'OK Git: installed\n'
  else printf 'MISSING Git: install Git for Windows or Mac command line tools\n'; fi
  branch=$(git -C "$root" symbolic-ref --short HEAD 2>/dev/null)
  origin=$(git -C "$root" remote get-url origin 2>/dev/null)
  if prefix=$(git -C "$root" rev-parse --show-prefix 2>/dev/null) && [ -z "$prefix" ] &&
     [ "$branch" = main ] && [ "$origin" = 'https://github.com/Djholloway139/chiswick-nurture-companion.git' ]; then
    printf 'OK Checkout: expected main and origin\n'
  else printf 'MISSING Checkout: open the companion clone on main; ask Dan if it differs\n'; fi
  for name in my-notes downloads; do
    if git -C "$root" check-ignore -q --no-index "$name/doctor-check" 2>/dev/null &&
       [ -z "$(git -C "$root" ls-files -- "$name" 2>/dev/null)" ]; then
      printf 'OK %s/: ignored and untracked\n' "$name"
    else printf 'MISSING %s/: stop before saving files; ask Dan\n' "$name"; fi
  done
  state=unknown; note='access and identity not verified; use /setup live discovery'
  if ! transport_key_ok; then
    printf 'MISSING NURTURE_API_KEY: missing or unsafe; enter your own key outside chat, then restart\n'
  elif ! command -v curl >/dev/null 2>&1; then
    printf 'MISSING curl: ask IT to restore the standard shell tools\n'
  else
    work=$(mktemp -d "${TMPDIR:-/tmp}/nurture-doctor.XXXXXX") || return 1
    doctor_work=$work
    trap 'rm -rf -- "$doctor_work"' EXIT
    trap 'exit 1' HUP INT TERM
    printf '%s' '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' > "$work/request.json"
    reply=$(transport_request discovery "$work/request.json")
    if [ "$?" -ne 0 ]; then
      state=offline; note='network or TLS failure; current kit preserved'
      printf 'UNKNOWN Nurture: %s\n' "$note"
    else
      code=${reply##*$'\n'}; body=${reply%$'\n'*}
      if [ "$code" = 200 ] && verdict=$(printf '%s' "$body" | LC_ALL=C awk -v mode=discovery -f "$root/scripts/json.awk" 2>/dev/null); then
        printf 'OK Discovery: live schemas received (%s); this does not verify key access\n' "$verdict"
        note='discovered; /setup must match live descriptions and verify access'
      else
        reason=$(transport_error "$body") || reason=''
        [ -z "$reason" ] || printf 'UNKNOWN Nurture response: %s\n' "$reason"
        case "$code" in
          401|403) state='not allowed for this key'; note='discovery refused; verify browser separately' ;;
          *) note='reply unverified; do not infer access or missing capabilities' ;;
        esac
        printf 'UNKNOWN Discovery: %s\n' "$note"
      fi
    fi
  fi
  printf 'UNKNOWN Identity: /setup must verify workspace and person live; tools/list is insufficient\n'
  for file in "$root"/.claude/skills/*/SKILL.md; do
    [ -f "$file" ] || continue
    name=${file%/SKILL.md}; name=${name##*/}
    printf 'COMMAND /%s: %s (%s)\n' "$name" "$state" "$note"
  done
  # Semantic coverage belongs to /setup, using live descriptions, not a tool map.
  return 0
}
main
