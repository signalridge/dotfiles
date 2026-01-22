# /pr-review - Review Pull Request

Perform a structured code review on a pull request.

## Usage

```
/pr-review [PR_NUMBER or URL]
```

## Workflow

### Step 1: Fetch PR Information

```bash
# Get PR details
gh pr view NUMBER --json title,body,files,additions,deletions,commits

# Get diff
gh pr diff NUMBER

# Check CI status
gh pr checks NUMBER
```

### Step 2: Understand Context

- Read PR description and linked issues
- Understand the goal and scope
- Check if PR is appropriately sized

### Step 3: Review with Hierarchy

#### Critical (Must Fix)

Security vulnerabilities, data loss risks, breaking changes:

- [ ] No hardcoded secrets or credentials
- [ ] No SQL/command injection vulnerabilities
- [ ] No authentication/authorization bypass
- [ ] No data exposure risks
- [ ] Proper error handling (no silent failures)

#### High (Should Fix)

Correctness and logic issues:

- [ ] Logic is correct and handles edge cases
- [ ] Error conditions handled appropriately
- [ ] No race conditions or deadlocks
- [ ] API contracts maintained
- [ ] Tests cover the changes

#### Medium (Consider)

Performance and maintainability:

- [ ] No obvious performance issues
- [ ] No unnecessary complexity
- [ ] Code follows project conventions
- [ ] Clear naming and structure

#### Low (Nit)

Style and minor improvements:

- [ ] Consistent formatting
- [ ] Clear comments where needed
- [ ] No leftover debug code

### Step 4: Leave Feedback

#### Comment Types

```bash
# General comment
gh pr comment NUMBER --body "Comment text"

# Request changes
gh pr review NUMBER --request-changes --body "Reason"

# Approve
gh pr review NUMBER --approve --body "LGTM"
```

#### Comment Format

```markdown
**[CRITICAL]** Security: SQL injection vulnerability
`file.py:45` - Use parameterized queries instead of string formatting

**[HIGH]** Logic: Missing null check
`api.py:123` - `user` can be None here, add validation

**[MEDIUM]** Performance: N+1 query
`service.py:67` - Consider eager loading to avoid N+1

**[NIT]** Style: Inconsistent naming
`utils.py:12` - Use snake_case for function names
```

### Step 5: Summary

```markdown
## Review Summary

### Overall

[Approve / Request Changes / Comment]

### Key Points

- [Main feedback point 1]
- [Main feedback point 2]

### Statistics

- Files reviewed: X
- Critical issues: X
- High issues: X
- Suggestions: X
```

## Quick Commands

```bash
# List open PRs
gh pr list

# Checkout PR locally for testing
gh pr checkout NUMBER

# View PR in browser
gh pr view NUMBER --web

# Merge PR
gh pr merge NUMBER --squash --delete-branch
```
