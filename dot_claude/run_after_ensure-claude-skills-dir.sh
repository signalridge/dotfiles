#!/usr/bin/env bash
#
# Claude Code reads ~/.claude/skills as a CURATED set of per-skill symlinks
# (managed interactively by `skill-activate`), not a single symlink to the
# whole library. Ensure it is a real directory: convert any leftover
# whole-dir symlink (e.g. an older ~/.claude/skills -> ~/.agents/skills) and
# create it empty if missing. Contents (the curated symlinks) are left alone,
# so a fresh machine starts with NO user-level skills active by default.

set -euo pipefail

d="$HOME/.claude/skills"
[ -L "$d" ] && rm -f "$d"
mkdir -p "$d"
