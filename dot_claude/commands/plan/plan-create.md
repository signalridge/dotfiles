# /plan-create - Create Implementation Plan

Create a structured implementation plan with goals, constraints, and definition of done.

## Usage

```
/plan-create [title]
/plan-create --from-issue <number>
/plan-create --template <name>
```

## Arguments

- `title`: Plan title/feature name
- `--from-issue <number>`: Create plan from GitHub issue
- `--template <name>`: Use specific template (feature, bugfix, refactor)

## Plan Structure

```markdown
---
created: YYYY-MM-DD
owner: [your name]
status: draft | in-progress | completed
issue: #123 (if applicable)
pr: #456 (when created)
---

# Plan: [Title]

## Goal

[One paragraph describing the desired outcome and why it matters]

## Background

[Context, current state, why this change is needed]

## Constraints

- [Technical constraint 1]
- [Business constraint 2]
- [Time/resource constraint 3]

## Definition of Done

- [ ] [Measurable criterion 1]
- [ ] [Measurable criterion 2]
- [ ] [Measurable criterion 3]
- [ ] Tests pass
- [ ] Documentation updated
- [ ] PR approved and merged

## Assumptions

- [Assumption 1 - verified/unverified]
- [Assumption 2 - verified/unverified]

## Decisions Required

- [ ] [Decision 1]: [Options A, B, C]
- [ ] [Decision 2]: [Options X, Y]

## Implementation Steps

1. [ ] Step 1
2. [ ] Step 2
3. [ ] Step 3

## References

- [Link to design doc]
- [Link to related issues]
- [Link to relevant code]
```

## Workflow

### Step 1: Gather Seeds

Collect information:

- **Goal**: What are we trying to achieve?
- **Background**: Why is this needed now?
- **Constraints**: What limits our options?
- **Success criteria**: How do we know we're done?

### Step 2: Generate Draft

Create initial plan with:

- Clear, measurable goals
- Realistic constraints
- Specific DoD items
- Logical implementation steps

### Step 3: Refine (2-3 iterations)

Ask clarifying questions:

- Are there edge cases not covered?
- Are assumptions documented and verified?
- Are there decisions that need to be made first?
- Is the scope appropriate?

### Step 4: Save Plan

```bash
# Save to .claude/plans/ directory
mkdir -p .claude/plans
# File: .claude/plans/YYYY-MM-DD-feature-name.md
```

## Templates

### Feature Template

- Focus on user value and acceptance criteria
- Include UI/UX considerations if applicable
- Consider backwards compatibility

### Bugfix Template

- Include reproduction steps
- Root cause analysis section
- Regression test requirement

### Refactor Template

- Current vs. target architecture
- Migration strategy
- Rollback plan

## Best Practices

1. **Start with Why**: Goal should explain the value, not just the task
2. **Be Specific**: Vague DoD leads to scope creep
3. **Surface Unknowns**: Better to identify decisions early
4. **Keep It Updated**: Plan is a living document
5. **Right Size**: If > 2 weeks work, consider splitting

## Examples

### Feature Plan

```
/plan-create user authentication
→ Creates plan for auth feature with OAuth, session management, etc.
```

### From Issue

```
/plan-create --from-issue 123
→ Pulls issue details and creates structured plan
```

## Related Commands

- `/plan-refine` - Improve existing plan
- `/plan-split` - Break large plan into smaller ones
- `/plan-import` - Import external plan
