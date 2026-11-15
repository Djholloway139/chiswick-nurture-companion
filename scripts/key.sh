#!/usr/bin/env bash
# Sourced only. Loads NURTURE_API_KEY from the ignored .env in this folder when
# the environment does not already set it. Parses one line; never sources .env.
set +x
nurture_key_load() {
  local file line value
  [ -z "${NURTURE_API_KEY:-}" ] || return 0
  file="$1/.env"
  [ -f "$file" ] && [ -r "$file" ] || return 1
  while IFS= read -r line || [ -n "$line" ]; do
    case "$line" in
      NURTURE_API_KEY=*)
        value=${line#NURTURE_API_KEY=}
        value=${value%$'\r'}
        case "$value" in \"*\") value=${value#\"}; value=${value%\"} ;; esac
        NURTURE_API_KEY=$value
        export NURTURE_API_KEY
        return 0 ;;
    esac
  done < "$file"
  return 1
}
