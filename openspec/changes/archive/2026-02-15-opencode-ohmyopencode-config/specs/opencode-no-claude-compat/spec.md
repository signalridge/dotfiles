## ADDED Requirements

### Requirement: Claude compatibility ingestion SHALL be disabled in oh-my-opencode

Managed `oh-my-opencode.jsonc` SHALL disable Claude compatibility ingestion toggles.

#### Scenario: Compatibility toggles are disabled

- **WHEN** maintainers inspect rendered oh-my-opencode config
- **THEN** Claude compatibility ingestion toggles are explicitly disabled

### Requirement: Sisyphus compatibility SHALL remain native-only

Sisyphus task compatibility SHALL stay native-only and not require Claude compatibility mode.

#### Scenario: Native-only task compatibility

- **WHEN** maintainers inspect Sisyphus task compatibility settings
- **THEN** Claude compatibility mode is disabled

### Requirement: Claude hook bridge SHALL be disabled

Managed hook policy SHALL disable Claude bridge hooks.

#### Scenario: Claude bridge hook is blocked

- **WHEN** maintainers inspect disabled hook configuration
- **THEN** Claude bridge hook identifiers are included

### Requirement: OpenCode launcher SHALL enforce no-Claude prompt isolation

OpenCode launch wrappers SHALL enforce runtime flags that block implicit Claude prompt ingestion.

#### Scenario: Prompt isolation flag is exported

- **WHEN** OpenCode is launched via managed wrapper
- **THEN** runtime includes `OPENCODE_DISABLE_CLAUDE_CODE_PROMPT=1`

### Requirement: no-Claude policy SHALL remain operationally usable

Under no-Claude runtime policy, required repository workflow assets SHALL still be available through managed OpenCode-native paths.

#### Scenario: no-Claude mode does not break required workflow assets

- **WHEN** strict no-Claude runtime policy is active
- **THEN** required commands and skills remain discoverable through managed OpenCode-native projection/path wiring

### Requirement: no-Claude guardrails SHALL remain effective under advanced oh-my features

Advanced oh-my orchestration/experimental settings SHALL NOT re-enable Claude compatibility ingestion paths.

#### Scenario: Advanced settings do not weaken no-Claude policy

- **WHEN** maintainers enable managed advanced settings (including `task_system=true` and enabled dynamic context pruning)
- **THEN** Claude compatibility ingestion toggles remain disabled
- **AND** Claude bridge hooks remain disabled
- **AND** Sisyphus Claude compatibility mode remains disabled
- **AND** wrapper runtime still exports no-Claude prompt isolation flags

### Requirement: no-Claude policy scope SHALL be explicit and auditable

Managed docs/templates SHALL explicitly distinguish blocked Claude compatibility ingestion paths from upstream OpenCode project instruction fallback behavior.

#### Scenario: Operators understand no-Claude scope boundaries

- **WHEN** operators review managed OpenCode no-Claude policy docs
- **THEN** they can identify that implicit global `~/.claude` prompt/skills ingestion is blocked
- **AND** they can identify that upstream project instruction fallback behavior exists
- **AND** they can identify `AGENTS.md` as the authoritative managed project instruction convention
