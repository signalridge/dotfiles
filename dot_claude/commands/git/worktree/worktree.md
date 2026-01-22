# /worktree - Git Worktree Management

Manage multiple working directories for parallel development.

## What are Worktrees?

Git worktrees let you have multiple branches checked out simultaneously in different directories. Useful for:

- Working on a feature while reviewing a PR
- Hotfix on main while feature branch is in progress
- Comparing implementations side by side

## Commands

### List Worktrees

```bash
git worktree list
```

### Create Worktree

#### For existing branch

```bash
git worktree add ../project-branch-name branch-name
```

#### For new branch

```bash
git worktree add -b new-feature ../project-new-feature main
```

#### Recommended structure

```
~/Projects/
├── myproject/           # Main worktree (default)
├── myproject-feature/   # Feature branch worktree
├── myproject-hotfix/    # Hotfix worktree
└── myproject-review/    # PR review worktree
```

### Remove Worktree

```bash
# Remove the directory and prune
git worktree remove ../project-branch-name

# Or manually delete and prune
rm -rf ../project-branch-name
git worktree prune
```

### Move Worktree

```bash
git worktree move ../old-path ../new-path
```

## Workflows

### PR Review Workflow

```bash
# Create worktree for PR review
git fetch origin pull/123/head:pr-123
git worktree add ../myproject-pr-123 pr-123

# Review in new directory
cd ../myproject-pr-123
# ... run tests, review code ...

# Cleanup when done
cd ../myproject
git worktree remove ../myproject-pr-123
git branch -D pr-123
```

### Hotfix While Feature in Progress

```bash
# You're working on feature branch in main worktree
# Urgent hotfix needed

# Create hotfix worktree from main
git worktree add -b hotfix/urgent ../myproject-hotfix main

# Fix, commit, push in hotfix worktree
cd ../myproject-hotfix
# ... make fix ...
git commit -am "fix: urgent issue"
git push -u origin hotfix/urgent

# Return to feature work
cd ../myproject
# Feature branch still intact
```

### Comparison Workflow

```bash
# Compare two implementations
git worktree add ../myproject-v1 v1.0.0
git worktree add ../myproject-v2 v2.0.0

# Now you can diff, run tests, compare behavior
diff ../myproject-v1/src ../myproject-v2/src
```

## Best Practices

1. **Naming convention**: `project-branchname` or `project-purpose`
2. **Keep worktrees near main repo**: Makes relative paths predictable
3. **Clean up promptly**: Remove worktrees when done
4. **Don't commit from wrong worktree**: Check `git branch` before committing
5. **Shared objects**: All worktrees share the same `.git` objects (space efficient)

## Limitations

- Can't have same branch in multiple worktrees
- Each worktree needs its own `node_modules`, `.venv`, etc.
- IDE settings may need adjustment per worktree
