#!/usr/bin/env bash
#
# Flatten the shared skill store into a view Claude Code can discover.
#
# Skills live nested under ~/.agents/skills/<collection>/<skill>/SKILL.md — the
# Codex-native layout (Codex scans .agents/skills recursively, so it sees them
# all). Claude Code, however, only discovers DIRECT children
# ~/.claude/skills/<name>/SKILL.md and does NOT recurse, so it would otherwise
# see almost nothing.
#
# Fix: keep ~/.agents/skills as the canonical nested store (untouched, shared
# with Codex via ~/.codex/skills) and rebuild ~/.claude/skills as a real
# directory holding one symlink per skill. Claude Code follows symlinks, so the
# whole catalog becomes visible without duplicating any content.
#
# Idempotent: runs after every `chezmoi apply`, so it tracks skills added or
# removed by the .chezmoiexternal.toml.tmpl archives automatically.

set -euo pipefail

agents_skills="${HOME}/.agents/skills"
claude_skills="${HOME}/.claude/skills"

if [ ! -d "$agents_skills" ]; then
    echo "skill-farm: ${agents_skills} not present, skipping" >&2
    exit 0
fi

# ~/.claude/skills used to be a single symlink -> ~/.agents/skills. Replace it
# with a real directory we own.
if [ -L "$claude_skills" ]; then
    rm -f "$claude_skills"
fi
mkdir -p "$claude_skills"

# Remove only the symlinks we manage; leave any hand-placed real dirs intact.
find "$claude_skills" -maxdepth 1 -type l -delete

# One flat symlink per skill, keyed by the skill's own directory name. Skip
# .system (Codex/OpenAI global skills such as imagegen and skill-installer):
# they are OpenAI-specific and hold the only name collision (skill-creator).
while IFS= read -r -d '' skill_md; do
    skill_dir=$(dirname "$skill_md")
    name=$(basename "$skill_dir")
    link="${claude_skills}/${name}"

    # First entry wins on a duplicate name; never clobber a real path.
    if [ -e "$link" ] || [ -L "$link" ]; then
        continue
    fi

    ln -sfn "$skill_dir" "$link"
done < <(find "$agents_skills" -path "${agents_skills}/.system" -prune -o -name SKILL.md -print0)

echo "skill-farm: linked $(find "$claude_skills" -maxdepth 1 -type l | wc -l | tr -d ' ') skills into ${claude_skills}" >&2
