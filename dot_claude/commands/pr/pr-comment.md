# /pr-comment - Add PR Comment

Add comments to pull requests with context-aware suggestions.

## Usage

```
/pr-comment <pr-number> [message]
/pr-comment <pr-number> --file <path> --line <number>
/pr-comment <pr-number> --review
```

## Arguments

- `pr-number`: PR number to comment on
- `message`: Comment text (interactive if omitted)
- `--file <path>`: Comment on specific file
- `--line <number>`: Comment on specific line
- `--review`: Start a review (batch comments)

## Comment Types

| Type        | Command                  | Use Case                    |
| ----------- | ------------------------ | --------------------------- |
| **General** | `gh pr comment`          | Overall feedback            |
| **Line**    | `gh pr review --comment` | Code-specific feedback      |
| **Review**  | `gh pr review`           | Formal review with approval |

## Workflow

### Step 1: Fetch PR Context

```bash
# Get PR details
gh pr view 123 --json title,body,files,additions,deletions

# Get PR diff
gh pr diff 123
```

### Step 2: Choose Comment Type

#### General Comment

For overall feedback, questions, or updates:

```bash
gh pr comment 123 --body "Comment text here"
```

#### Line-specific Comment

For code-specific feedback:

```bash
gh api repos/{owner}/{repo}/pulls/123/comments \
  -f body="Suggestion: use const here" \
  -f commit_id="abc123" \
  -f path="src/file.ts" \
  -f line=42
```

#### Review Comment

For formal review:

```bash
gh pr review 123 --comment --body "Comments without approval decision"
gh pr review 123 --approve --body "LGTM!"
gh pr review 123 --request-changes --body "Please fix X"
```

### Step 3: Format Comment

#### Feedback Categories

```markdown
**[CRITICAL]** Security issue
Need to sanitize user input here to prevent XSS.

**[SUGGESTION]** Performance
Consider memoizing this computation.

**[QUESTION]** Clarification needed
Why was this approach chosen over X?

**[NIT]** Style
Minor: prefer `const` over `let` here.
```

#### Code Suggestions

````markdown
```suggestion
const value = computeValue();
```
````

#### Referencing Code

```markdown
In `src/api.ts:45`:

> const data = fetchData();

This could cause issues when...
```

## Templates

### Request for Changes

```markdown
Thanks for the PR! I have a few suggestions:

## Required Changes

- [ ] Fix security issue in auth.ts:23
- [ ] Add error handling for edge case

## Optional Improvements

- Consider using TypeScript generics here
- Could simplify with destructuring

Let me know if you have questions!
```

### Approval

```markdown
Looks good!

## Summary

- Clean implementation of feature X
- Good test coverage
- Documentation updated

Approving with minor suggestions that can be addressed in follow-up.
```

### Question

````markdown
Quick question about the implementation:

In `src/service.ts:67`:

```ts
const result = await fetchAll();
```
````

Would it be better to use pagination here? The dataset could be large.

````

## Batch Comments (Review Mode)

```bash
# Start review
gh pr review 123 --comment --body "Starting review..."

# Add multiple comments, then submit
gh pr review 123 --approve --body "All comments addressed"
````

## Output

```markdown
## Comment Added

- PR: #123 - Add user authentication
- Type: Line comment
- File: src/auth.ts:45
- Comment: "Consider using bcrypt for password hashing"

### Link

https://github.com/owner/repo/pull/123#discussion_r12345
```

## Related Commands

- `/pr-create` - Create new PR
- `/pr-review` - Full PR review
- `/pr-update` - Update PR description
