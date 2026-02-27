# opencode-workflow-integration Specification

## Purpose

Define repository-managed OpenCode workflow boundaries so runtime behavior stays consistent with current implementation: native OpenCode CLI operations, managed config/templates, and cross-tool diagnostics without repository-specific OpenCode wrappers.

## Requirements

### Requirement: OpenCode operations SHALL be native CLI first

The repository SHALL treat native `opencode` commands as the operational entrypoint and SHALL NOT provide repository-managed OpenCode wrapper binaries (`opencode-manage`, `opencode-with`, `opencode-token`).

#### Scenario: Wrapper scripts are not managed

- **WHEN** maintainers inspect managed scripts under `dot_local/bin`
- **THEN** OpenCode wrapper binaries are absent
- **AND** OpenCode workflow instructions reference native `opencode` operations

### Requirement: OpenCode command and skill projection SHALL remain explicit

Shared command and skill assets SHALL remain discoverable through OpenCode-native paths via managed symlink templates.

#### Scenario: Projection topology is present

- **WHEN** maintainers inspect OpenCode template assets
- **THEN** `private_dot_config/opencode/commands/symlink_core.tmpl` points to shared command source-of-truth
- **AND** `private_dot_config/opencode/symlink_skills.tmpl` points to shared skill source-of-truth

### Requirement: OpenCode command templates SHALL avoid removed wrapper dependencies

Managed OpenCode command templates SHALL use available cross-tool diagnostics and SHALL NOT reference removed OpenCode wrapper commands.

#### Scenario: doctor-all template is executable in current repo

- **WHEN** maintainers inspect `private_dot_config/opencode/opencode.jsonc.tmpl`
- **THEN** `doctor-all` references `claude-manage doctor` and `codex-manage doctor`
- **AND** no managed command template requires `opencode-manage`

### Requirement: Shell UX SHALL NOT advertise removed OpenCode wrappers

Shell aliases and completion registration SHALL stay aligned with available commands.

#### Scenario: No stale alias or completion entries remain

- **WHEN** maintainers inspect `dot_custom/alias.sh` and `dot_custom/functions.sh`
- **THEN** no alias/completion entries reference removed OpenCode wrappers

### Requirement: OpenCode AGENTS policy SHALL describe native runtime boundaries

Managed OpenCode user-level AGENTS policy SHALL describe strict/compat profile boundaries and native operation guidance without wrapper assumptions.

#### Scenario: AGENTS runtime boundary guidance matches implementation

- **WHEN** maintainers inspect `private_dot_config/opencode/AGENTS.md`
- **THEN** strict/compat behavior remains explicit
- **AND** operator guidance uses native `opencode` plus existing cross-tool diagnostics

### Requirement: Theme assets SHALL be managed as OpenCode configuration artifacts

Custom OpenCode themes included by the repository SHALL be version-controlled as template assets and rendered under OpenCode config paths.

#### Scenario: Managed theme asset exists

- **WHEN** maintainers inspect repository OpenCode template assets
- **THEN** theme files are present under `private_dot_config/opencode/themes/`
- **AND** theme files are valid JSON documents

### Requirement: Tests SHALL match the native no-wrapper workflow

Repository tests SHALL validate managed OpenCode config rendering and SHALL NOT require deleted wrapper workflows.

#### Scenario: Test suite reflects current architecture

- **WHEN** maintainers run repository tests
- **THEN** OpenCode config rendering tests pass
- **AND** no test requires removed OpenCode wrapper binaries

### Requirement: Manage scripts SHALL retain chezmoi apply compatibility for supported tools

Managed `claude-manage` and `codex-manage` workflows SHALL continue to use a chezmoi-compatible script exclusion mechanism.

#### Scenario: Compatible apply flags remain enforced

- **WHEN** operators run account switch/create/update workflows in managed `claude-manage` or `codex-manage`
- **THEN** `chezmoi apply` uses supported exclusion behavior
- **AND** no workflow path uses unsupported `--no-scripts`
