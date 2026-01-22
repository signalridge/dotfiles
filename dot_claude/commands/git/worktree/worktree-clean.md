# /worktree-clean - Clean Up Worktrees

Remove stale, merged, or abandoned worktrees.

## Usage

```
/worktree-clean
/worktree-clean --merged
/worktree-clean --stale
/worktree-clean --all
```

## Arguments

- `--merged`: Remove worktrees with merged branches
- `--stale`: Remove worktrees with deleted remote branches
- `--all`: Remove all non-main worktrees
- `--dry-run`: Preview without executing
- `--interactive, -i`: Confirm each removal

## Workflow

### Step 1: Scan Worktrees

```bash
# List all worktrees
git worktree list

# Check for stale worktrees
git worktree prune --dry-run
```

### Step 2: Categorize

| Category      | Description                  | Action             |
| ------------- | ---------------------------- | ------------------ |
| **Main**      | Primary working directory    | Never remove       |
| **Active**    | Has recent commits, unmerged | Keep               |
| **Merged**    | Branch fully merged          | Safe to remove     |
| **Stale**     | Remote branch deleted        | Safe to remove     |
| **Abandoned** | No commits in 30+ days       | Prompt to remove   |
| **Dirty**     | Has uncommitted changes      | Warn before remove |

### Step 3: Generate Report

```markdown
## Worktree Status Report

### Keep (Active)

- /project-worktrees/feature-xyz [feature/xyz]
  - Last commit: 2 days ago
  - Status: 3 commits ahead of main

### Safe to Remove (Merged)

- /project-worktrees/feature-auth [feature/auth]
  - Merged to main on 2024-01-15
  - PR #123 closed

- /project-worktrees/fix-login [fix/login]
  - Merged to main on 2024-01-14
  - PR #120 closed

### Safe to Remove (Stale)

- /project-worktrees/pr-99 [pr-99]
  - Remote branch deleted
  - PR #99 closed

### Warning (Dirty)

- /project-worktrees/experiment [experiment]
  - Has uncommitted changes
  - 5 modified files
```

### Step 4: Execute Cleanup

```bash
# Prune git worktree metadata
git worktree prune

# Remove merged worktrees
for worktree in $merged_worktrees; do
  git worktree remove "$worktree"
  git branch -d "$(basename $worktree)"
done

# Remove stale worktrees
for worktree in $stale_worktrees; do
  git worktree remove "$worktree"
  git branch -D "$(basename $worktree)"
done
```

### Step 5: Summary

```markdown
## Cleanup Complete

### Removed

- [x] feature/auth (merged)
- [x] fix/login (merged)
- [x] pr-99 (stale)

### Skipped

- experiment (has uncommitted changes)

### Remaining Worktrees

1. /project [main]
2. /project-worktrees/feature-xyz [feature/xyz]
3. /project-worktrees/experiment [experiment]

### Space Recovered

- Directories removed: 3
- Estimated space: ~150 MB
```

## Automatic Cleanup Rules

Configure cleanup thresholds:

```markdown
## Cleanup Policy

### Auto-remove

- Branches merged > 7 days ago
- Remote branch deleted > 1 day ago
- PR closed/merged

### Prompt for removal

- No commits in 30+ days
- Has uncommitted changes
- Branch not merged

### Never auto-remove

- Main worktree
- Branches with open PRs
- Marked as "keep" (.worktree-keep file)
```

## Protecting Worktrees

To prevent accidental removal:

```bash
# Create marker file in worktree
touch /path/to/worktree/.worktree-keep
```

## Related Commands

- `/worktree-list` - View all worktrees
- `/worktree-remove` - Remove specific worktree
- `/worktree-merge` - Merge before cleanup
