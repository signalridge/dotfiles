## ADDED Requirements

### Requirement: Shared command source exists

The system SHALL store canonical command content under `~/.agents/commands/core` for core commands: plan, review, commit, context, test, pr-review, pr-create.

#### Scenario: Shared command files rendered

- **WHEN** chezmoi applies templates
- **THEN** files exist at `~/.agents/commands/core/<name>.md` for each core command

### Requirement: Claude commands link to shared content

The system SHALL render `~/.claude/commands/core/*.md` as symlinks to the shared command content.

#### Scenario: Claude command content derives from shared source

- **WHEN** chezmoi applies templates
- **THEN** `~/.claude/commands/core/plan.md` is a symlink to `~/.agents/commands/core/plan.md`

### Requirement: Codex prompts link to shared content

The system SHALL render `~/.codex/prompts/<name>.md` for each shared command as a symlink to the shared content.

#### Scenario: Codex prompt exists

- **WHEN** chezmoi applies templates
- **THEN** `~/.codex/prompts/plan.md` exists and is a symlink to `~/.agents/commands/core/plan.md`
