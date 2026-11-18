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
    # Encoding keeps script quotes away from MSYS native argument conversion.
    # The message travels only through NURTURE_KEY_PROMPT.
    # Only the credential prompt can supply an error message. Once a password
    # exists, failures use fixed text so they cannot reflect the key.
    if ! command -v iconv >/dev/null 2>&1 || ! command -v base64 >/dev/null 2>&1; then
      printf 'NOT SAVED: the key box failed: Git Bash tools missing; send this line to Dan\n'; exit 1
    fi
    prompt_script='$ErrorActionPreference = "Stop"; '
    prompt_script+='try { $c = Get-Credential -UserName "Nurture key" -Message $env:NURTURE_KEY_PROMPT } catch { [Console]::Out.Write(($_.Exception.Message -split "[\r\n]", 2)[0]); exit 2 }; '
    prompt_script+='if ($null -eq $c) { exit 3 }; '
    prompt_script+='try { $password = $c.GetNetworkCredential().Password } catch { [Console]::Out.Write("could not read the key from the box"); exit 2 }; '
    prompt_script+='[Console]::Out.Write($password); exit 0'
    if ! encoded_prompt=$({ printf '%s' "$prompt_script" | iconv -f UTF-8 -t UTF-16LE | base64 | tr -d '\r\n'; } 2>/dev/null) || [ -z "$encoded_prompt" ]; then
      printf 'NOT SAVED: the key box failed: could not encode the PowerShell command; send this line to Dan\n'; exit 1
    fi
    key=$(NURTURE_KEY_PROMPT="$message" powershell.exe -NoProfile -EncodedCommand "$encoded_prompt" 2>/dev/null)
    prompt_status=$?
    case "$prompt_status" in
      0) ;;
      3) key=''; printf 'NOT SAVED: cancelled\n'; exit 1 ;;
      2)
        detail=${key%%$'\n'*}; detail=${detail%$'\r'}; key=''
        [ -n "$detail" ] || detail='PowerShell did not give a reason'
        printf 'NOT SAVED: the key box failed: %s; send this line to Dan\n' "$detail"
        exit 1 ;;
      *) key=''; printf 'NOT SAVED: the key box failed: PowerShell could not run the box; send this line to Dan\n'; exit 1 ;;
    esac ;;
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
