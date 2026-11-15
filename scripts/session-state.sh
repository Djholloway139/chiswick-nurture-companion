#!/usr/bin/env bash
# Sourced by startup and the prompt guard. Hook stdin never goes to disk or output.
set +x
unset NURTURE_API_KEY
umask 077

session_location() {
  local session gd prefix
  session=$(LC_ALL=C awk -v mode=hook-session -f "$root/scripts/json.awk") || return 1
  case "$session" in
    fallback) state_key=per-start ;;
    sid-*) state_key=$session ;;
    *) return 1 ;;
  esac
  prefix=$(git -C "$root" rev-parse --show-prefix 2>/dev/null) && [ -z "$prefix" ] || return 1
  gd=$(git -C "$root" rev-parse --git-dir 2>/dev/null) || return 1
  case "$gd" in /*|[a-zA-Z]:/*) state_dir="$gd/companion-startup" ;; *) state_dir="$root/$gd/companion-startup" ;; esac
  state_file="$state_dir/$state_key.state"
}

session_put() {
  local tmp="$state_file.tmp.$$"
  mkdir -p "$state_dir" || return 1
  printf '%s\n' "$1" > "$tmp" && mv -f "$tmp" "$state_file" || return 1
  # Resume/clear/compact must never replace the latest actual startup outcome.
  if [ "${mode:-}" = startup ]; then
    tmp="$state_dir/last-startup.state.tmp.$$"
    if ! { printf '%s\n' "$1" > "$tmp" && mv -f "$tmp" "$state_dir/last-startup.state"; }; then
      rm -f "$state_file"
      return 1
    fi
  fi
}
