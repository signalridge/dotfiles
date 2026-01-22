# /worktree-remove - Remove Git Worktree

Safely remove a git worktree and optionally its branch.

## Usage

```
/worktree-remove <worktree>
/worktree-remove <worktree> --force
/worktree-remove <worktree> --keep-branch
```

## Arguments

- `worktree`: Worktree name, branch, or path
- `--force, -f`: Remove even with uncommitted changes
- `--keep-branch`: Don't delete the branch
- `--dry-run`: Preview without executing

## Workflow

### Step 1: Pre-removal Checks

```bash
# Check worktree status
cd /path/to/worktree
git status
```

Verify:

- [ ] No uncommitted changes (or intentionally discarding)
- [ ] Branch merged (if applicable)
- [ ] No stashed changes
- [ ] Correct worktree selected

### Step 2: Check Branch Status

```bash
# Is branch merged?
git branch --merged main | grep "branch-name"

# Commits not in main
git log main..branch-name --oneline
```

If not merged, confirm intentional removal.

### Step 3: Remove Worktree

```bash
# Standard removal
git worktree remove /path/to/worktree

# Force removal (uncommitted changes)
git worktree remove --force /path/to/worktree
```

### Step 4: Clean Up Branch

```bash
# Delete local branch
git branch -d branch-name     # Safe delete (checks merge)
git branch -D branch-name     # Force delete

# Delete remote branch (if exists)
git push origin --delete branch-name
```

### Step 5: Prune References

```bash
# Clean up stale worktree metadata
git worktree prune

# Verify removal
git worktree list
```

## Safety Checks

### Uncommitted Changes Warning

```markdown
⚠️ Worktree has uncommitted changes:

Modified:

- src/api.py
- tests/test_api.py

Untracked:

- notes.txt

Options:

1. Commit changes first: /commit
2. Stash changes: git stash
3. Force remove (lose changes): /worktree-remove --force
```

### Unmerged Branch Warning

```markdown
⚠️ Branch has unmerged commits:

Commits not in main:

- abc1234 feat: add user endpoint
- def5678 fix: validation error

Options:

1. Merge first: /worktree-merge
2. Keep branch: /worktree-remove --keep-branch
3. Force delete: /worktree-remove --force
```

## Output

```markdown
## Worktree Removed

### Details

- Path: /Users/you/project-worktrees/feature-auth
- Branch: feature/add-auth
- Status: Clean

### Actions Taken

- [x] Worktree directory removed
- [x] Local branch deleted
- [x] Remote branch deleted
- [x] Worktree references pruned

### Remaining Worktrees

1. /Users/you/project [main]
2. /Users/you/project-worktrees/pr-456 [pr-456]
```

## Batch Removal

Remove multiple worktrees:

```bash
# Remove all PR review worktrees
for wt in $(git worktree list | grep "pr-" | awk '{print $1}'); do
  git worktree remove "$wt"
done
```

Or use `/worktree-clean` for automated cleanup.

## Related Commands

- `/worktree-list` - View all worktrees
- `/worktree-merge` - Merge before removing
- `/worktree-clean` - Clean up stale worktrees
