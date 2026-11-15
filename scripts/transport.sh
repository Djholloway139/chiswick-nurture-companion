#!/usr/bin/env bash
# Sourced by the doctor. Never execute arbitrary host/flag inputs.
set +x
set -o pipefail
. "$root/scripts/key.sh"

transport_key_ok() {
  nurture_key_load "$root"
  [ -n "${NURTURE_API_KEY:-}" ] || return 1
  case "$NURTURE_API_KEY" in *[![:graph:]]*) return 1 ;; esac
}

# Fixed discovery destination. Credential is on stdin, never argv or curl's env.
# No curlrc, redirects, retries, tracing or raw stderr output.
transport_request() {
  local destination timeout
  case "$1" in
    discovery) destination='https://app.nurtureoutreach.com/mcp'; timeout=8 ;;
    *) return 1 ;;
  esac
  printf 'Authorization: Bearer %s\n' "$NURTURE_API_KEY" |
    (
      unset NURTURE_API_KEY
      curl --disable --silent --connect-timeout 5 --max-time "$timeout" \
        --max-filesize 2097152 --proto '=https' \
        --header @- --header 'Content-Type: application/json' --header 'Accept: application/json' \
        --data-binary "@$2" --write-out $'\n%{http_code}' "$destination" 2>/dev/null
    )
}

# ASCII punctuation and letters only. Suppress reflected credentials.
# A character allowlist alone cannot protect a reflected secret.
transport_error() {
  local text
  text=$(printf '%s' "$1" | LC_ALL=C awk -v mode=error -f "$root/scripts/json.awk" 2>/dev/null) || return 1
  [ -n "$text" ] && [ "${#text}" -le 2000 ] || return 1
  case "$text" in *"$NURTURE_API_KEY"*) return 1 ;; esac
  # Reject escapes, non-ASCII and terminal control rather than interpreting them.
  if printf '%s' "$text" | LC_ALL=C grep '[^a-zA-Z0-9 .,:;!?()/_+=@#%'"'"'-]' >/dev/null; then return 1; fi
  printf '%s' "$text"
}
