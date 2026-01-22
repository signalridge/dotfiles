# /pr-ready - Verify PR Readiness

Check if a pull request is ready for review or merge.

## Usage

```
/pr-ready [pr-number]
/pr-ready --self
/pr-ready --fix
```

## Arguments

- `pr-number`: PR to check (default: current branch's PR)
- `--self`: Check PR for current branch
- `--fix`: Attempt to fix issues automatically

## Readiness Checklist

### Code Quality

- [ ] All tests pass
- [ ] No linting errors
- [ ] No type errors
- [ ] Code coverage maintained
- [ ] No security vulnerabilities

### Git Status

- [ ] Branch up to date with base
- [ ] No merge conflicts
- [ ] Commits are clean (no fixup/wip)
- [ ] Commit messages follow convention

### PR Requirements

- [ ] Title follows convention
- [ ] Description is complete
- [ ] Linked to issue (if applicable)
- [ ] Labels added
- [ ] Reviewers assigned

### Documentation

- [ ] README updated (if needed)
- [ ] API docs updated (if changed)
- [ ] Changelog entry added

## Workflow

### Step 1: Fetch PR Status

```bash
# Get PR details
gh pr view 123 --json state,title,body,labels,reviews,statusCheckRollup

# Get check status
gh pr checks 123
```

### Step 2: Verify CI Status

```bash
# List all checks
gh pr checks 123 --json name,status,conclusion

# Wait for checks (if running)
gh pr checks 123 --watch
```

Status interpretation:

- `success` - Check passed
- `failure` - Check failed
- `pending` - Still running
- `skipped` - Not applicable

### Step 3: Check for Conflicts

```bash
# Check mergeable status
gh pr view 123 --json mergeable,mergeStateStatus

# If conflicts exist
git fetch origin main
git merge origin/main --no-commit
# Resolve conflicts, then commit
```

### Step 4: Verify Branch Status

```bash
# Check if behind base
git fetch origin
git rev-list --count HEAD..origin/main

# Rebase if needed
git rebase origin/main
git push --force-with-lease
```

### Step 5: Review Commits

```bash
# List commits
gh pr view 123 --json commits

# Check for WIP/fixup commits
git log origin/main..HEAD --oneline | grep -i "wip\|fixup\|squash"
```

### Step 6: Validate PR Metadata

Check:

- Title format: `type(scope): description`
- Description has all sections
- Issue linked: `Closes #123` or `Fixes #456`
- Appropriate labels

## Output

```markdown
## PR Readiness Report: #123

### Summary

Status: ⚠️ **Almost Ready** (3 issues)

### Checks

| Check    | Status          |
| -------- | --------------- |
| Tests    | ✅ Pass         |
| Lint     | ✅ Pass         |
| Types    | ✅ Pass         |
| Coverage | ⚠️ Decreased 2% |
| Security | ✅ Pass         |

### Git Status

| Item          | Status                     |
| ------------- | -------------------------- |
| Conflicts     | ✅ None                    |
| Behind base   | ⚠️ 3 commits               |
| Clean history | ❌ Contains "fixup" commit |

### PR Metadata

| Item         | Status                  |
| ------------ | ----------------------- |
| Title format | ✅ Valid                |
| Description  | ✅ Complete             |
| Issue linked | ✅ #456                 |
| Labels       | ⚠️ Missing "type" label |
| Reviewers    | ✅ 2 assigned           |

### Required Actions

1. ❌ Squash fixup commits: `git rebase -i origin/main`
2. ⚠️ Rebase on main: `git rebase origin/main`
3. ⚠️ Add label: `gh pr edit 123 --add-label "type:feature"`

### Optional Improvements

- Consider adding more test coverage
- Update changelog entry
```

## Auto-fix Mode

With `--fix`, automatically:

```bash
# Rebase on main
git fetch origin && git rebase origin/main

# Squash fixup commits
git rebase -i --autosquash origin/main

# Add missing labels
gh pr edit 123 --add-label "type:feature"

# Push updates
git push --force-with-lease
```

## Related Commands

- `/pr-create` - Create new PR
- `/pr-update` - Update PR description
- `/pr-review` - Review PR
