## ADDED Requirements

### Requirement: OpenCode doctor diagnostics SHALL report websearch provider readiness

Managed OpenCode diagnostics SHALL report configured websearch provider and provider-specific readiness state.

#### Scenario: Tavily provider without key emits warning

- **WHEN** `opencode-manage doctor` runs and managed websearch provider is `tavily`
- **THEN** diagnostics warn when `TAVILY_API_KEY` is unset
- **AND** diagnostics report provider-ready state when `TAVILY_API_KEY` is set

### Requirement: Manage diagnostics summary SHALL remain human-readable

Repository manage diagnostics output SHALL render summary status using readable formatting rather than escaped control literals.

#### Scenario: Summary renders readable status counts

- **WHEN** operators run `claude-manage doctor`, `codex-manage doctor`, or `opencode-manage doctor`
- **THEN** summary line displays readable status counts for ok/warning/failed

### Requirement: Account-removal prompts SHALL be format-string-safe

Manage account-removal prompts SHALL avoid direct variable interpolation in `printf` format strings.

#### Scenario: Prompt string handling remains safe for account names

- **WHEN** operators remove an account whose label contains format-control characters
- **THEN** prompt output remains literal and does not alter output formatting behavior
