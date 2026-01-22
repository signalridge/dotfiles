# /pr-update - Update Pull Request

Update an existing pull request's title, description, or metadata.

## Usage

```
/pr-update <pr-number>
/pr-update <pr-number> --title "New title"
/pr-update <pr-number> --body
/pr-update <pr-number> --sync
```

## Arguments

- `pr-number`: PR to update
- `--title "text"`: Update title
- `--body`: Update description interactively
- `--sync`: Sync description with current changes
- `--add-label <label>`: Add label
- `--add-reviewer <user>`: Add reviewer

## Workflow

### Step 1: Fetch Current PR State

```bash
# Get current PR details
gh pr view 123 --json title,body,labels,assignees,milestone

# Get diff since PR creation
gh pr diff 123
```

### Step 2: Analyze Changes

If new commits added since PR creation:

- New features implemented
- Bug fixes included
- Tests added
- Documentation updated

### Step 3: Update Title

Follow convention: `type(scope): description`

```bash
gh pr edit 123 --title "feat(auth): add OAuth2 support for GitHub login"
```

### Step 4: Update Description

```bash
# Interactive edit
gh pr edit 123 --body-file -

# Or from file
gh pr edit 123 --body-file pr-description.md
```

### Description Template

```markdown
## Summary

[Updated summary reflecting all changes]

## Changes

- [x] Original change 1
- [x] Original change 2
- [x] **NEW:** Additional change 3
- [x] **NEW:** Bug fix for edge case

## Testing

- [x] Unit tests added
- [x] Integration tests pass
- [x] **NEW:** E2E tests added

## Screenshots (if applicable)

[Add new screenshots if UI changed]

## Notes for Reviewers

[Any additional context for the review]
```

### Step 5: Update Labels

```bash
# Add labels
gh pr edit 123 --add-label "needs-review"
gh pr edit 123 --add-label "size:medium"

# Remove labels
gh pr edit 123 --remove-label "wip"
```

### Step 6: Update Reviewers

```bash
# Add reviewers
gh pr edit 123 --add-reviewer username1,username2

# Add team
gh pr edit 123 --add-reviewer org/team-name
```

### Step 7: Link Issues

```bash
# Update body to include issue link
gh pr edit 123 --body "$(gh pr view 123 --json body -q .body)

Closes #456
Fixes #789"
```

## Sync Mode

Automatically update description based on commits:

```bash
# Analyze commits since base
git log origin/main..HEAD --pretty=format:"- %s"

# Generate updated summary
# ... Claude analyzes changes ...

# Update PR
gh pr edit 123 --body "$(cat updated-description.md)"
```

## Common Updates

### Convert Draft to Ready

```bash
gh pr ready 123
```

### Mark as Draft

```bash
gh pr ready 123 --undo
```

### Update Base Branch

```bash
gh pr edit 123 --base develop
```

### Add Milestone

```bash
gh pr edit 123 --milestone "v2.0"
```

## Output

```markdown
## PR Updated: #123

### Changes Made

- Title: "fix: login error" → "feat(auth): add OAuth2 support"
- Description: Updated with new changes
- Labels: Added "needs-review", removed "wip"
- Reviewers: Added @reviewer1, @reviewer2

### Current State

- Status: Ready for review
- Checks: 3 passing, 0 failing
- Reviews: 0/2 approved

### Link

https://github.com/owner/repo/pull/123
```

## Batch Updates

Update multiple aspects at once:

```bash
gh pr edit 123 \
  --title "feat(auth): add OAuth2 support" \
  --add-label "needs-review" \
  --add-label "size:large" \
  --remove-label "wip" \
  --add-reviewer team-lead \
  --milestone "v2.0"
```

## Related Commands

- `/pr-create` - Create new PR
- `/pr-ready` - Check if PR is ready
- `/pr-comment` - Add comments
- `/pr-review` - Review PR
