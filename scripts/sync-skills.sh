#!/usr/bin/env bash
# Local hard links, never copies or Git symlinks. Requires one hard-link capable volume.
set +x
unset NURTURE_API_KEY
set -eu
root=$(cd "$(dirname "$0")/.." && pwd -P)
cd "$root"
target=.agents/skills
[ ! -L .agents ] && [ ! -L "$target" ] || { printf 'Skills unavailable: unexpected local directory link; ask Dan\n'; exit 1; }
mkdir -p "$target"
# Only manage SKILL.md aliases. Refuse unexpected content rather than delete notes.
for dir in "$target"/*; do
  [ -d "$dir" ] || continue
  name=${dir##*/}
  if [ ! -f ".claude/skills/$name/SKILL.md" ]; then
    [ ! -L "$dir" ] || { printf 'Skills unavailable: unexpected skill link\n'; exit 1; }
    rm -f "$dir/SKILL.md"
    rmdir "$dir" || { printf 'Skills unavailable: unexpected local skill content; ask Dan\n'; exit 1; }
  fi
done
for source in .claude/skills/*/SKILL.md; do
  [ -f "$source" ] || continue
  name=${source%/SKILL.md}; name=${name##*/}
  dir="$target/$name"
  [ ! -L "$dir" ] || { printf 'Skills unavailable: unexpected skill directory link\n'; exit 1; }
  mkdir -p "$dir"
  if [ "$source" -ef "$dir/SKILL.md" ]; then continue; fi
  tmp="$dir/.link.$$"
  trap 'rm -f "$tmp"' EXIT
  ln "$source" "$tmp" || { printf 'Skills unavailable: hard links unsupported; use a local APFS or NTFS folder and ask IT\n'; exit 1; }
  [ "$source" -ef "$tmp" ] || { printf 'Skills unavailable: link became a copy; ask IT\n'; exit 1; }
  mv -f "$tmp" "$dir/SKILL.md"
done
printf 'OK Skills: Claude Code and Codex share the same files\n'
