## ADDED Requirements

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
