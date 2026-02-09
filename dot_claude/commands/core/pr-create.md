# /pr-create - Create Pull Request

Generate and create a well-structured pull request.

## Workflow

### Step 1: Gather Information

```bash
# Check current branch and status
git branch --show-current
git status

# Review all commits to be included
git log main..HEAD --oneline

# See full diff against base branch
git diff main...HEAD --stat
git diff main...HEAD
```

### Step 2: Analyze Changes

For each commit/change, identify:

- Type: feature, fix, refactor, docs, test, chore
- Scope: What component/module is affected
- Impact: What behavior changes

### Step 3: Generate PR Content

#### Title Format

```
type(scope): concise description
```

Examples:

- `feat(auth): add OAuth2 support for GitHub login`
- `fix(api): handle null response in user endpoint`
- `refactor(core): extract validation to separate module`

#### Body Template

```markdown
## Summary

Brief description of what this PR does and why.

## Changes

- [Change 1]
- [Change 2]

## Testing

- [ ] Unit tests added/updated
- [ ] Manual testing performed
- [ ] Edge cases considered

## Screenshots (if UI changes)

[Add screenshots here]

## Checklist

- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Tests pass locally
- [ ] Documentation updated (if needed)
```

### Step 4: Create PR

```bash
gh pr create \
  --title "type(scope): description" \
  --body "$(cat <<'EOF'
## Summary
[Summary here]

## Changes
- [Changes here]

## Testing
- [ ] Tests pass
EOF
)"
```

### Step 5: Post-Creation

```bash
# Add reviewers
gh pr edit --add-reviewer username

# Add labels
gh pr edit --add-label "type:feature"

# Link to issue
gh pr edit --body "Closes #123"
```

## Options

### Draft PR

```bash
gh pr create --draft
```

### Target Different Branch

```bash
gh pr create --base develop
```

### From Fork

```bash
gh pr create --repo upstream/repo
```

## PR Size Guidelines

- Ideal: < 400 lines changed
- Acceptable: 400-800 lines
- Too large: > 800 lines (consider splitting)
