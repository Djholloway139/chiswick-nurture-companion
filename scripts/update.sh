#!/usr/bin/env bash
# Code delivery: apply only at startup. Other events fetch and notify.
set +x
unset NURTURE_API_KEY
main() {
  local mode project prefix gd lock fetch_pid='' timer_pid='' rc reserved before after old new now last tmp changed=0 receipt
  mode=${1:-check}
  warn() { printf 'Companion update skipped: %s; current version kept\n' "$1"; exit 0; }
  case "$mode" in startup|resume|daily|check) ;; *) warn 'invalid update mode' ;; esac
  project=${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/.." 2>/dev/null && pwd -P)}
  cd "$project" 2>/dev/null || warn 'cannot open companion folder'
  command -v git >/dev/null 2>&1 || warn 'Git missing; ask IT'
  prefix=$(git rev-parse --show-prefix 2>/dev/null) && [ -z "$prefix" ] || warn 'open companion checkout'
  [ "$(git symbolic-ref --short HEAD 2>/dev/null)" = main ] || warn 'checkout is not on main'
  [ "$(git remote get-url origin 2>/dev/null)" = 'https://github.com/Djholloway139/chiswick-nurture-companion.git' ] || warn 'unexpected origin; ask Dan'
  gd=$(git rev-parse --git-dir 2>/dev/null) || warn 'invalid checkout'
  now=$(date +%s)
  lock="$gd/companion-update.lock"
  # Remove only an empty stale lock, never a populated directory.
  find "$lock" -maxdepth 0 -mmin +2 -exec rmdir {} \; 2>/dev/null
  mkdir "$lock" 2>/dev/null || warn 'another updater is running or a lock needs Dan'
  cleanup() {
    [ -z "$timer_pid" ] || kill "$timer_pid" 2>/dev/null || :
    [ -z "$fetch_pid" ] || kill "$fetch_pid" 2>/dev/null || :
    rmdir "$lock" 2>/dev/null || :
  }
  trap cleanup EXIT
  trap 'warn interrupted' HUP INT TERM
  last=''
  [ ! -f "$gd/companion-last-check" ] || read -r last < "$gd/companion-last-check"
  case "$last" in ''|*[!0-9]*) last=0 ;; esac
  if [ "$mode" = daily ] && [ "$last" -gt 0 ] && [ "$now" -ge "$last" ] && [ $((now-last)) -lt 86400 ]; then
    [ ! -f "$gd/companion-update-ready" ] || printf 'update ready, restart to apply\n'
    exit 0
  fi
  # Timestamp records last attempt, bounding offline retries to one per day.
  tmp="$gd/companion-last-check.$$"
  printf '%s\n' "$now" > "$tmp" && mv -f "$tmp" "$gd/companion-last-check" || warn 'cannot save check time'
  export GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=never
  git -c credential.helper= -c credential.interactive=false fetch --quiet --no-tags origin \
    '+refs/heads/main:refs/remotes/origin/main' >/dev/null 2>&1 &
  fetch_pid=$!
  ( sleep 8; kill "$fetch_pid" 2>/dev/null ) >/dev/null 2>&1 &
  timer_pid=$!
  wait "$fetch_pid" 2>/dev/null; rc=$?; fetch_pid=''
  kill "$timer_pid" 2>/dev/null || :
  wait "$timer_pid" 2>/dev/null || :
  timer_pid=''
  [ "$rc" -eq 0 ] || warn 'offline, authentication failure or fetch timeout'
  reserved=$(git ls-tree -r --name-only origin/main -- my-notes downloads .agents/skills 2>/dev/null) || warn 'upstream unreadable'
  [ -z "$reserved" ] || warn 'upstream tracks a protected local folder'
  before=$(git rev-parse HEAD 2>/dev/null) || warn 'current revision unreadable'
  after=$(git rev-parse origin/main 2>/dev/null) || warn 'release revision unreadable'
  if [ "$mode" != startup ]; then
    if [ "$before" != "$after" ]; then
      tmp="$gd/companion-update-ready.$$"
      printf '%s\n' "$after" > "$tmp" && mv -f "$tmp" "$gd/companion-update-ready" || warn 'cannot save update notice'
      printf 'update ready, restart to apply\n'
    else
      rm -f "$gd/companion-update-ready"
    fi
    exit 0
  fi
  old=$(cat VERSION 2>/dev/null) || old=unversioned
  new=$(git show origin/main:VERSION 2>/dev/null) || warn 'release has no VERSION'
  [[ "$new" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || warn 'release VERSION invalid'
  git cat-file -e origin/main:CHANGELOG.md 2>/dev/null || warn 'release has no changelog'
  [ "$before" = "$after" ] && [ "$old" = "$new" ] || changed=1
  git diff --quiet --ignore-submodules -- 2>/dev/null || changed=1
  git diff --cached --quiet --ignore-submodules -- 2>/dev/null || changed=1
  git reset --hard origin/main >/dev/null 2>&1 || {
    printf 'Companion update failed: apply outcome unknown; stop and ask Dan\n' >&2
    exit 1
  }
  rm -f "$gd/companion-update-ready"
  if [ "$changed" -eq 1 ]; then
    if [ -n "${COMPANION_STARTUP_KEY:-}" ]; then
      case "$COMPANION_STARTUP_KEY" in
        *[!a-zA-Z0-9_-]*) printf 'Companion update readiness is invalid. Stop and ask Dan.\n' >&2; exit 1 ;;
      esac
      receipt="$gd/companion-startup/$COMPANION_STARTUP_KEY.applied"
      printf 'applied\n' > "$receipt.tmp.$$" && mv -f "$receipt.tmp.$$" "$receipt" || {
        printf 'Companion update applied but readiness could not be saved. Stop and ask Dan.\n' >&2
        exit 1
      }
    fi
    printf 'Companion updated from %s to %s\n' "$old" "$new"
    awk -v old="$old" '
      /^## / { if($2==old) exit; active=1 }
      active { print }
    ' CHANGELOG.md
    printf 'Restart Claude Code before using the updated companion so all instructions reload.\n'
  else
    printf 'Companion up to date (%s)\n' "$new"
  fi
  exit 0
}
main "$@"
