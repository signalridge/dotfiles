## ADDED Requirements

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
