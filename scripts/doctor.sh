#!/usr/bin/env bash
# Live discovery only. Tool presence never proves this key's effective access.
set +x
set -o pipefail
umask 077
doctor_header_helper() {
  local label=$1 shell=$2 statuses batch_dir batch_path encoded reason
  # Parse the byte stream directly. Shell variables can discard NUL bytes and
  # make UTF-16 output appear to be valid JSON.
  (
    cd "$root" || exit 1
    case "$shell" in
      sh) /bin/sh -c "$helper_command" ;;
      cmd)
        case "$helper_command" in *%*) exit 20 ;; esac
        command -v cygpath >/dev/null 2>&1 || exit 21
        batch_dir=$(mktemp -d "${TMPDIR:-/tmp}/nurture-header-check.XXXXXX") || exit 22
        trap 'rm -rf -- "$batch_dir"' EXIT
        trap 'exit 1' HUP INT TERM
        printf '@echo off\r\n%s\r\n' "$helper_command" > "$batch_dir/headers.cmd" || exit 22
        batch_path=$(cygpath -w "$batch_dir/headers.cmd") || exit 23
        [ -n "$batch_path" ] || exit 23
        cmd.exe //d //c "$batch_path" ;;
      powershell)
        command -v iconv >/dev/null 2>&1 && command -v base64 >/dev/null 2>&1 || exit 21
        encoded=$(printf '%s' "$helper_command" | iconv -f UTF-8 -t UTF-16LE | base64 | tr -d '\r\n') || exit 24
        [ -n "$encoded" ] || exit 24
        powershell.exe -NoProfile -EncodedCommand "$encoded" ;;
    esac
  ) 2>/dev/null | LC_ALL=C awk -v mode=object-member -v member=Authorization \
    -f "$root/scripts/json.awk" >/dev/null 2>&1
  statuses=("${PIPESTATUS[@]}")
  if [ "${statuses[0]}" -ne 0 ]; then
    case "${statuses[0]}" in
      20) reason='helper command contains %; batch check refused' ;;
      21) reason='Git Bash tools missing' ;;
      22) reason='could not prepare the temporary batch file' ;;
      23) reason='could not convert the batch file path to Windows form' ;;
      24) reason='could not encode the PowerShell command' ;;
      *) reason='command failed' ;;
    esac
    printf '%s: %s; send this line to Dan\n' "$label" "$reason"
  elif [ "${statuses[1]}" -eq 0 ]; then
    printf '%s: OK\n' "$label"
  else
    printf '%s: stdout is not a JSON object containing Authorization; send this line to Dan\n' "$label"
  fi
  # Neither stdout nor stderr from the command is ever displayed.
}
main() {
  local root os version prefix branch origin reply code body verdict reason work state note file name helper_command
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
  if helper_command=$(LC_ALL=C awk -v mode=string-at-path \
    -v target_path=/mcpServers/nurture/headersHelper -f "$root/scripts/json.awk" "$root/.mcp.json" 2>/dev/null); then
    doctor_header_helper 'header helper' sh
    case "$os" in
      MINGW*|MSYS*)
        doctor_header_helper 'header helper (cmd.exe)' cmd
        doctor_header_helper 'header helper (PowerShell)' powershell ;;
    esac
  else
    printf 'header helper: cannot read the command from .mcp.json; send this line to Dan\n'
  fi
  state=unknown; note='access and identity not verified; use /setup live discovery'
  if ! transport_key_ok; then
    printf 'MISSING NURTURE_API_KEY: missing or unsafe; run bash scripts/save-key.sh so Bela can paste it into the pop-up box\n'
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
