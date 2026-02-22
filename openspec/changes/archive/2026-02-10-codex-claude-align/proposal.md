## Why

Align Codex and Claude workflows to reduce drift between commands and ensure a consistent operator experience. Improve Codex capability parity (prompts, MCP, features) without adding hooks complexity.

## What Changes

- Add shared command source under `~/.agents/commands` and move core command content there.
- Update Claude command templates to include shared command content.
- Add Codex prompt templates that include the same shared command content.
- Enhance Codex config defaults/features (tool toggles, environment policy, MCP settings) for higher capability parity.
- Keep existing MCP server list and ensure related feature flags are enabled for Codex.

## Capabilities

### New Capabilities

- `shared-ai-commands`: Single-source command content used by both Claude and Codex.
- `codex-config-enhancements`: Expanded Codex feature/tool configuration for richer workflow parity.

### Modified Capabilities

- (none)

## Impact

- New templates under `dot_agents/commands/core/`.
- Updates to `dot_claude/commands/core/*.md` and new `dot_codex/prompts/*.md`.
- Updates to `dot_codex/config.toml.tmpl` and `dot_codex/AGENTS.md.tmpl` (if needed).
- Updates to `.chezmoidata/codex.yaml` to reflect new feature defaults.
