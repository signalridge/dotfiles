## ADDED Requirements

### Requirement: Manage scripts SHALL use chezmoi-compatible script exclusion flags

Managed `claude-manage`, `codex-manage`, and `opencode-manage` apply workflows SHALL use a `chezmoi`-compatible script exclusion mechanism.

#### Scenario: Apply command remains compatible on current chezmoi versions

- **WHEN** operators run account switch/create/update workflows in any manage script
- **THEN** the script uses `chezmoi apply` with a supported script exclusion flag
- **AND** no workflow path relies on unsupported `--no-scripts`

### Requirement: OpenCode diagnostics SHALL report advanced feature readiness

`opencode-manage doctor` SHALL verify readiness for advanced managed sections and required binaries.

#### Scenario: Doctor reports command/lsp/formatter readiness

- **WHEN** operators run `opencode-manage doctor`
- **THEN** output reports presence/readiness for managed `command`, `lsp`, and `formatter` sections
- **AND** output warns when enabled LSP/formatter commands are not found in PATH
- **AND** summary remains human-readable

### Requirement: Tests SHALL prevent apply-flag compatibility regressions

Repository tests SHALL fail if unsupported `chezmoi` script exclusion flags reappear in manage scripts.

#### Scenario: Regression test catches unsupported flag

- **WHEN** maintainers run repository tests
- **THEN** tests fail if `--no-scripts` appears in managed AI workflow scripts
- **AND** tests assert supported `--exclude scripts` usage remains present
