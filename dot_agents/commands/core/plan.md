# /plan - Implementation Planning

Plan a feature or task with clear structure before coding.

## When to Use

- `C2` direct changes where you want a lightweight implementation plan.
- `C2` changes where you want a more structured planning workflow via Superpowers `writing-plans`.
- Any time the scope is still fuzzy and you want to clarify goal/DoD.

## When NOT to Use

- If classification is `C3` or `C4`: use OpenSpec.
  - Next step (CLI-first): `openspec new change <change-name>`, with explicit confirmation.
  - Optional wrapper shortcuts: `/opsx:new <change-name>` (Claude) or `/opsx-new <change-name>` (Codex/OpenCode).
  - `C3` (Standard Governed): open change -> scan -> implement step-by-step -> validate -> archive.
  - `C4` (Discovery-First): open change -> **mandatory exploration phase** (map codebase, enumerate unknowns, write discovery summary) -> **user approval on scope** -> implement -> validate -> archive. Do not begin implementation until exploration is complete and user approves.

`/plan` does not conflict with OpenSpec wrappers (`/opsx:*` in Claude, `/opsx-*` in Codex/OpenCode). They are different layers:

- `/plan`: `C2` lightweight planning entry.
- OpenSpec CLI (`openspec ...`): canonical lifecycle entry for `C3`/`C4` implementation.
- OpenSpec wrappers: optional shortcuts when wrapper prompts are installed.

If wrappers are missing, continue with native `openspec ...` CLI. Install wrappers only when needed via `openspec init --tools <tool>` (or `openspec update`).

Always run `/route` first if category is not already explicit.

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
- `superpowers:writing-plans` when you need a structured, detailed execution plan
- `superpowers:brainstorming` when you need option exploration before committing to one plan

## Related Skills

- `superpowers:brainstorming`
- `superpowers:writing-plans`
- `superpowers:executing-plans`

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
