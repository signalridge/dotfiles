## Why

Current OpenCode integration is stable, but still below the user's target for a "full-feature" daily profile.

Confirmed gaps:

- `opencode.jsonc` does not yet express key native features (`agent`, `command`, `lsp`, `formatter`, `share`, `autoupdate`, `tui`) as managed policy.
- `oh-my-opencode.jsonc` still contains stale/loose fields (for example `disabled_tools`) and lacks broader governance coverage for hooks/operational controls.
- Three manage scripts still call `chezmoi apply --no-scripts`, which is incompatible with current `chezmoi` and breaks account workflows.
- Existing diagnostics and tests do not fully prove advanced feature readiness (especially LSP/formatter/command wiring and binary availability).

## What Changes

- Expand managed OpenCode config to a broader, schema-backed feature profile.
- Expand managed oh-my-opencode config with stronger hook/governance policy while preserving no-Claude runtime boundaries and native MCP independence.
- Replace `--no-scripts` with `--exclude scripts` in all affected manage scripts.
- Extend `opencode-manage doctor` to check advanced feature readiness (`lsp`, `formatter`, `command`) and executable availability.
- Extend tests and docs to prevent regression.

## Scope

Included:

- OpenCode native configuration surface expansion.
- oh-my-opencode governance/profile expansion.
- Manage-script compatibility fix.
- Doctor/test/doc updates tied to these behaviors.

Excluded:

- Reworking user's MCP architecture (user already implemented native MCP separately).
- Changing no-Claude baseline policy direction.

## Capabilities

### Modified Capabilities

- `opencode-native-configuration`
- `opencode-workflow-integration`

## Impact

- `private_dot_config/opencode/opencode.jsonc.tmpl`
- `private_dot_config/opencode/oh-my-opencode.jsonc.tmpl`
- `dot_local/bin/executable_opencode-manage.tmpl`
- `dot_local/bin/executable_codex-manage.tmpl`
- `dot_local/bin/executable_claude-manage.tmpl`
- `tests/test_opencode_config_rendering.sh`
- `docs/opencode-provider.md`
- new compatibility regression test for `chezmoi apply` flags
