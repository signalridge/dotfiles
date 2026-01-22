# /command-cheatsheet - Command Reference

Display available commands with descriptions and usage examples.

## Usage

```
/command-cheatsheet
/command-cheatsheet <keyword>
/command-cheatsheet --category <name>
/command-cheatsheet --update
```

## Arguments

- `keyword`: Search commands by keyword
- `--category <name>`: Filter by category (git, plan, pr, doc, etc.)
- `--update`: Regenerate cheatsheet from command files
- `--json`: Output as JSON

## Categories

### Git & Branch Management

| Command             | Description                    |
| ------------------- | ------------------------------ |
| `/branch-create`    | Create branch with auto-naming |
| `/commit`           | Context-aware commit           |
| `/commit-stage`     | Stage changes in logical units |
| `/conflict-resolve` | Resolve merge conflicts        |

### Planning & Workflow

| Command         | Description                   |
| --------------- | ----------------------------- |
| `/plan`         | Quick implementation planning |
| `/plan-create`  | Create detailed plan          |
| `/plan-import`  | Import external plan          |
| `/plan-refine`  | Improve existing plan         |
| `/plan-split`   | Break large plan into parts   |
| `/handoff`      | Session continuity            |
| `/context-save` | Save session context          |

### Worktrees

| Command            | Description              |
| ------------------ | ------------------------ |
| `/worktree`        | Worktree overview        |
| `/worktree-list`   | List all worktrees       |
| `/worktree-merge`  | Merge worktree branch    |
| `/worktree-open`   | Open worktree in editor  |
| `/worktree-remove` | Remove worktree          |
| `/worktree-clean`  | Clean up stale worktrees |

### Pull Requests

| Command       | Description         |
| ------------- | ------------------- |
| `/pr-create`  | Create pull request |
| `/pr-review`  | Review pull request |
| `/pr-comment` | Add PR comment      |
| `/pr-ready`   | Check PR readiness  |
| `/pr-update`  | Update PR metadata  |

### Code Quality

| Command          | Description           |
| ---------------- | --------------------- |
| `/review`        | Code review checklist |
| `/debug`         | Systematic debugging  |
| `/test`          | Test workflow         |
| `/refactor`      | Safe refactoring      |
| `/security-scan` | Security analysis     |
| `/tdd-cycle`     | TDD workflow          |

### Documentation

| Command            | Description                  |
| ------------------ | ---------------------------- |
| `/doc-generate`    | Generate documentation       |
| `/doc-compact`     | Reduce doc redundancy        |
| `/doc-update`      | Update docs for code changes |
| `/feedback-create` | Create feedback summary      |

### Dependencies & Setup

| Command     | Description           |
| ----------- | --------------------- |
| `/deps`     | Dependency management |
| `/scaffold` | Project scaffolding   |
| `/context`  | Codebase analysis     |

### Meta Commands

| Command               | Description                 |
| --------------------- | --------------------------- |
| `/command-cheatsheet` | This reference              |
| `/command-create`     | Create new command          |
| `/command-suggest`    | Get command suggestions     |
| `/prompt-generate`    | Generate structured prompts |

## Quick Reference

### Most Used

```
/commit          - Commit with good message
/pr-create       - Create PR
/debug           - Fix issues systematically
/plan-create     - Plan before coding
```

### Workflow Sequence

```
/plan-create     → Plan the work
/branch-create   → Create feature branch
[code]           → Write code
/commit-stage    → Stage changes
/commit          → Commit with message
/pr-create       → Create pull request
/pr-ready        → Verify PR is ready
```

### Debugging Flow

```
/debug           → ISOLATE → TRACE → VERIFY
/test            → Run tests
/security-scan   → Check security
/review          → Final review
```

## Search Examples

### Find git commands

```
/command-cheatsheet git
→ Shows: branch-create, commit, commit-stage, conflict-resolve, worktree-*
```

### Find planning commands

```
/command-cheatsheet --category plan
→ Shows: plan, plan-create, plan-import, plan-refine, plan-split
```

## Output Format

```markdown
## Commands Matching: "commit"

### /commit

**Category:** Git
**Description:** Create context-aware commit with conventional message
**Usage:** `/commit [--amend]`
**Example:** `/commit` → Analyzes changes and generates commit message

### /commit-stage

**Category:** Git
**Description:** Stage changes in logical units
**Usage:** `/commit-stage [files...] [--patch]`
**Example:** `/commit-stage src/*.py --patch`
```

## Related Commands

- `/command-create` - Create new command
- `/command-suggest` - Get suggestions based on context
