#!/usr/bin/env bash
# Asks Bela for his Nurture key in a private pop-up box and saves it to the
# ignored .env in this folder. Prints only a status line, never the key.
set +x
set -o pipefail
umask 077
unset NURTURE_API_KEY
root=$(cd "$(dirname "$0")/.." && pwd -P) || { printf 'NOT SAVED: folder not found; ask Dan\n'; exit 1; }
message='Paste your Nurture key, then click Save. Claude cannot see what you type here.'
case "$(uname -s)" in
  Darwin)
    key=$(osascript \
      -e 'on run argv' \
      -e 'activate' \
      -e 'text returned of (display dialog (item 1 of argv) with title "Nurture key" default answer "" with hidden answer buttons {"Cancel", "Save"} default button "Save" giving up after 600)' \
      -e 'end run' "$message" 2>/dev/null) || { printf 'NOT SAVED: cancelled\n'; exit 1; } ;;
  MINGW*|MSYS*)
    key=$(powershell.exe -NoProfile -Command \
      '$c = Get-Credential -UserName "Nurture key" -Message $args[0]; if ($c) { [Console]::Out.Write($c.GetNetworkCredential().Password) }' \
      "$message" 2>/dev/null) || { printf 'NOT SAVED: cancelled\n'; exit 1; } ;;
  *) printf 'NOT SAVED: this computer is not supported; ask Dan\n'; exit 1 ;;
esac
# Trim spaces and line breaks picked up when copying.
key=${key//$'\r'/}
key="${key#"${key%%[![:space:]]*}"}"
key="${key%"${key##*[![:space:]]}"}"
case "$key" in
  '') printf 'NOT SAVED: no key entered\n'; exit 1 ;;
  *[![:graph:]]*|*\"*|*\\*) key=''; printf 'NOT SAVED: that does not look like a key; copy it again\n'; exit 1 ;;
esac
tmp=$(mktemp "$root/.env.XXXXXX") || { key=''; printf 'NOT SAVED: could not write the file; ask Dan\n'; exit 1; }
if printf 'NURTURE_API_KEY=%s\n' "$key" > "$tmp" && mv -f "$tmp" "$root/.env"; then
  key=''
  printf 'SAVED: key stored in this folder only\n'
else
  key=''; rm -f "$tmp"
  printf 'NOT SAVED: could not write the file; ask Dan\n'; exit 1
fi
