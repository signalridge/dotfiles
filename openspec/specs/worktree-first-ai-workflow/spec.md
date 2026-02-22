# worktree-first-ai-workflow Specification

## Purpose

Define repository-level worktree standards, shell helpers, policy anchors, and verification requirements for L2+ development workflow.

## Requirements

### Requirement: Repository SHALL standardize a project-local worktree directory

The repository SHALL use `.worktrees/` as the canonical project-local worktree directory and SHALL ensure it is ignored by git.

#### Scenario: Worktree directory convention is explicit

- **WHEN** maintainers inspect repository ignore rules
- **THEN** `.gitignore` includes `.worktrees/`
- **AND** `git check-ignore .worktrees` succeeds in the repository

### Requirement: Shell workflow SHALL provide first-party worktree lifecycle helpers

The repository shell helpers SHALL provide a minimal command set to create, navigate, list, remove, and prune worktrees.

#### Scenario: Worktree helper commands are available

- **WHEN** maintainers inspect managed shell functions
- **THEN** `wt-new`, `wt-go`, `wt-ls`, `wt-rm`, and `wt-prune` are defined
- **AND** `wt-rm` requires explicit user confirmation unless force mode is requested

#### Scenario: `wt-new` blocks nested creation from linked worktrees

- **WHEN** operator runs `wt-new <branch>` from a linked worktree instead of the primary workspace
- **THEN** command exits with a descriptive error instructing operator to run from primary workspace
- **AND** no nested `.worktrees/` path is created under the linked worktree directory

### Requirement: Worktree helpers SHALL handle target path collisions safely

Worktree helper commands SHALL fail safely when requested target paths already exist but are not valid worktrees for the current repository.

#### Scenario: `wt-new` detects non-worktree path collision

- **WHEN** operator runs `wt-new <branch>` and `.worktrees/<branch>` already exists as a non-worktree path
- **THEN** command exits with a descriptive error
- **AND** existing path contents are not modified or removed implicitly

### Requirement: Shell prompt SHALL expose worktree context when inside dedicated worktree paths

The repository prompt configuration SHALL display a concise worktree indicator when current directory is under `.worktrees/*`, and SHALL remain quiet outside dedicated worktree paths.

#### Scenario: Worktree indicator is visible in dedicated worktree paths

- **WHEN** operators run interactive shells inside `.worktrees/<branch>` directories
- **THEN** prompt includes a stable worktree marker (for example `[wt:<branch>]`)

#### Scenario: Prompt remains clean outside worktree paths

- **WHEN** operators run interactive shells in main workspace or non-worktree directories
- **THEN** no worktree marker is rendered

#### Scenario: Prompt degrades safely for non-standard worktree locations

- **WHEN** operators run inside git worktrees that are not under `.worktrees/*`
- **THEN** prompt rendering remains successful without errors
- **AND** indicator may be omitted by design

### Requirement: Worktree workflow SHALL remain decoupled from account doctor responsibilities

Worktree baseline behavior SHALL not require extending account-management doctor commands.

#### Scenario: Manage doctor scope remains account/config focused

- **WHEN** maintainers inspect `claude-manage` and `codex-manage` doctor implementations
- **THEN** account/config diagnostics remain intact
- **AND** worktree workflow does not depend on doctor-specific checks to be usable

### Requirement: AGENTS policies SHALL define a Worktree Gate for L2+ work

Managed Claude/Codex/OpenCode policy templates SHALL include an explicit `Worktree Gate (L2+)` section.

#### Scenario: Cross-tool worktree gate is explicit

- **WHEN** maintainers inspect AGENTS templates for Claude/Codex/OpenCode
- **THEN** each template contains `Worktree Gate (L2+)`
- **AND** guidance states one-task-one-branch-one-worktree for L2+ work
- **AND** guidance includes a default path recommendation under `.worktrees/`

### Requirement: Tests SHALL enforce worktree workflow policy anchors

Repository tests SHALL assert worktree workflow anchors across templates and scripts.

#### Scenario: Worktree policy anchors are regression-tested

- **WHEN** maintainers run shell test suite
- **THEN** tests assert `.worktrees/` ignore rule presence
- **AND** tests assert AGENTS templates include worktree-related anchors

### Requirement: Worktree machine-checkable anchors SHALL remain explicit

Worktree workflow requirements SHALL include stable text anchors so automated tests can detect behavioral drift.

#### Scenario: Anchor set is complete

- **WHEN** maintainers inspect design/testing artifacts for this change
- **THEN** anchor set includes `.worktrees/`, `Worktree Gate (L2+)`, and `wt-new` signature checks
- **AND** shared command projection anchors are included for cross-tool command consistency
