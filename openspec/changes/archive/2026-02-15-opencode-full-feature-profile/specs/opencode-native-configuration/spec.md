## ADDED Requirements

### Requirement: OpenCode native config SHALL expose a managed full-feature operational surface

Managed `opencode.jsonc` SHALL explicitly configure high-value native runtime sections beyond baseline model/provider fields.

#### Scenario: Full-feature sections are rendered

- **WHEN** maintainers render `~/.config/opencode/opencode.jsonc`
- **THEN** config includes explicit `agent`, `command`, `lsp`, `formatter`, `share`, `autoupdate`, and `tui` sections
- **AND** baseline deterministic sections (`model`, `small_model`, `provider`, `plugin`, `permission`) remain present

### Requirement: Managed OpenCode feature profile SHALL remain deterministic under account selector changes

Expanded configuration SHALL preserve selector-driven model/provider behavior.

#### Scenario: Expanded profile does not break selector determinism

- **WHEN** `opencodeProviderAccount` changes and templates are re-rendered
- **THEN** `model` and `small_model` still resolve deterministically by selected provider family
- **AND** expanded sections do not alter provider/env/baseURL mapping semantics

### Requirement: Managed oh-my profile SHALL avoid stale unsupported keys

Managed oh-my configuration SHALL only include deliberate policy keys and SHALL not retain stale unsupported managed keys.

#### Scenario: Governance profile stays schema-safe

- **WHEN** maintainers inspect rendered `~/.config/opencode/oh-my-opencode.jsonc`
- **THEN** required governance controls remain explicit
- **AND** stale unsupported managed keys (for example `disabled_tools`) are absent
