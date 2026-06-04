#!/usr/bin/env bash
#
# Keep Claude Code and Codex user-level skill dirs as real directories, not
# leftover whole-dir symlinks to the shared ~/.harnesses/skills library.
# `skill-activate` intentionally does not manage these user-level dirs; it only
# writes per-project symlinks under the current directory's ./.claude/skills and
# ./.codex/skills.

set -euo pipefail

for d in "$HOME/.claude/skills" "$HOME/.codex/skills"; do
    [ -L "$d" ] && rm -f "$d"
    mkdir -p "$d"
done
