# /plan-refine - Refine Implementation Plan

Improve an existing plan through clarifying questions and iterative refinement.

## Usage

```
/plan-refine [plan-file]
/plan-refine --interactive
/plan-refine --check-only
```

## Arguments

- `plan-file`: Path to plan file (default: most recent in .claude/plans/)
- `--interactive`: Full interactive refinement session
- `--check-only`: Analyze without making changes

## Workflow

### Step 1: Analyze Current Plan

Review for:

- **Completeness**: All sections filled?
- **Clarity**: Ambiguous language?
- **Consistency**: Contradictions?
- **Feasibility**: Realistic scope?
- **Measurability**: Can DoD be verified?

### Step 2: Identify Issues

Common problems:

| Issue               | Example                 | Fix                                 |
| ------------------- | ----------------------- | ----------------------------------- |
| Vague goal          | "Improve performance"   | "Reduce API latency to <100ms"      |
| Missing constraints | No tech stack mentioned | Add technical boundaries            |
| Unmeasurable DoD    | "Works correctly"       | "All tests pass, no errors in logs" |
| Hidden assumptions  | Assuming API exists     | Document and verify                 |
| Scope creep risk    | "And also..."           | Split into phases                   |

### Step 3: Ask Clarifying Questions

One question at a time approach:

1. Ask the most important question first
2. Wait for response
3. Update plan immediately
4. Ask next question based on new context
5. Repeat until plan is solid

Example questions:

- "What happens if [edge case]?"
- "Is [assumption] verified?"
- "Who decides [open question]?"
- "What's the priority between [X] and [Y]?"

### Step 4: Update Plan

After each answer:

- Update relevant section
- Add new constraints/assumptions discovered
- Refine DoD if needed
- Update implementation steps

### Step 5: Verify Completeness

Checklist:

- [ ] Goal is specific and measurable
- [ ] All constraints documented
- [ ] DoD items are testable
- [ ] Assumptions are marked verified/unverified
- [ ] No open decisions blocking start
- [ ] Implementation steps are actionable
- [ ] Scope is appropriate (< 2 weeks ideal)

## Refinement Patterns

### Goal Refinement

```markdown
# Before

## Goal

Make the app faster.

# After

## Goal

Reduce p95 API response time from 500ms to <100ms for the /users endpoint,
improving user experience during peak load (>1000 concurrent users).
```

### DoD Refinement

```markdown
# Before

- [ ] Feature works

# After

- [ ] API endpoint returns correct data for all test cases
- [ ] Response time < 100ms at p95
- [ ] Error rate < 0.1%
- [ ] Integration tests added (>80% coverage for new code)
- [ ] Documentation updated in API reference
- [ ] Deployed to staging and verified
```

### Constraint Discovery

```markdown
# Added after refinement

## Constraints

- Must maintain backwards compatibility with v1 API
- Cannot require database migration during business hours
- Must work with existing authentication system
- Budget: < 2 engineering days
```

## Output

After refinement:

```markdown
## Refinement Summary

### Changes Made

1. Goal: Added specific metrics (latency, throughput)
2. Constraints: Added 3 new technical constraints
3. DoD: Expanded from 2 to 6 measurable items
4. Assumptions: Verified 2, added 1 new unverified

### Remaining Questions

- [ ] Confirm database connection pool size with ops team

### Confidence Level

Before: 60% → After: 90%
```

## Related Commands

- `/plan-create` - Create new plan
- `/plan-split` - Break plan into smaller pieces
