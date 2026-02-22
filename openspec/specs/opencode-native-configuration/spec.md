# opencode-native-configuration Specification

## Purpose

Define the managed OpenCode native configuration surface rendered by this repository, including deterministic provider/model selection and explicit operational policy controls.

## Requirements

### Requirement: OpenCode config SHALL use a curated native operational profile

The system SHALL render `~/.config/opencode/opencode.jsonc` from repository templates and include a curated set of native OpenCode operational features beyond baseline model/provider fields.

#### Scenario: Curated profile is rendered

- **WHEN** maintainers run `chezmoi apply`
- **THEN** rendered OpenCode config includes schema metadata and selected operational fields (for example `instructions`, `default_agent`, `watcher`, `compaction`)

### Requirement: Account-driven defaults SHALL remain deterministic

The system SHALL derive OpenCode default model selection from `opencodeProviderAccount` while keeping explicit third-party provider metadata.

#### Scenario: Account selector drives default models

- **WHEN** maintainers update `opencodeProviderAccount` and re-render templates
- **THEN** `model` and `small_model` consistently reflect the selected provider/account family

#### Scenario: Third-party providers expose key mapping explicitly

- **WHEN** maintainers inspect rendered provider blocks
- **THEN** managed third-party providers define explicit `env` and `options.baseURL`

### Requirement: Shared commands SHALL be available through OpenCode-native command paths

The system SHALL project repository shared commands into OpenCode-native command discovery paths.

#### Scenario: Command projection is present

- **WHEN** maintainers inspect managed OpenCode command paths
- **THEN** shared command markdown assets are available through OpenCode-native loading

#### Scenario: Command projection uses layered discovery topology

- **WHEN** maintainers inspect managed command projection topology
- **THEN** layered command tree discovery remains available in `~/.config/opencode/commands/`
- **AND** core command projection is symlinked to shared source-of-truth assets (`~/.agents/commands/core`)
- **AND** topology remains aligned with Claude-style directory symlink projection

### Requirement: Shared skills SHALL be available through managed OpenCode skill paths

The system SHALL ensure required shared skills are available through managed OpenCode skill paths, including strict runtime policy mode.

#### Scenario: Skills are available in strict mode

- **WHEN** OpenCode runs under strict external-skill isolation policy
- **THEN** required shared skills remain discoverable via managed OpenCode skill path wiring

#### Scenario: Skills projection handles nested skill trees deterministically

- **WHEN** maintainers inspect global and project skill wiring
- **THEN** global shared skills are available through managed OpenCode-native skills projection
- **AND** project-local `.agents/skills` discovery is configured with recursive traversal in oh-my skill source configuration

### Requirement: oh-my-opencode SHALL use a curated advanced orchestration profile

The system SHALL render `~/.config/opencode/oh-my-opencode.jsonc` with explicit high-value orchestration controls rather than relying on implicit defaults.

#### Scenario: Core orchestration controls are pinned

- **WHEN** maintainers inspect rendered oh-my-opencode configuration
- **THEN** `sisyphus_agent.disabled` is explicit
- **AND** stale planner routing toggles (`planner_enabled`, `replace_plan`, `default_builder_enabled`) are absent when `sisyphus_agent.disabled=true`
- **AND** `sisyphus.tasks` is explicit (`storage_path`, `claude_code_compat`)
- **AND** `background_task` concurrency/timeouts are explicitly configured
- **AND** category mappings are explicitly configured for built-in categories

### Requirement: oh-my-opencode operational controls SHALL remain explicit

The system SHALL keep operational controls explicit for browser automation, websearch, notifications, and tmux multi-agent execution.

#### Scenario: Operational controls are configured

- **WHEN** maintainers inspect rendered oh-my-opencode configuration
- **THEN** browser automation provider is explicit
- **AND** websearch provider is explicit
- **AND** notification force behavior is explicit
- **AND** tmux integration layout and pane constraints are explicit

### Requirement: oh-my-opencode disable controls SHALL be governance-driven

The system SHALL encode disable-control policy explicitly (required disables pinned, optional disables managed deliberately).

#### Scenario: Required disable controls are present

- **WHEN** maintainers inspect rendered oh-my-opencode configuration
- **THEN** required bridge-blocking disable controls are explicitly present
- **AND** selected `disabled_*` arrays are either explicitly configured or intentionally omitted by policy (not accidental)

### Requirement: Experimental behavior SHALL be explicit and deterministic

The system SHALL pin the approved `experimental` matrix in managed oh-my-opencode configuration.

