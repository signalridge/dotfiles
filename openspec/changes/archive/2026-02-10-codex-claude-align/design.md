## Context

Claude commands live under `dot_claude/commands`, while Codex uses global prompts under `~/.codex/prompts`. There is no shared command source, so changes drift between tools. Codex config is already customized but lacks parity with Claude workflow features (prompts, MCP alignment, richer tool toggles). Hooks are intentionally skipped to avoid complex interception.

## Goals / Non-Goals

**Goals:**

- Single-source command content shared by Claude and Codex.
- Codex prompts generated from shared command content.
- Codex config enhanced for higher capability parity (features, tools, env policy, MCP support).
- Minimal change to existing Claude behavior and paths.

**Non-Goals:**

- Implement runtime hooks or tool event interception for Codex.
- Rework Claude settings or permissions model.
- Add new external dependencies beyond existing MCP wrappers.

## Decisions

- **Shared command source in `~/.agents/commands`**: Use `dot_agents/commands/core/*.md` as the canonical content. This matches the shared skills model and avoids tool-specific duplication.
- **Claude commands link to shared content**: Replace `dot_claude/commands/core/*.md` with symlinks pointing at `~/.agents/commands`, keeping existing Claude command paths stable.
- **Codex prompts link to shared content**: Create `dot_codex/prompts/*.md` at the top level (no subdirs), each symlinked to the shared command file to mirror Claude commands.
- **Codex config enhancements**: Enable additional features and tools via the documented schema; set `shell_environment_policy.inherit = "all"` and `ignore_default_excludes = true` for maximum environment visibility; keep `approval_policy = never`, `sandbox_mode = danger-full-access`, `network_access = enabled`.
- **MCP alignment**: Keep existing `mcp_servers` list in `.chezmoidata/codex.yaml` and enable MCP-friendly feature flags rather than introducing new servers.

## Risks / Trade-offs

- **More permissive shell environment** → Mitigation: keep changes scoped to Codex config only and document the choice in AGENTS.
- **Feature flags may be unstable** → Mitigation: enable `suppress_unstable_features_warning` and keep feature list minimal to documented booleans.
- **Symlink target drift** → Mitigation: centralize shared command content under `~/.agents/commands` and avoid nested directories for Codex prompts.

## Migration Plan

1. Add shared command templates under `dot_agents/commands/core`.
2. Convert `dot_claude/commands/core/*.md` to symlinks pointing at shared command templates.
3. Add `dot_codex/prompts/*.md` symlink templates pointing at shared command templates.
4. Update `.chezmoidata/codex.yaml` and `dot_codex/config.toml.tmpl` to enable features/tools and env policy.
5. Run `chezmoi diff` and `chezmoi apply`, then verify `/plan` and `/review` in Claude and Codex.

## Open Questions

- Confirm the final list of Codex feature flags to enable.
