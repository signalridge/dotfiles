# /worktree-list - List Git Worktrees

Display all git worktrees with status information.

## Usage

```
/worktree-list
/worktree-list --verbose
/worktree-list --format json
```

## Arguments

- `--verbose, -v`: Show detailed status for each worktree
- `--format json`: Output as JSON for scripting

## Workflow

### Step 1: List Worktrees

```bash
git worktree list
```

Output format:

```
/path/to/main        abc1234 [main]
/path/to/feature     def5678 [feature/add-auth]
/path/to/pr-review   ghi9012 [pr-123]
```

### Step 2: Enhanced Information

For each worktree, show:

- **Path**: Absolute path to worktree
- **Branch**: Current branch name
- **Commit**: HEAD commit (short hash)
- **Status**: Clean, modified, or conflicts
- **Upstream**: Tracking branch status

### Verbose Output

```markdown
## Worktrees

### 1. /Users/you/project (main)

- Branch: main
- Commit: abc1234 "feat: add user auth"
- Status: Clean
- Upstream: origin/main (up to date)

### 2. /Users/you/project-worktrees/feature-auth

- Branch: feature/add-auth
- Commit: def5678 "wip: auth middleware"
- Status: 3 modified files
- Upstream: origin/feature/add-auth (2 ahead, 1 behind)

### 3. /Users/you/project-worktrees/pr-123

- Branch: pr-123
- Commit: ghi9012 "fix: login redirect"
- Status: Clean
- Upstream: origin/pull/123/head (PR review)
```

## Status Indicators

| Status    | Meaning                   |
| --------- | ------------------------- |
| Clean     | No uncommitted changes    |
| Modified  | Uncommitted changes exist |
| Untracked | New files not in git      |
| Conflicts | Merge conflicts present   |
| Detached  | HEAD is detached          |
| Stale     | Branch deleted on remote  |

## Quick Actions

Based on status, suggest actions:

```markdown
### Suggested Actions

- **feature-auth**: Has uncommitted changes
  → Run `/commit` or `git stash`

- **pr-123**: Ready for merge
  → Run `/worktree-merge pr-123`

- **old-feature**: Stale (remote branch deleted)
  → Run `/worktree-remove old-feature`
```

## JSON Output

```json
{
  "worktrees": [
    {
      "path": "/Users/you/project",
      "branch": "main",
      "commit": "abc1234",
      "status": "clean",
      "upstream": "origin/main",
      "ahead": 0,
      "behind": 0
    }
  ]
}
```

## Related Commands

- `/worktree-create` - Create new worktree
- `/worktree-merge` - Merge worktree branch
- `/worktree-remove` - Remove worktree
- `/worktree-clean` - Clean up stale worktrees
