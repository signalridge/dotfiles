#!/usr/bin/env bash
#
# Keep Claude Code, Codex, and Cursor CLI user-level skill dirs as real
# directories, not leftover whole-dir symlinks to the shared ~/.harnesses/skills
# library. `skill-activate` intentionally does not manage these user-level dirs;
# it only writes per-project symlinks under the current directory's
# ./.claude/skills, ./.codex/skills, ./.pi/skills, and ./.cursor/skills.

set -euo pipefail

for d in "$HOME/.claude/skills" "$HOME/.codex/skills" "$HOME/.cursor/skills"; do
    [ -L "$d" ] && rm -f "$d"
    mkdir -p "$d"
done
