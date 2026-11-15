#!/usr/bin/env bash
# SessionStart cannot block. The prompt guard enforces the recorded state.
set +x
unset NURTURE_API_KEY
set -o pipefail
root=$(cd "$(dirname "$0")/.." && pwd -P) || exit 1
. "$root/scripts/session-state.sh"
session_location || { printf 'Companion startup could not record readiness. Stop and ask Dan.\n' >&2; exit 1; }
mode=${1:-startup}
case "$mode" in startup|resume) ;; *) printf 'Companion startup mode is invalid. Ask Dan.\n' >&2; exit 1 ;; esac
previous=''
[ ! -r "$state_file" ] || read -r previous < "$state_file"
if [ "$mode" = resume ]; then
  if [ ! -e "$state_file" ]; then
    latest=''
    [ ! -r "$state_dir/last-startup.state" ] || read -r latest < "$state_dir/last-startup.state"
    if [ "$latest" = ready ]; then
      previous=ready
    else
      session_put failed || { printf 'Companion startup could not save readiness. Ask Dan.\n' >&2; exit 1; }
    fi
  fi
  case "$previous" in
    ready) ;;
    *) printf 'Companion startup is incomplete or needs a restart. Start a new Claude Code session.\n' >&2; exit 1 ;;
  esac
fi
session_put pending || { printf 'Companion startup could not save readiness. Ask Dan.\n' >&2; exit 1; }
# Pending remains after a timeout, signal or crash. Never reuse yesterday's ready state.
trap 'printf "Companion startup interrupted. Start a new Claude Code session.\n" >&2; exit 1' HUP INT TERM
export COMPANION_STARTUP_KEY="$state_key"
receipt="$state_dir/$state_key.applied"
rm -f "$receipt" || exit 1
if ! bash "$root/scripts/update.sh" "$mode"; then
  session_put failed || :
  printf 'Companion startup failed. Start a new Claude Code session; ask Dan if it repeats.\n' >&2
  exit 1
fi
if [ -f "$receipt" ]; then
  session_put restart || exit 1
  printf 'Companion updated. Restart Claude Code with a new session before working.\n' >&2
else
  session_put ready || { printf 'Companion startup could not save readiness. Ask Dan.\n' >&2; exit 1; }
fi
# Claude reads .claude/skills directly. Optional alias work cannot gate readiness.
if ! bash "$root/scripts/sync-skills.sh" >/dev/null 2>&1; then
  if [ ! -f "$state_dir/$state_key.codex-warning" ]; then
    printf 'Codex skills unavailable in this folder\n' >&2
    : > "$state_dir/$state_key.codex-warning" || :
  fi
fi
