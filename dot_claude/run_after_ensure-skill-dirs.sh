#!/usr/bin/env bash
#
# Keep Claude Code, Codex, Pi, Cursor CLI, and Kimi Code user-level skill dirs
# as real directories, not leftover whole-dir symlinks to the shared
# ~/.harnesses/skills
# library. `skill-activate` intentionally does not manage these user-level dirs;
# it only writes per-project symlinks under the current directory's
# ./.claude/skills, ./.codex/skills, ./.pi/skills, ./.cursor/skills, and
# ./.kimi-code/skills.

set -euo pipefail

for d in "$HOME/.claude/skills" "$HOME/.codex/skills" "$HOME/.pi/agent/skills" "$HOME/.cursor/skills" "$HOME/.kimi-code/skills"; do
    [ -L "$d" ] && rm -f "$d"
    mkdir -p "$d"
done
