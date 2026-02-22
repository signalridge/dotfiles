## MODIFIED Requirements

### Requirement: oh-my-opencode SHALL use a curated advanced orchestration profile

The system SHALL render `~/.config/opencode/oh-my-opencode.jsonc` with explicit high-value orchestration controls that match effective runtime behavior, without stale disabled-agent planner residue.

#### Scenario: Effective disabled-agent profile is explicit and non-contradictory

- **WHEN** maintainers inspect rendered oh-my-opencode configuration
- **THEN** `sisyphus_agent.disabled=true` remains explicit
- **AND** stale planner routing toggles (`planner_enabled`, `replace_plan`, `default_builder_enabled`) that imply active Sisyphus planning behavior are absent
- **AND** `sisyphus.tasks` remains explicit for compatibility boundary control

Note: This modifies the main spec scenario that previously required `planner_enabled` and `replace_plan` to be explicit. With `sisyphus_agent.disabled=true`, upstream behavior treats these toggles as runtime-inactive; removing them is a clarity/auditability decision and SHALL be reflected in both config and main spec expectation.

#### Scenario: Core orchestration controls stay explicit

- **WHEN** maintainers inspect rendered oh-my-opencode configuration
- **THEN** `background_task` concurrency/timeouts remain explicitly configured
- **AND** category mappings remain explicitly configured for managed categories

### Requirement: OpenCode spec-verify command SHALL use correct CLI syntax

The managed `spec-verify` command template SHALL use correct `openspec validate` positional argument syntax for single-change verification.

#### Scenario: spec-verify validates a single change correctly

- **WHEN** maintainers inspect `spec-verify` command template in `opencode.jsonc`
- **THEN** the template uses `openspec validate <change-name>` (positional argument)
- **AND** does not use `--changes <change-name>` (which is a flag for validating all changes)

### Requirement: oh-my-opencode search configuration SHALL align with Tavily-first governance

Managed oh-my-opencode configuration SHALL not silently contradict Tavily-first search policy and SHALL explicitly describe non-Tavily fallback behavior.

#### Scenario: Tavily-versus-Exa precedence is explicit in managed OpenCode config posture

- **WHEN** maintainers inspect rendered OpenCode and oh-my-opencode configuration plus policy text
- **THEN** the precedence between Tavily MCP and Exa-oriented websearch is explicitly documented
- **AND** fallback behavior is deterministic when Tavily MCP is unavailable

### Requirement: oh-my-opencode subagent model routing SHALL be explicit for research/exploration agents

Managed oh-my-opencode profile SHALL explicitly set model-routing stance for `librarian`, `explore`, and `oracle` so runtime does not silently depend on upstream default provider chains.

#### Scenario: Research/exploration subagent route stance is explicit

- **WHEN** maintainers inspect rendered oh-my-opencode configuration
- **THEN** `agents.librarian`, `agents.explore`, and `agents.oracle` model routes are explicitly configured
- **OR** an explicit managed exception states intentional use of upstream defaults
- **AND** unintentional fallback to upstream default GLM route is prevented by policy assertions
