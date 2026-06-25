#!/usr/bin/env bash
set -euo pipefail

# Links all skills in the repository to tool-specific skill directories:
#   ~/.claude/skills
#   ~/.cursor/skills
#   ~/.codex/skills
#   ~/.config/opencode/skills

REPO="$(cd "$(dirname "$0")/.." && pwd)"
DESTS=(
  "$HOME/.claude/skills"
  "$HOME/.cursor/skills"
  "$HOME/.codex/skills"
  "$HOME/.config/opencode/skills"
)

if [[ -t 1 ]]; then
  BOLD=$'\033[1m'
  GRAY=$'\033[38;5;245m'
  RESET=$'\033[0m'
else
  BOLD='' GRAY='' RESET=''
fi

# If a destination is a symlink that resolves into this repo, we'd end up
# writing the per-skill symlinks back into the repo's own skills/ tree. Detect
# and bail out instead of polluting the working copy.
guard_dest() {
  local dest="$1"
  if [ -L "$dest" ]; then
    local resolved
    resolved="$(readlink -f "$dest")"
    case "$resolved" in
      "$REPO"|"$REPO"/*)
        echo "error: $dest is a symlink into this repo ($resolved)." >&2
        echo "Remove it (rm \"$dest\") and re-run; the script will recreate it as a real dir." >&2
        exit 1
        ;;
    esac
  fi
}

link_skills_to() {
  local dest="$1"
  find "$REPO/skills" -name SKILL.md -not -path '*/node_modules/*' -not -path '*/deprecated/*' -print0 |
  while IFS= read -r -d '' skill_md; do
    local src name target
    src="$(dirname "$skill_md")"
    name="$(basename "$src")"
    target="$dest/$name"

    if [ -e "$target" ] && [ ! -L "$target" ]; then
      rm -rf "$target"
    fi

    ln -sfn "$src" "$target"
    echo "${GRAY}  $name -> $src${RESET}"
  done
}

for dest in "${DESTS[@]}"; do
  guard_dest "$dest"
  mkdir -p "$dest"
  echo "${BOLD}${dest}${RESET}"
  link_skills_to "$dest"
done
