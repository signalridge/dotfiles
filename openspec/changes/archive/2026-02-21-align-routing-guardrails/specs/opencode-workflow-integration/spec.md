## ADDED Requirements

### Requirement: OpenCode workflow policy SHALL include explicit guardrail-sensitive routing

Managed OpenCode AGENTS policy SHALL include guardrail-sensitive areas and require risk-triggered review discipline for L3/L4 changes, including post-change reporting expectations for sensitive categories.

#### Scenario: Guardrail-sensitive workflow policy exists

- **WHEN** maintainers inspect managed OpenCode AGENTS policy
- **THEN** guardrail-sensitive categories and review expectations are explicitly documented

#### Scenario: OpenCode L3+ pre-analysis references guardrail-triggered checks

- **WHEN** maintainers inspect OpenCode L3+ pre-analysis guidance
- **THEN** risk areas include guardrail-triggered checks rather than only generic risk labels

### Requirement: OpenCode guardrail policy anchors SHALL be machine-verifiable

Managed OpenCode guardrail policy SHALL expose deterministic anchor terms so repository tests can validate governance content by pattern matching.

#### Scenario: Guardrail anchor terms are present in OpenCode policy

- **WHEN** maintainers inspect managed OpenCode AGENTS policy
- **THEN** a fixed Guardrails section heading is present
- **AND** sensitive-category anchors include: `Authentication`, `Authorization`, `Financial`, `Security`, `Data Schema`, `External APIs`, `Irreversible Ops`, `PII/Privacy`
- **AND** high-risk operation wording explicitly includes confirmation requirements for archive/rewrite style operations

### Requirement: OpenCode policy SHALL document runtime enforcement boundaries

Managed OpenCode workflow guidance SHALL explicitly document strict-mode runtime boundaries and define confirmation-first handling expectations for high-risk operations.

#### Scenario: Runtime boundary statement is explicit

- **WHEN** operators inspect managed OpenCode AGENTS policy
- **THEN** policy distinguishes strict native mode runtime behavior from hook-enabled Claude behavior
- **AND** policy explicitly documents that AGENTS -> CLAUDE fallback behavior exists in upstream OpenCode rules
- **AND** policy describes when `OPENCODE_DISABLE_CLAUDE_CODE=1` is required for full fallback isolation
- **AND** policy requires explicit confirmation before high-risk operations

### Requirement: OpenCode command-surface compatibility SHALL be explicit

Managed OpenCode workflow documentation SHALL explicitly cover command-path differences between OpenSpec-generated and OpenCode-documented command surfaces.

#### Scenario: Command-path compatibility guidance is discoverable

- **WHEN** operators inspect managed OpenCode workflow documentation
- **THEN** they can identify OpenSpec-generated `.opencode/command/opsx-*.md` behavior
- **AND** they can identify OpenCode-documented `.opencode/commands`/`~/.config/opencode/commands` behavior
- **AND** managed compatibility expectations (authoritative path and bridge strategy) are explicit

### Requirement: OpenCode search routing SHALL prioritize Tavily MCP with explicit fallback boundary

Managed OpenCode workflow policy SHALL treat Tavily MCP as the primary search route and explicitly document precedence relative to oh-my-opencode Exa-oriented defaults.

#### Scenario: Tavily-first search policy anchor is explicit

- **WHEN** operators inspect managed OpenCode AGENTS policy
- **THEN** policy explicitly states Tavily MCP is primary for web/news/docs lookup
- **AND** fallback to built-in/non-Tavily search is explicitly conditional on Tavily unavailability/failure

#### Scenario: Tavily-versus-Exa boundary is explicit for OpenCode operators

- **WHEN** operators inspect managed OpenCode governance docs/config
- **THEN** they can determine whether Exa websearch remains enabled as fallback/secondary path
- **AND** they can determine the authoritative managed behavior when Tavily MCP is unavailable

### Requirement: OpenCode subagent execution diagnostics SHALL be explicit

Managed OpenCode policy SHALL document execution-mode expectations and diagnostics for exploration/research subagents.

#### Scenario: Background-mode expectation is explicit for explore/librarian

- **WHEN** operators inspect managed OpenCode policy guidance
- **THEN** guidance states `explore`/`librarian` are background-first and synchronous blocking usage is discouraged for routine exploration

#### Scenario: Empty subagent response diagnostic is explicitly classified

- **WHEN** operators inspect managed OpenCode troubleshooting/policy guidance
- **THEN** `No assistant or tool response found` is described as an execution-channel diagnostic
- **AND** guidance specifies retry/escalation behavior instead of treating it as successful business output

### Requirement: OpenSpec wrapper ownership and sync authority SHALL be explicit across tools

Managed documentation and policy SHALL clearly describe where OpenSpec wrappers are sourced and how they are refreshed per tool surface.

#### Scenario: Wrapper authority guidance is discoverable

- **WHEN** operators inspect managed tool workflow documentation
- **THEN** they can identify authoritative wrapper/prompt source and refresh command path per tool surface
- **AND** guidance reduces ambiguity between repository-local and global wrapper materialization

### Requirement: OpenSpec artifact versioning posture SHALL be explicit and default local-only

Repository workflow governance SHALL explicitly declare that this repository treats `openspec/` artifacts as local working state by default.

#### Scenario: Local-only posture is visible and enforceable

- **WHEN** maintainers inspect repository OpenSpec governance docs/configuration
- **THEN** `.gitignore` contains a rule that ignores `openspec/`
- **AND** tool policy docs explicitly state that OpenSpec artifacts are not version-controlled by default
- **AND** `.gitignore` and documentation do not silently contradict each other

#### Scenario: Tracking OpenSpec artifacts requires explicit opt-in

- **WHEN** maintainers need version-controlled OpenSpec artifacts for collaboration/audit
- **THEN** they must intentionally change ignore policy before tracking `openspec/` artifacts
- **AND** the default local-only posture remains the documented baseline for this repository

### Requirement: OpenCode AGENTS opsx references SHALL use tool-native syntax

OpenCode AGENTS policy SHALL reference opsx commands using hyphen form (`/opsx-*`) consistently, with a single cross-tool disambiguation note for Claude colon form.

#### Scenario: Opsx syntax is consistent in OpenCode AGENTS

- **WHEN** maintainers inspect managed OpenCode AGENTS policy
- **THEN** all opsx command references use hyphen form (`/opsx-new`, `/opsx-ff`, `/opsx-apply`, `/opsx-verify`, `/opsx-archive`)
- **AND** no mixed colon-form references appear outside the optional disambiguation note
