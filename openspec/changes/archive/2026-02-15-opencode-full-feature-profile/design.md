## Pre-Analysis

- **Similar patterns**:
  - `private_dot_config/opencode/opencode.jsonc.tmpl`
  - `private_dot_config/opencode/oh-my-opencode.jsonc.tmpl`
  - `dot_local/bin/executable_{claude,codex,opencode}-manage.tmpl`
- **Dependencies**:
  - OpenCode schema (`https://opencode.ai/config.json`)
  - oh-my-opencode schema/docs (`assets/oh-my-opencode.schema.json`, `docs/configurations.md`)
  - `chezmoi` apply-flag behavior on current installed version
- **Conventions**:
  - no-Claude runtime boundary stays enabled
  - provider/account resolution remains data-driven via `opencodeProviderAccount`
  - diagnostics output must remain human-readable and testable
- **Risk areas**:
  - schema drift between OpenCode and oh-my-opencode
  - enabling advanced features without binary/tool readiness checks
  - regressions in account switching if apply flag remains incompatible

## Design Goals

1. Expand managed OpenCode profile with high-value native features that are stable and testable.
2. Keep oh-my profile explicit, schema-safe, and governance-driven.
3. Preserve existing policy boundaries (native runtime, no-Claude compatibility bridge).
4. Make compatibility and readiness observable via doctor + tests.

## Configuration Design

### OpenCode (`opencode.jsonc`)

Add explicit managed sections:

- `agent`: tuned defaults for `build` and `plan` to keep behavior deterministic.
- `command`: reusable command templates for local workflow operations.
- `lsp`: explicit server definitions (enabled + optional-disabled entries) with extension routing.
- `formatter`: explicit formatter definitions with command/extension mapping.
- `share`: explicit sharing mode.
- `autoupdate`: explicit update policy.
- `tui`: explicit terminal UX tuning.

Keep existing deterministic behavior:

- `model`/`small_model` derivation from `opencodeProviderAccount`.
- provider map and plugin order.
- permission defaults as confirmation-first.

### oh-my-opencode

Strengthen governance profile:

- keep no-Claude toggles off (`claude_code.* = false`).
- retain required bridge disable (`disabled_hooks` contains `claude-code-hooks`).
- remove non-schema stale managed key (`disabled_tools`).
- add explicit hook/governance controls and operational settings where stable.

## Workflow Compatibility Design

### Chezmoi apply flag

Replace all `chezmoi apply --no-scripts` calls with:

- `chezmoi apply --verbose --exclude scripts ...`

Rationale:

- current installed `chezmoi` rejects `--no-scripts`.
- `--exclude scripts` is supported and preserves intent.

### Doctor readiness checks

Extend `opencode-manage doctor` with:

- config presence checks for `command`, `lsp`, `formatter`.
- per-entry command executable checks for enabled LSP/formatter entries.
- summary-integrated warnings for missing binaries or missing sections.

## Verification Strategy

- Update rendering tests for new managed fields and schema-safe constraints.
- Add regression test to fail if `--no-scripts` appears in manage scripts.
- Run full repository tests.
- Run OpenSpec validation for this change.
