## ADDED Requirements

### Requirement: OpenCode SHALL keep first-class wrapper workflow parity

The system SHALL provide `opencode-manage`, `opencode-with`, and `opencode-token` as first-class operational wrappers aligned with repository AI workflow conventions.

#### Scenario: Wrapper trio is available

- **WHEN** maintainers inspect managed wrapper scripts
- **THEN** account lifecycle, launch override, and token/config helper workflows are available

### Requirement: Shared AI core SHALL support OpenCode context deterministically

Shared AI core helpers SHALL support OpenCode account/provider resolution and tool-scoped key namespace behavior.

#### Scenario: OpenCode context resolves account and key path rules

- **WHEN** OpenCode wrappers execute through shared core
- **THEN** account/provider parsing and key path helpers resolve deterministically in OpenCode context

### Requirement: Account lifecycle SHALL support native and third-party auth models

Managed OpenCode operations SHALL preserve native-provider auth behavior and third-party gopass key lifecycle behavior in one coherent workflow.

#### Scenario: Native provider lifecycle remains supported

- **WHEN** operators manage native provider accounts
- **THEN** workflow follows OpenCode native auth expectations without forced gopass key insertion

#### Scenario: Third-party lifecycle remains supported

- **WHEN** operators manage third-party provider accounts
- **THEN** workflow supports gopass-backed key check/store/update under OpenCode namespace

### Requirement: Workflow diagnostics SHALL be available for day-2 operations

Managed OpenCode workflow SHALL provide diagnostics expectations for command/skill/plugin/auth readiness.

#### Scenario: Operators can validate readiness quickly

- **WHEN** operators run managed diagnostics workflow
- **THEN** they can validate command/skill visibility, plugin state, and auth/key readiness

### Requirement: `opencode-manage` SHALL provide a doctor command

Managed OpenCode account tooling SHALL expose a dedicated diagnostics command for workflow readiness checks.

#### Scenario: Doctor command reports readiness summary

- **WHEN** operators run `opencode-manage doctor`
- **THEN** they can verify runtime dependencies, rendered config validity, command/skill projection state, no-Claude guardrails, and current account auth readiness
- **AND** command output includes a summary of pass/warn/fail counts

### Requirement: User-level instruction entrypoints SHALL be explicit

Managed OpenCode workflow SHALL keep user-level instruction entrypoints (`AGENTS.md`) explicit and documented.

#### Scenario: User-level instruction path is discoverable

- **WHEN** maintainers inspect workflow documentation and templates
- **THEN** they can identify OpenCode user-level `AGENTS.md` path under `~/.config/opencode/`
- **AND** they can identify precedence behavior when `OPENCODE_CONFIG_DIR` is set
- **AND** they can identify project-level instruction chaining behavior

### Requirement: OpenCode user-level AGENTS policy SHALL preserve cross-tool workflow rigor

Managed OpenCode `AGENTS.md` template SHALL preserve core workflow policy depth consistent with repository Claude/Codex conventions while staying OpenCode-native.

#### Scenario: AGENTS policy includes full workflow guardrails

- **WHEN** maintainers inspect managed OpenCode `AGENTS.md` template
- **THEN** they can identify workflow complexity routing, OpenSpec execution gate, command/skill source-of-truth, and safety constraints
- **AND** they can identify OpenCode-native runtime boundary policy without requiring Claude compatibility bridge

### Requirement: Workflow diagnostics SHALL cover advanced oh-my policy state

Managed diagnostics/documentation SHALL let operators verify advanced orchestration and experimental policy state without reading upstream source code.

#### Scenario: Operators can verify advanced policy state

- **WHEN** operators run documented OpenCode diagnostics checks
- **THEN** they can confirm managed `sisyphus/background/tmux` policy state
- **AND** they can confirm managed `experimental` matrix values
- **AND** they can confirm no-Claude guardrails are still active under that profile

### Requirement: Shell UX parity SHALL remain consistent with Claude/Codex

OpenCode aliases and completions SHALL remain aligned with existing wrapper UX conventions.

#### Scenario: Alias/completion parity exists

- **WHEN** maintainers inspect shell alias/completion templates
- **THEN** OpenCode wrapper aliases and completion registration are present and consistent

### Requirement: Manage diagnostics parity SHALL be command-complete across three tools

Repository wrapper UX SHALL keep `claude-manage`, `codex-manage`, and `opencode-manage` diagnostics subcommands aligned with completion exposure.

#### Scenario: Doctor subcommand parity exists

- **WHEN** operators run each tool's `*-manage doctor`
- **THEN** each command prints a readiness report and summary counts
- **AND** each command is discoverable in zsh completion entries
- **AND** no completion advertises a subcommand that wrapper scripts do not implement

### Requirement: Shared workflow assets SHALL preserve explicit abstraction boundaries

Shared command/skill assets SHALL be centralized in `dot_agents`, while tool runtime/config ownership remains tool-specific.

#### Scenario: Abstraction boundary remains stable

- **WHEN** maintainers inspect command/skill/instruction templates
- **THEN** shared commands/skills resolve from `dot_agents` or `~/.agents` source-of-truth
- **AND** tool runtime config roots (`~/.claude`, `~/.codex`, `~/.config/opencode`) remain explicit and independent
- **AND** no hidden cross-tool config coupling is introduced

### Requirement: Documentation SHALL cover operational workflow, not only setup

OpenCode docs SHALL cover account model, no-Claude policy, command/skill projection behavior, and troubleshooting steps.

#### Scenario: Docs are operationally complete

- **WHEN** users read OpenCode docs
- **THEN** they can run daily operations and diagnose common failures without undocumented assumptions

### Requirement: Documentation SHALL include cross-tool parity matrix

Managed documentation SHALL explicitly map Claude/Codex workflow primitives to OpenCode/oh-my equivalents and identify intentional deltas.

#### Scenario: Operators can audit parity and deltas

- **WHEN** operators review OpenCode workflow documentation
- **THEN** they can identify parity status for account management, command routing, skill loading, instruction files, and diagnostics flows
- **AND** they can identify intentionally unsupported or deferred parity items

### Requirement: Managed defaults SHALL be informed by vetted community patterns

OpenCode/oh-my managed defaults SHALL be reviewed against representative community configurations and only absorb patterns that pass repository guardrails.

#### Scenario: Community patterns are reviewed with explicit decisions

- **WHEN** maintainers evolve managed OpenCode/oh-my defaults
- **THEN** they can trace accepted/rejected community patterns to explicit rationale in docs/spec artifacts

### Requirement: Tests SHALL validate runtime policy behavior

The repository test suite SHALL validate runtime wrapper behavior and policy-sensitive invariants, not only static template rendering.

#### Scenario: Tests cover policy-sensitive behavior

- **WHEN** maintainers run repository tests
- **THEN** tests verify account resolution, key-path behavior, projection assumptions, and runtime isolation invariants
