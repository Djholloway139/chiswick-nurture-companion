#!/usr/bin/env bash
# headersHelper for .mcp.json. Claude Code runs this itself and keeps the output
# out of the conversation. Claude must never run it: the output holds the key.
set +x
root=$(cd "$(dirname "$0")/.." && pwd -P) || { printf '{}'; exit 0; }
. "$root/scripts/key.sh"
nurture_key_load "$root"
case "${NURTURE_API_KEY:-}" in
  ''|*[![:graph:]]*|*\"*|*\\*) printf '{}' ;;
  # A request header, not a Nurture payload: {"Authorization":"Bearer <key>"}.
  *) q='"'; printf '{%sAuthorization%s:%sBearer %s%s}' "$q" "$q" "$q" "$NURTURE_API_KEY" "$q" ;;
esac
