#!/usr/bin/env bash
# Based on the reviewed bounded-fetch updater. No clean or credential prompts.
set +x
main() {
  warn() { printf 'Companion update skipped: %s\n' "$1"; exit 0; }
  local project prefix gd lock fetch_pid='' timer_pid='' rc reserved before changed=0
  project=${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/.." 2>/dev/null && pwd -P)}
  cd "$project" 2>/dev/null || warn 'cannot open the companion folder'
  command -v git >/dev/null 2>&1 || warn 'Git is missing; install Git and reopen Claude Code'
  prefix=$(git rev-parse --show-prefix 2>/dev/null) && [ -z "$prefix" ] || warn 'open the companion checkout'
  [ "$(git symbolic-ref --short HEAD 2>/dev/null)" = main ] || warn 'checkout is not on main; ask your administrator'
  gd=$(git rev-parse --git-dir 2>/dev/null) || warn 'invalid checkout'
  lock="$gd/companion-update.lock"
  find "$lock" -maxdepth 0 -mmin +2 -exec rmdir {} \; 2>/dev/null
  mkdir "$lock" 2>/dev/null || warn 'another updater is running or its lock remains; ask your administrator'
  cleanup() {
    [ -z "$timer_pid" ] || kill "$timer_pid" 2>/dev/null || :
    [ -z "$fetch_pid" ] || kill "$fetch_pid" 2>/dev/null || :
    rmdir "$lock" 2>/dev/null || :
  }
  trap cleanup EXIT
  trap 'warn interrupted' HUP INT TERM
  export GIT_TERMINAL_PROMPT=0
  export GCM_INTERACTIVE=never
  git -c credential.helper= -c credential.interactive=false fetch --quiet --no-tags origin \
    '+refs/heads/main:refs/remotes/origin/main' >/dev/null 2>&1 &
  fetch_pid=$!
  ( sleep 8; kill "$fetch_pid" 2>/dev/null ) >/dev/null 2>&1 &
  timer_pid=$!
  wait "$fetch_pid" 2>/dev/null; rc=$?; fetch_pid=''
  kill "$timer_pid" 2>/dev/null || :
  wait "$timer_pid" 2>/dev/null || :
  timer_pid=''
  [ "$rc" -eq 0 ] || warn 'offline, authentication failure, or fetch timeout; try next session'
  reserved=$(git ls-tree -r --name-only origin/main -- my-notes downloads 2>/dev/null) || warn 'upstream tree unreadable'
  [ -z "$reserved" ] || warn 'upstream tracks a protected personal folder; contact your administrator'
  before=$(git rev-parse HEAD 2>/dev/null) || warn 'current version unreadable'
  [ "$before" = "$(git rev-parse origin/main 2>/dev/null)" ] || changed=1
  git diff --quiet --ignore-submodules -- 2>/dev/null || changed=1
  git diff --cached --quiet --ignore-submodules -- 2>/dev/null || changed=1
  git reset --hard origin/main >/dev/null 2>&1 || warn 'could not apply update; contact your administrator'
  if [ "$changed" -eq 1 ]; then
    printf 'Companion updated: restart Claude Code to apply\n'
  else
    printf 'Companion up to date\n'
  fi
  # Exit while the function's local lock path is still in scope for the trap.
  exit 0
}
main