#### Scenario: Approved experimental matrix is rendered

- **WHEN** maintainers inspect rendered oh-my-opencode configuration
- **THEN** `truncate_all_tool_outputs=false`
- **AND** `aggressive_truncation=false`
- **AND** `auto_resume=false`
- **AND** `preemptive_compaction=false`
- **AND** `dynamic_context_pruning.enabled=true`
- **AND** `dynamic_context_pruning.notification="detailed"`
- **AND** `dynamic_context_pruning.turn_protection.enabled=true`
- **AND** `dynamic_context_pruning.turn_protection.turns=4`
- **AND** `dynamic_context_pruning.strategies.deduplication.enabled=true`
- **AND** `dynamic_context_pruning.strategies.supersede_writes.enabled=true`
- **AND** `dynamic_context_pruning.strategies.supersede_writes.aggressive=false`
- **AND** `dynamic_context_pruning.strategies.purge_errors.enabled=true`
- **AND** `dynamic_context_pruning.strategies.purge_errors.turns=6`
- **AND** `task_system=true`
- **AND** `plugin_load_timeout_ms=15000`
- **AND** `safe_hook_creation=true`

### Requirement: Plugin chain SHALL remain deterministic

The system SHALL keep OpenCode plugin order explicit and stable.

#### Scenario: Plugin order is pinned

- **WHEN** maintainers inspect rendered plugin configuration
- **THEN** plugin sequence remains deterministic and orchestration-first

### Requirement: Sensitive permission defaults SHALL remain confirmation-first

The system SHALL explicitly set confirmation-first defaults for high-risk tool operations.

#### Scenario: Risky operations require confirmation

- **WHEN** maintainers inspect rendered permission configuration
- **THEN** high-risk operations (including `edit`, `bash`, `external_directory`) are explicitly gated with `ask`

### Requirement: OpenCode provider-family coverage SHALL remain aligned with repository account surface

Managed OpenCode provider definitions SHALL cover third-party provider families already supported by repository Claude/Codex workflow, with deterministic model/env/baseURL mapping.

#### Scenario: Cross-tool provider family parity exists

- **WHEN** maintainers inspect managed OpenCode provider definitions and account-driven model resolution
- **THEN** provider families used by repository Claude/Codex workflow (including `harui`) are representable in OpenCode config
- **AND** each mapped provider exposes deterministic env key and baseURL behavior

### Requirement: Managed oh-my websearch default SHALL remain startup-safe

Managed `oh-my-opencode` defaults SHALL avoid hard startup dependency on unscoped Tavily environment variables.

#### Scenario: Default provider does not require Tavily env

- **WHEN** maintainers render managed `oh-my-opencode` configuration without exporting `TAVILY_API_KEY`
- **THEN** default websearch provider remains configured to a startup-safe provider
- **AND** OpenCode startup is not blocked by missing Tavily environment variable

### Requirement: Tavily override policy SHALL remain explicit

When operators intentionally switch websearch provider to Tavily, managed docs and diagnostics SHALL make the key requirement explicit.

#### Scenario: Tavily override requirement is discoverable

- **WHEN** operators inspect managed docs or diagnostics
- **THEN** they can identify that Tavily mode requires `TAVILY_API_KEY` in runtime environment

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

### Requirement: Managed OpenCode oh-my profile SHALL support strict and compat modes

Managed configuration SHALL support an explicit compatibility mode selector while keeping strict mode as default.

#### Scenario: Strict mode renders isolation-first compatibility settings

- **WHEN** `opencodeCompatibilityMode` is unset or set to `strict`
- **THEN** Claude compatibility toggles remain disabled
- **AND** `claude-code-hooks` is disabled
- **AND** `sisyphus.tasks.claude_code_compat` is false

#### Scenario: Compat mode renders compatibility-ingress settings

- **WHEN** `opencodeCompatibilityMode` is set to `compat`
- **THEN** Claude compatibility toggles are enabled for commands/skills/agents/hooks/plugins
- **AND** `claude-code-hooks` is not disabled
- **AND** `sisyphus.tasks.claude_code_compat` is true

### Requirement: Managed OpenCode theme assets SHALL remain versioned

Repository-managed OpenCode themes SHALL be stored as configuration assets and rendered without requiring wrapper scripts.

#### Scenario: Theme asset is present and renderable

- **WHEN** maintainers inspect OpenCode template assets
- **THEN** at least one theme JSON file exists under `private_dot_config/opencode/themes/`
- **AND** theme files are valid JSON
