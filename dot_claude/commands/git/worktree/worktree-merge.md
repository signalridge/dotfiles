# /worktree-merge - Merge Worktree Branch

Safely merge a worktree branch with comprehensive checks.

## Usage

```
/worktree-merge <worktree>
/worktree-merge <worktree> --strategy <merge|squash|ff>
/worktree-merge <worktree> --no-delete
```

## Arguments

- `worktree`: Worktree name or path
- `--strategy`: Merge strategy (default: squash)
- `--no-delete`: Keep worktree after merge
- `--dry-run`: Preview without executing

## Merge Strategies

| Strategy   | Command               | When to Use           |
| ---------- | --------------------- | --------------------- |
| **merge**  | `git merge`           | Preserve full history |
| **squash** | `git merge --squash`  | Clean single commit   |
| **ff**     | `git merge --ff-only` | Linear history only   |

## Workflow

### Step 1: Pre-merge Checks

```bash
# In target worktree
cd /path/to/worktree

# Check for uncommitted changes
git status

# Check remote sync
git fetch origin
git status -sb  # Shows ahead/behind
```

Safety checks:

- [ ] No uncommitted changes in worktree
- [ ] No uncommitted changes in main repo
- [ ] Branch is up to date with remote
- [ ] No merge conflicts expected

### Step 2: Verify Merge Target

```bash
# Identify upstream/target branch
git rev-parse --abbrev-ref --symbolic-full-name @{u}

# Or determine from branch name
# feature/xyz → main
# hotfix/abc → main
# pr-123 → main
```

### Step 3: Check for Conflicts

```bash
# Preview merge
git merge-tree $(git merge-base main feature) main feature

# Or dry-run merge
git merge --no-commit --no-ff feature
git merge --abort  # If just checking
```

### Step 4: Execute Merge

#### Squash Merge (Recommended)

```bash
cd /path/to/main-repo
git merge --squash worktree-branch
git commit -m "feat: description of changes"
```

#### Regular Merge

```bash
git merge worktree-branch -m "Merge feature/xyz"
```

#### Fast-Forward Only

```bash
git merge --ff-only worktree-branch
```

### Step 5: Post-merge Actions

```bash
# Push to remote
git push origin main

# Close PR if applicable
gh pr close 123 --comment "Merged via worktree"

# Delete remote branch
git push origin --delete feature/xyz
```

### Step 6: Cleanup Worktree

```bash
# Remove worktree
git worktree remove /path/to/worktree

# Delete local branch
git branch -d feature/xyz

# Prune worktree references
git worktree prune
```

## Output

```markdown
## Merge Summary

### Pre-merge Checks

- [x] No uncommitted changes
- [x] Synced with remote
- [x] No conflicts detected

### Merge Details

- Source: feature/add-auth (def5678)
- Target: main (abc1234)
- Strategy: squash
- Commits merged: 5

### Post-merge Actions

- [x] Pushed to origin/main
- [x] Closed PR #123
- [x] Deleted remote branch
- [x] Removed worktree
- [x] Deleted local branch

### New HEAD

- Commit: xyz7890
- Message: "feat: add user authentication system"
```

## Handling Issues

### Uncommitted Changes

```bash
# Option 1: Commit them
git add . && git commit -m "wip: save work"

# Option 2: Stash them
git stash

# Option 3: Discard them (careful!)
git checkout -- .
```

### Merge Conflicts

```bash
# Abort and use conflict-resolve
git merge --abort
/conflict-resolve
```

### Behind Remote

```bash
# Update first
git pull --rebase origin main
# Then retry merge
```

## Related Commands

- `/worktree-list` - View all worktrees
- `/worktree-remove` - Remove without merging
- `/conflict-resolve` - Handle merge conflicts
