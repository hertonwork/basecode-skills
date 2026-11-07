#!/usr/bin/env bash
# Symlink the skills in this repo into a skills directory, for agents that
# read SKILL.md folders directly (Claude Code personal/project skills, Codex,
# or any tool that supports the Agent Skills format) without the plugin system.
#
# Usage:
#   scripts/install-skills.sh                 # -> ~/.claude/skills (personal, all projects)
#   scripts/install-skills.sh .claude/skills  # -> project-level skills in the current repo
#   scripts/install-skills.sh ~/.codex/skills # -> any other skills directory
#
# Re-running is safe: existing links are replaced, other files are untouched.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target="${1:-$HOME/.claude/skills}"

mkdir -p "$target"

for skill_dir in "$repo_root"/plugins/*/skills/*/; do
    name="$(basename "$skill_dir")"
    link="$target/$name"

    if [ -e "$link" ] && [ ! -L "$link" ]; then
        echo "skip  $link exists and is not a symlink"
        continue
    fi

    ln -sfn "${skill_dir%/}" "$link"
    echo "link  $link -> ${skill_dir%/}"
done

echo
echo "Installed into $target. Restart your agent session to pick up the skills."
