## ADDED Requirements

### Requirement: Canonical gopass namespace SHALL be tool-scoped

The system SHALL store and retrieve AI tool API keys using a canonical namespace derived from runtime tool context (`claude`, `codex`, `opencode`).

#### Scenario: Claude namespace selection

- **WHEN** helpers run with `AI_TOOL_CONTEXT=claude`
- **THEN** key paths use prefix `claude`

#### Scenario: Codex namespace selection

- **WHEN** helpers run with `AI_TOOL_CONTEXT=codex`
- **THEN** key paths use prefix `codex`

#### Scenario: OpenCode namespace selection

- **WHEN** helpers run with `AI_TOOL_CONTEXT=opencode`
- **THEN** key paths use prefix `opencode`

### Requirement: Canonical key path format

The system SHALL store keys at `<prefix>/providers/<provider>/accounts/<encoded_account>/api_key` where `<encoded_account>` is a stable, path-safe encoding of the account name.

#### Scenario: Path generation for account

- **WHEN** a key is stored for provider `deepseek` and account `work`
- **THEN** the key path is `<prefix>/providers/deepseek/accounts/<encoded_account>/api_key`

### Requirement: Tool context and path validation

The system SHALL reject unsupported tool context values and invalid path segments that could lead to malformed gopass paths.

#### Scenario: Unsupported tool context rejected

- **WHEN** `AI_TOOL_CONTEXT` is not one of `claude`, `codex`, `opencode`
- **THEN** key operations fail with a clear error

#### Scenario: Invalid account rejected

- **WHEN** a provider or account segment is invalid
- **THEN** key operations fail with a clear error

### Requirement: Runtime key access SHALL use canonical path helpers only

The system SHALL use canonical path helpers for key read/write/delete/list operations without runtime fallback to legacy path layouts.

#### Scenario: Canonical-only read behavior

- **WHEN** runtime resolves keys for a provider/account
- **THEN** it reads canonical path candidates only

### Requirement: Migration guidance SHALL match current project workflow

The system SHALL document manual migration through managed account commands (`*-manage add-key`) and key presence checks (`*-token --check`).

#### Scenario: Manual migration path is documented

- **WHEN** operators follow provider docs
- **THEN** they can move keys from legacy entries to canonical namespace without a dedicated migration binary
