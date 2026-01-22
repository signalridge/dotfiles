# /command-suggest - Suggest Commands

Get command suggestions based on current context or task description.

## Usage

```
/command-suggest
/command-suggest <task-description>
/command-suggest --context
```

## Arguments

- `task-description`: What you're trying to do
- `--context`: Analyze current state for suggestions
- `--all`: Show all available commands

## How It Works

### Context Analysis

Analyzes:

1. **Git state**: Branch, uncommitted changes, conflicts
2. **Recent files**: What you've been working on
3. **Error messages**: If debugging
4. **Project type**: Language, framework

### Task Matching

Maps tasks to commands:

| Task Keywords         | Suggested Commands                     |
| --------------------- | -------------------------------------- |
| "commit", "save"      | `/commit-stage`, `/commit`             |
| "review", "check"     | `/review`, `/pr-review`                |
| "fix", "bug", "error" | `/debug`, `/test`                      |
| "plan", "design"      | `/plan-create`, `/plan`                |
| "deploy", "release"   | `/pr-ready`, `/pr-create`              |
| "document", "docs"    | `/doc-generate`, `/doc-update`         |
| "branch", "feature"   | `/branch-create`, `/worktree`          |
| "merge", "conflict"   | `/conflict-resolve`, `/worktree-merge` |

## Examples

### From Context

```
/command-suggest --context

Current state:
- Branch: feature/add-auth
- Changes: 5 files modified, not staged
- Tests: Not run recently

Suggested commands:
1. /commit-stage - Stage your changes in logical units
2. /test - Run tests before committing
3. /commit - Commit with descriptive message
```

### From Description

```
/command-suggest "I need to fix a bug in the login flow"

Suggested workflow:
1. /debug - Systematic debugging (ISOLATE → TRACE → VERIFY)
2. /branch-create - Create fix branch
3. /test - Write test that exposes bug
4. /commit - Commit the fix
5. /pr-create - Create pull request
```

### For PR Workflow

```
/command-suggest "ready to submit my changes"

Suggested workflow:
1. /commit-stage - Ensure all changes staged
2. /commit - Final commit
3. /pr-ready - Check PR readiness
4. /pr-create - Create the PR
5. /pr-update - Update description if needed
```

## Context-Aware Suggestions

### When Conflicts Detected

```
⚠️ Merge conflicts detected in 3 files

Suggested:
→ /conflict-resolve - Resolve conflicts systematically
```

### When Tests Failing

```
⚠️ Recent test run had failures

Suggested:
→ /debug - Debug failing tests
→ /tdd-cycle - Use TDD to fix
```

### When PR Exists

```
ℹ️ Open PR #123 on current branch

Suggested:
→ /pr-ready - Check if ready for review
→ /pr-update - Update PR description
→ /pr-comment - Add context for reviewers
```

### When Starting New Work

```
ℹ️ On main branch with clean state

Suggested:
→ /plan-create - Plan your implementation
→ /branch-create - Create feature branch
```

## Output Format

```markdown
## Command Suggestions

### Based on: [Context / Your description]

### Primary Suggestion

**`/command-name`** - Description

> Best for: [Why this is recommended]

### Workflow

1. `/first-command` - Do this first
2. `/second-command` - Then this
3. `/third-command` - Finally this

### Alternative Commands

- `/alternative-1` - If you need X instead
- `/alternative-2` - For Y situation

### Tips

- [Relevant tip based on context]
```

## Learning

The suggestion system learns from:

- Commands you use frequently
- Patterns in your workflow
- Project-specific conventions

## Related Commands

- `/command-cheatsheet` - Full command reference
- `/command-create` - Create custom commands
