#!/usr/bin/env bash
#
# Claude Code and Codex each read a CURATED set of per-skill symlinks managed
# by `skill-activate`, not a single symlink to the whole ~/.agents/skills
# library. Ensure both user-level dirs are real directories (convert any
# leftover whole-dir symlink) and leave their contents alone. Empty by default
# → no user-level skills are active until you pick them. Project-level sets
# live in each project's ./.claude/skills and ./.agents/skills.

set -euo pipefail

for d in "$HOME/.claude/skills" "$HOME/.codex/skills"; do
    [ -L "$d" ] && rm -f "$d"
    mkdir -p "$d"
done
