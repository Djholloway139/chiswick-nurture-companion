#!/usr/bin/env bash
# Run by Bela from Git Bash or Terminal before a Codex session.
set +x
root=$(cd "$(dirname "$0")/.." && pwd -P) || exit 1
cd "$root" || exit 1
case "${1:-}" in resume|fork) mode=resume ;; *) mode=startup ;; esac
# Codex reads fresh instructions after this launcher; it does not use Claude hooks.
bash scripts/update.sh "$mode" || exit 1
bash scripts/sync-skills.sh || {
  printf 'Codex skills unavailable in this folder. Stop and follow install/codex.md.\n' >&2
  exit 1
}
exec codex "$@"
