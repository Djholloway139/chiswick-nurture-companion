#!/usr/bin/env bash
# Read-only checks. Never write credentials or print a response body.
set +x
main() {
  local root os version major minor patch prefix branch origin reply code body verdict
  root=$(cd "$(dirname "$0")/.." 2>/dev/null && pwd -P)
  os=$(uname -s 2>/dev/null)
  case "$os" in
    Darwin) printf 'OK OS: macOS\n' ;;
    MINGW*|MSYS*) printf 'OK OS: Windows Git Bash\n' ;;
    *) printf 'UNKNOWN OS: use macOS or Git Bash from Git for Windows\n' ;;
  esac
  if command -v git >/dev/null 2>&1; then
    printf 'OK Git: installed\n'
  else
    printf 'MISSING Git: install Git for Windows on Windows, or Apple command line tools on Mac; reopen Claude Code\n'
  fi
  version=$(claude --version 2>/dev/null)
  if [[ "$version" =~ ([0-9]+)\.([0-9]+)\.([0-9]+) ]]; then
    major=${BASH_REMATCH[1]}; minor=${BASH_REMATCH[2]}; patch=${BASH_REMATCH[3]}
    printf 'OK Claude Code: %s.%s.%s (version information only)\n' "$major" "$minor" "$patch"
  else
    printf 'UNKNOWN Claude Code: version not readable; ask IT to check the installed version\n'
  fi
  branch=$(git -C "$root" symbolic-ref --short HEAD 2>/dev/null)
  origin=$(git -C "$root" remote get-url origin 2>/dev/null)
  if prefix=$(git -C "$root" rev-parse --show-prefix 2>/dev/null) && [ -z "$prefix" ] &&
    [ "$branch" = main ] && [ "$origin" = 'https://github.com/Djholloway139/chiswick-nurture-companion.git' ]; then
    printf 'OK Checkout: companion on main with the expected origin\n'
  else
    printf 'MISSING Checkout: open the chiswick-nurture-companion folder cloned from https://github.com/Djholloway139/chiswick-nurture-companion.git on main; ask your administrator if it differs\n'
  fi
  for path in my-notes downloads; do
    if git -C "$root" check-ignore -q --no-index "$path/doctor-check" 2>/dev/null &&
      [ -z "$(git -C "$root" ls-files -- "$path" 2>/dev/null)" ]; then
      printf 'OK %s/: ignored and untracked\n' "$path"
    else
      printf 'MISSING %s/: personal folder is not protected; stop and ask your administrator to restore the kit before saving files\n' "$path"
    fi
  done
  if [ -z "${NURTURE_API_KEY:-}" ]; then
    printf 'MISSING NURTURE_API_KEY: add your own key in your user environment settings, never in chat, then fully restart Claude Code\n'
    printf 'UNKNOWN Nurture key: no key available; finish setup first or use Chrome\n'
    return 0
  fi
  printf 'OK NURTURE_API_KEY: present (value hidden)\n'
  if ! command -v curl >/dev/null 2>&1; then
    printf 'MISSING Nurture key: cannot check without curl; ask IT to restore the standard macOS or Git Bash tools\n'
    return 0
  fi
  case "$NURTURE_API_KEY" in
    *$'\n'*|*$'\r'*) printf 'MISSING Nurture key: key has a line break; re-enter it yourself in environment settings and restart\n'; return 0 ;;
  esac
  reply=$(printf 'Authorization: %s %s\n' 'Bearer' "$NURTURE_API_KEY" |
    curl --silent --connect-timeout 5 --max-time 8 --max-filesize 2097152 --proto '=https' \
      --header @- --header 'Content-Type: application/json' --header 'Accept: application/json' \
      --data '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"list_tasks","arguments":{"limit":1}}}' \
      --write-out $'\n%{http_code}' 'https://app.nurtureoutreach.com/mcp' 2>/dev/null)
  if [ "$?" -ne 0 ]; then
    printf 'UNKNOWN Nurture key: network or TLS check failed; reconnect and run set me up again\n'
    return 0
  fi
  code=${reply##*$'\n'}; body=${reply%$'\n'*}
  case "$code" in
    200)
      verdict=$(printf '%s' "$body" | LC_ALL=C awk -v keycheck=1 -f "$root/scripts/json.awk" 2>/dev/null)
      case "$verdict" in
        accepted) printf 'OK Nurture key: accepted\n' ;;
        refused) printf 'MISSING Nurture key: refused, create a new one in Nurture\n' ;;
        permission) printf 'MISSING Nurture key: works but lacks task permission; ask your admin to add list tasks\n' ;;
        *) printf 'UNKNOWN Nurture key: reply could not be verified; tell your administrator\n' ;;
      esac ;;
    401) printf 'MISSING Nurture key: refused, create a new one in Nurture\n' ;;
    403) printf 'MISSING Nurture key: works but lacks task permission; ask your admin to add list tasks\n' ;;
    *) printf 'UNKNOWN Nurture key: service did not return a task result; try later and tell your administrator if it continues\n' ;;
  esac
  return 0
}
main
