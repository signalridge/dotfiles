# codex-config-enhancements Specification

## Purpose

TBD - created by archiving change codex-claude-align. Update Purpose after archive.

## Requirements

### Requirement: Codex enhanced feature flags

The system SHALL enable the following Codex feature flags: `apply_patch_freeform`, `include_apply_patch_tool`, `unified_exec`, `shell_snapshot`, `runtime_metrics`, `undo`, `request_rule`, `responses_websockets`, `remote_compaction`, `remote_models`, `skill_mcp_dependency_install`, `skill_env_var_dependency_prompt`, `web_search`, `web_search_cached`, `web_search_request`, `shell_tool`, `memory_tool`.

#### Scenario: Features are enabled in config

- **WHEN** Codex config is rendered
- **THEN** `[features]` contains the listed keys set to `true`

### Requirement: Codex tools enabled

The system SHALL enable `tools.view_image` and `tools.web_search`.

#### Scenario: Tool toggles are enabled

- **WHEN** Codex config is rendered
- **THEN** `tools.view_image = true` and `tools.web_search = true`

### Requirement: High-capability defaults and environment policy

The system SHALL set `approval_policy = "never"`, `sandbox_mode = "danger-full-access"`, `network_access = "enabled"`, `web_search = "live"`, `suppress_unstable_features_warning = true`, and `shell_environment_policy.inherit = "all"` with `ignore_default_excludes = true` and an empty `exclude` list.

#### Scenario: High-capability defaults configured

- **WHEN** Codex config is rendered
- **THEN** the listed defaults and shell environment policy values are present
