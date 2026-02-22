# shared-ai-commands Specification

## Purpose

TBD - created by archiving change codex-claude-align. Update Purpose after archive.

## Requirements

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

### Requirement: Shared command source SHALL include cross-tool worktree workflow guidance

The shared command source-of-truth SHALL include a managed worktree workflow command document, so Claude/Codex/OpenCode consume consistent operator guidance.

#### Scenario: Shared worktree command document exists

- **WHEN** maintainers inspect `dot_agents/commands/core`
- **THEN** a worktree command document exists in the shared command set
- **AND** command content describes list/diagnose/navigate workflow without claiming unsupported direct shell CWD switching

### Requirement: Command delta scope SHALL stay projection-focused

This capability delta SHALL focus on cross-tool command consistency only, and SHALL NOT redefine repository-level shell/tool baseline requirements that belong to `worktree-first-ai-workflow`.

#### Scenario: Responsibility boundary is explicit

- **WHEN** maintainers review this delta spec and companion worktree baseline spec
- **THEN** shared-ai-commands requirements are limited to command source/projection consistency
- **AND** shell helper and tool-integration baseline behavior remains defined in the worktree baseline capability

### Requirement: Worktree command guidance SHALL be projected consistently across tool surfaces

The managed worktree command guidance SHALL be discoverable through existing command projection paths for Claude/Codex/OpenCode.

#### Scenario: Command projection includes worktree guidance

- **WHEN** maintainers inspect tool-specific command projection templates and rendered paths
- **THEN** Claude/Codex/OpenCode command surfaces all expose the shared worktree guidance
- **AND** behavior and wording remain consistent across tool surfaces

#### Scenario: Projection anchors are machine-checkable

- **WHEN** maintainers run repository tests
- **THEN** tests assert presence of shared worktree command anchors in projected command surfaces for supported tools
- **AND** failures identify missing projection path or content drift

### Requirement: Cross-tool command guidance SHALL avoid OpenCode-only behavior drift

Worktree command semantics SHALL not depend on OpenCode-only custom commands when equivalent shared command paths exist.

#### Scenario: Shared guidance avoids OpenCode-only switch semantics

- **WHEN** maintainers inspect managed OpenCode command templates and shared command docs
- **THEN** no OpenCode-only `wt-switch` style command is required to fulfill baseline workflow
- **AND** shared guidance uses shell-level `wt-*` commands as canonical execution path
