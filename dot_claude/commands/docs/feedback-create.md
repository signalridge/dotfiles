# /feedback-create - Create Feedback Summary

Generate structured feedback summaries for code reviews, designs, or discussions.

## Usage

```
/feedback-create <context>
/feedback-create --from-pr <number>
/feedback-create --from-discussion
```

## Arguments

- `context`: Topic or area for feedback
- `--from-pr <number>`: Generate from PR comments
- `--from-discussion`: Interactive feedback collection
- `--format <type>`: Output format (markdown, json, github)

## Feedback Types

| Type              | Use Case               | Structure                   |
| ----------------- | ---------------------- | --------------------------- |
| **Code Review**   | PR feedback            | File-based, severity-tagged |
| **Design Review** | Architecture decisions | Pros/cons, alternatives     |
| **Retrospective** | Sprint/project review  | What worked, improvements   |
| **User Feedback** | Feature requests       | Priority, impact, effort    |

## Workflow

### Step 1: Collect Feedback

#### From PR Comments

```bash
# Get all comments
gh api repos/{owner}/{repo}/pulls/123/comments

# Get review comments
gh pr view 123 --json reviews
```

#### Interactive Collection

Prompt for feedback on:

- What's working well?
- What needs improvement?
- Specific concerns?
- Suggestions?

### Step 2: Categorize

| Category   | Icon | Description                       |
| ---------- | ---- | --------------------------------- |
| Critical   | 🔴   | Must address before merge/release |
| Important  | 🟠   | Should address soon               |
| Suggestion | 🟡   | Nice to have                      |
| Praise     | 🟢   | What's working well               |
| Question   | 🔵   | Needs clarification               |

### Step 3: Prioritize

Rank by:

1. **Impact**: How much does this affect users/system?
2. **Effort**: How hard is it to address?
3. **Risk**: What happens if not addressed?

### Step 4: Generate Summary

```markdown
## Feedback Summary: [Context]

Generated: YYYY-MM-DD
Source: [PR #123 / Discussion / Review]

### Overview

[Brief summary of feedback themes]

### Critical Issues (Must Fix)

1. 🔴 **[Issue Title]**
   - Location: `file.py:45`
   - Issue: [Description]
   - Suggested fix: [Recommendation]

### Important Feedback

1. 🟠 **[Issue Title]**
   - [Details]

### Suggestions

1. 🟡 **[Suggestion]**
   - [Details]
   - Effort: Low/Medium/High

### Positive Feedback

1. 🟢 **[What's working]**
   - [Details]

### Questions to Resolve

1. 🔵 **[Question]**
   - Context: [Why this matters]

### Action Items

- [ ] Fix critical issue 1
- [ ] Address important feedback 2
- [ ] Discuss question 1 with team

### Statistics

- Total items: X
- Critical: X
- Important: X
- Suggestions: X
```

## Templates

### Code Review Feedback

```markdown
## Code Review Feedback: PR #123

### Summary

Overall: Approve with minor changes

### By File

#### `src/api.py`

- 🔴 L45: SQL injection risk
- 🟡 L78: Consider extracting to helper

#### `tests/test_api.py`

- 🟢 Good coverage of edge cases
- 🟡 L23: Could use parametrize
```

### Design Feedback

```markdown
## Design Review: [Feature]

### Proposed Approach

[Summary of proposal]

### Feedback

#### Strengths

- Clean separation of concerns
- Aligns with existing patterns

#### Concerns

- 🟠 Scalability at 10x load
- 🟡 Migration complexity

#### Alternatives Considered

1. Option A: [Pros/Cons]
2. Option B: [Pros/Cons]

### Recommendation

[Final recommendation with rationale]
```

### Retrospective Feedback

```markdown
## Sprint Retrospective: [Sprint Name]

### What Worked Well

- Fast PR reviews
- Clear requirements

### What Could Improve

- More testing time
- Earlier design reviews

### Action Items for Next Sprint

1. [ ] Block 2 hours for testing before release
2. [ ] Design review meeting on day 2
```

## Output Formats

### GitHub Issue

```bash
gh issue create --title "Feedback: [Context]" --body-file feedback.md
```

### Slack Message

Compact format suitable for Slack.

### JSON

```json
{
  "context": "PR #123",
  "summary": "...",
  "items": [{ "category": "critical", "title": "...", "description": "..." }]
}
```

## Related Commands

- `/pr-review` - Full PR review
- `/review` - Code review checklist
