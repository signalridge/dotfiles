## ADDED Requirements

### Requirement: Codex workflow policy SHALL include explicit guardrail-sensitive risk routing

Codex managed workflow policy SHALL define guardrail-sensitive areas and require risk-triggered review discipline for L3/L4 changes, including a post-change report requirement for sensitive categories.

#### Scenario: Guardrail categories are explicitly documented

- **WHEN** maintainers inspect managed Codex AGENTS policy
- **THEN** policy includes explicit guardrail-sensitive categories and risk review expectations

#### Scenario: L3+ pre-analysis references guardrail-triggered risk check

- **WHEN** maintainers inspect managed Codex pre-analysis guidance
- **THEN** risk areas include guardrail-triggered checks instead of only generic risk labels

### Requirement: Codex guardrail policy anchors SHALL be machine-verifiable

Codex managed guardrail policy SHALL expose deterministic anchor terms so repository tests can validate governance content by pattern matching.

#### Scenario: Guardrail anchor terms are present

- **WHEN** maintainers inspect managed Codex AGENTS policy
- **THEN** a fixed Guardrails section heading is present
- **AND** sensitive-category anchors include: `Authentication`, `Authorization`, `Financial`, `Security`, `Data Schema`, `External APIs`, `Irreversible Ops`, `PII/Privacy`
- **AND** high-risk operation wording explicitly includes confirmation requirements for archive/rewrite style operations

### Requirement: Codex guardrail references SHALL resolve to an available managed source

Codex managed workflow policy SHALL reference a guardrails document path that is resolvable in Codex runtime environments.

#### Scenario: Guardrail path is resolvable

- **WHEN** maintainers inspect managed Codex AGENTS policy and rendered assets
- **THEN** guardrail references point to a managed path that exists in Codex runtime scope
- **AND** the policy does not rely on an unresolved `context/guardrails.md` reference

### Requirement: Codex diagnostics SHALL include OpenSpec wrapper readiness checks

Codex workflow diagnostics SHALL validate OpenSpec wrapper prompt readiness in addition to core prompt projection.

#### Scenario: Opsx wrapper readiness is reported

- **WHEN** operators run `codex-manage doctor`
- **THEN** diagnostics report whether required `opsx-*` wrappers are present
- **AND** report warnings when wrapper coverage is incomplete

### Requirement: Codex search routing SHALL prioritize Tavily MCP

Codex managed workflow policy and runtime configuration SHALL implement Tavily MCP as the primary search path, with built-in web search only as fallback when Tavily is unavailable.

#### Scenario: Tavily-first policy anchor is explicit in Codex workflow guidance

- **WHEN** maintainers inspect managed Codex AGENTS policy
- **THEN** policy explicitly states Tavily MCP is preferred for web/news/docs lookup
- **AND** fallback to built-in web search is explicitly conditional on Tavily unavailability/failure

#### Scenario: Tavily MCP runtime readiness is provisioned for Codex

- **WHEN** maintainers inspect rendered Codex config and diagnostics output
- **THEN** Codex runtime includes a configured `mcp_servers.tavily` entry
- **AND** diagnostics provide actionable status for Tavily MCP availability

### Requirement: Codex policy SHALL distinguish hard enforcement from instruction enforcement

Codex workflow policy SHALL explicitly distinguish available runtime mechanisms from policy-only constraints, and require explicit confirmation-first handling for high-risk operations.

#### Scenario: High-risk operation policy is explicit

- **WHEN** maintainers inspect managed Codex AGENTS policy
- **THEN** policy explicitly distinguishes hard-enforced constraints and instruction-enforced constraints
- **AND** policy states Codex runtime hook support is limited (for example notify-oriented behavior), not Claude-equivalent multi-event policy gating
- **AND** high-risk operations (for example archive/rewrite operations) require explicit confirmation by policy

### Requirement: Codex AGENTS opsx references SHALL use tool-native syntax

Codex AGENTS policy SHALL reference opsx commands using hyphen form (`/opsx-*`) matching actual Codex prompt file naming, with a single cross-tool disambiguation note for Claude colon form.

#### Scenario: Opsx syntax is consistent in Codex AGENTS

- **WHEN** maintainers inspect managed Codex AGENTS policy
- **THEN** all opsx command references use hyphen form (`/opsx-new`, `/opsx-ff`, `/opsx-apply`, `/opsx-verify`, `/opsx-archive`)
- **AND** a single disambiguation note explains that Claude Code uses colon form (`/opsx:*`)
- **AND** no mixed colon-form references appear outside the disambiguation note
