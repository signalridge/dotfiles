# Dotfiles Integration Standard for Local Skills

This project manages upstream skills through `.chezmoiexternal.toml.tmpl` with many `exact = true` destinations.

## Placement Rule

Custom/local skills must live under:

- `.agents/skills/local/<skill-name>/`

In this repository layout, that maps to:

- `dot_agents/skills/local/<skill-name>/`

## Conflict Rule

Do not place custom skills under externally managed exact-sync paths such as:

- `.agents/skills/systems-programming/`
- `.agents/skills/backend-development/`
- `.agents/skills/python-development/`
- `.agents/skills/ecosystem/...`

Reason: these paths are populated by archives and may overwrite/remove unmanaged content.

## Acceptance Checklist

1. Skill exists under `dot_agents/skills/local/<skill-name>/`.
2. `.chezmoiexternal.toml.tmpl` has no external target for `.agents/skills/local`.
3. `quick_validate.py` passes.
4. `package_skill.py` produces a `.skill` artifact.
5. Skill includes only necessary files (`SKILL.md`, optional `references/`, optional `scripts/`, optional `assets/`).
