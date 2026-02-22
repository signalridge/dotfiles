## ADDED Requirements

### Requirement: OpenCode launcher SHALL enforce isolation flags only in strict mode

Managed launcher behavior SHALL follow selected compatibility mode.

#### Scenario: Strict mode injects no-Claude isolation env flags

- **WHEN** operators launch OpenCode in strict mode
- **THEN** launcher exports strict isolation flags before execution

#### Scenario: Compat mode does not inject strict isolation env flags

- **WHEN** operators launch OpenCode in compat mode
- **THEN** launcher runs without forced strict isolation env flags

### Requirement: OpenCode doctor SHALL validate compatibility and routing readiness

Diagnostics SHALL report compatibility profile drift and operational routing readiness.

#### Scenario: Doctor validates compatibility mode and MCP/provider readiness

- **WHEN** operators run `opencode-manage doctor`
- **THEN** output validates rendered compatibility state against expected mode
- **AND** output reports built-in MCP enabled/disabled state
- **AND** output reports category/agent model provider routability
