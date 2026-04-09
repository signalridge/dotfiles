# /plan - Implementation Planning

Plan a feature or task with clear structure before coding.

## When to Use

- Direct changes where you want a lightweight implementation plan.
- Any time the scope is still fuzzy and you want to clarify goal/DoD.

## Framework: Goal → Constraints → Definition of Done

### Step 1: Clarify Goal

Ask for or derive:

- **What**: One-sentence description of the desired outcome
- **Why**: Business/technical motivation
- **Who**: Who benefits from this change

### Step 2: Identify Constraints

Consider:

- Existing patterns and conventions in the codebase
- Dependencies and compatibility requirements
- Performance requirements
- Security implications
- Testing requirements
- Rollback expectations

### Step 3: Define Success Criteria (DoD)

Create measurable acceptance criteria:

- [ ] Functional requirements met
- [ ] Tests pass (existing + new)
- [ ] No security vulnerabilities introduced
- [ ] Code follows project conventions
- [ ] Documentation updated if needed
- [ ] Rollback path is clear

### Step 4: Break Down Tasks

Create a task list with:

1. Research/exploration phase (if needed)
2. Implementation steps (ordered by dependency)
3. Testing steps
4. Cleanup/documentation

### Step 5: Identify Risks

List potential blockers:

- Unknown areas requiring investigation
- External dependencies
- Breaking changes

### Step 6: Decide First Command

Pick the next command to run:

- `/context` when you need entrypoints, dependencies, or conventions
- `/review` when the change touches auth/permissions/tokens/secrets
- `/test` when doing TDD or validating an assumption

## Output Format

```markdown
## Plan: [Feature Name]

### Goal

[One sentence]

### Scope

- In scope: ...
- Out of scope: ...

### Constraints

- [Constraint 1]
- [Constraint 2]

### Definition of Done

- [ ] [Criterion 1]
- [ ] [Criterion 2]

### Tasks

1. [ ] [Task 1]
2. [ ] [Task 2]

### Risks

- [Risk 1]: [Mitigation]

### Next Command

- [ ] /context
```
