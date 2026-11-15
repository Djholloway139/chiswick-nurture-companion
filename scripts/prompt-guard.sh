#!/usr/bin/env bash
# UserPromptSubmit exit 2 blocks the prompt; stderr is the displayed reason.
set +x
unset NURTURE_API_KEY
set -o pipefail
root=$(cd "$(dirname "$0")/.." && pwd -P) || exit 2
. "$root/scripts/session-state.sh"
block() { printf '%s\n' "$1" >&2; exit 2; }
session_location || block 'Companion startup readiness is unavailable. Start a new Claude Code session; ask Dan if it repeats.'
state=''
[ ! -r "$state_file" ] || read -r state < "$state_file"
# A new ID inherits a failed state on unsafe resume; preserve the restart reason.
if [ "$state" = failed ] && [ -r "$state_dir/last-startup.state" ]; then
  latest=''
  read -r latest < "$state_dir/last-startup.state"
  [ "$latest" != restart ] || state=restart
fi
case "$state" in
  ready) exit 0 ;;
  restart) block 'Companion updated. Restart Claude Code with a new session to load the update.' ;;
  *) block 'Companion startup did not finish safely. Start a new Claude Code session; ask Dan if it repeats.' ;;
esac
