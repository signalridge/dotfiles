# opencode-no-claude-compat Specification

## Purpose

Define strict no-Claude compatibility guardrails for managed OpenCode configuration while preserving an explicit opt-in compat mode.

## Requirements

### Requirement: Strict mode SHALL disable Claude compatibility ingestion toggles

Managed `oh-my-opencode.jsonc` SHALL disable Claude compatibility ingestion toggles when compatibility mode is unset or set to `strict`.

#### Scenario: Strict mode toggles are disabled

- **WHEN** maintainers render `private_dot_config/opencode/oh-my-opencode.jsonc.tmpl` with strict/default mode
- **THEN** `claude_code.commands`, `claude_code.skills`, `claude_code.agents`, `claude_code.hooks`, and `claude_code.plugins` are `false`

### Requirement: Strict mode SHALL disable Claude hook bridge

Managed hook policy SHALL disable Claude bridge hooks in strict/default mode.

#### Scenario: Claude bridge hook is blocked in strict mode

- **WHEN** maintainers inspect strict/default rendered `disabled_hooks`
- **THEN** `claude-code-hooks` is present

### Requirement: Strict mode SHALL keep Sisyphus compatibility native-only

Strict/default mode SHALL keep Sisyphus Claude compatibility disabled.

#### Scenario: Native-only task compatibility in strict mode

- **WHEN** maintainers inspect strict/default rendered `sisyphus.tasks`
- **THEN** `claude_code_compat` is `false`

### Requirement: Compat mode SHALL remain explicit and intentional

When explicitly enabled, compat mode SHALL intentionally enable Claude compatibility ingress controls.

#### Scenario: Compat mode enables compatibility ingress

- **WHEN** maintainers render with `opencodeCompatibilityMode = "compat"`
- **THEN** `claude_code.commands`, `claude_code.skills`, `claude_code.agents`, `claude_code.hooks`, and `claude_code.plugins` are `true`
- **AND** `claude-code-hooks` is not forcibly disabled
- **AND** `sisyphus.tasks.claude_code_compat` is `true`

### Requirement: No-Claude policy SHALL be configuration-driven, not wrapper-driven

Strict no-Claude policy SHALL remain effective through managed configuration alone and SHALL NOT depend on repository-specific OpenCode launcher wrappers.

#### Scenario: No-wrapper architecture still preserves no-Claude defaults

- **WHEN** maintainers inspect current repository workflow assets
- **THEN** no OpenCode wrapper launcher scripts are required for strict no-Claude defaults
- **AND** strict-mode no-Claude behavior remains encoded in managed `oh-my-opencode` template fields

### Requirement: No-Claude policy scope SHALL remain explicit and auditable

Managed docs/templates SHALL explicitly distinguish blocked Claude compatibility ingress paths from upstream OpenCode project instruction fallback behavior.

#### Scenario: Operators understand no-Claude boundaries

- **WHEN** operators review managed OpenCode AGENTS policy
- **THEN** they can identify strict/compat boundary behavior
- **AND** they can identify `AGENTS.md` as the authoritative managed instruction convention
