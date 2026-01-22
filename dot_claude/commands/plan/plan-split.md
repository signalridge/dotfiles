# /plan-split - Split Large Plan

Break a large plan into multiple smaller, manageable plans.

## Usage

```
/plan-split [plan-file]
/plan-split --by-phase
/plan-split --by-component
/plan-split --preview
```

## Arguments

- `plan-file`: Path to plan file (default: most recent)
- `--by-phase`: Split by implementation phases
- `--by-component`: Split by system components
- `--preview`: Show split preview without creating files

## When to Split

Split when:

- Estimated time > 2 weeks
- DoD has > 10 items
- Multiple independent deliverables
- Different team members for different parts
- Risk of scope creep is high

## Workflow

### Step 1: Analyze Plan

Review:

- Number of DoD items
- Dependencies between steps
- Natural boundaries (components, phases)
- Risk distribution

### Step 2: Propose Split Strategy

Options:

| Strategy         | When to Use               | Example                             |
| ---------------- | ------------------------- | ----------------------------------- |
| **By Phase**     | Sequential work           | Phase 1: Backend, Phase 2: Frontend |
| **By Component** | Independent parts         | Auth service, User service          |
| **By Priority**  | Must-have vs nice-to-have | MVP, Enhancements                   |
| **By Risk**      | De-risk early             | Spike, Implementation               |

### Step 3: Define Split Points

Group DoD items:

```markdown
## Original DoD

- [ ] A: Database schema
- [ ] B: API endpoints
- [ ] C: Frontend components
- [ ] D: Integration tests
- [ ] E: Documentation
- [ ] F: Performance optimization

## Proposed Split

Plan 1 (Foundation):

- [ ] A: Database schema
- [ ] B: API endpoints
- [ ] D: Integration tests (API only)

Plan 2 (Frontend):

- [ ] C: Frontend components
- [ ] D: Integration tests (E2E)
- [ ] E: Documentation

Plan 3 (Polish):

- [ ] F: Performance optimization
```

### Step 4: Handle Dependencies

For each split plan:

- **Prerequisites**: What must be done first?
- **Deliverables**: What does this plan produce?
- **Handoff**: What does next plan need?

Add cross-references:

```markdown
## References

- Depends on: [Plan 1: Foundation](./plan-1-foundation.md)
- Blocks: [Plan 3: Polish](./plan-3-polish.md)
```

### Step 5: Distribute Shared Elements

For each child plan:

- Copy relevant constraints
- Copy applicable assumptions
- Add plan-specific decisions
- Update scope in goal

### Step 6: Generate Split Plans

Create files:

```
.claude/plans/
├── original-plan.md (archived)
├── plan-1-foundation.md
├── plan-2-frontend.md
└── plan-3-polish.md
```

## Split Templates

### By Phase

```markdown
# Plan 1: [Feature] - Phase 1 (Foundation)

Goal: Establish backend infrastructure for [feature]

# Plan 2: [Feature] - Phase 2 (Implementation)

Goal: Build user-facing functionality

# Plan 3: [Feature] - Phase 3 (Polish)

Goal: Optimize and document
```

### By Component

```markdown
# Plan: [Feature] - Auth Service

Goal: Implement authentication for [feature]

# Plan: [Feature] - Data Service

Goal: Implement data layer for [feature]

# Plan: [Feature] - UI Components

Goal: Build frontend for [feature]
```

## Output

```markdown
## Split Summary

### Original Plan

- file: user-management.md
- DoD items: 12
- Estimated: 4 weeks

### Created Plans

1. **user-management-backend.md**
   - DoD items: 5
   - Estimated: 1.5 weeks
   - Prerequisites: None

2. **user-management-frontend.md**
   - DoD items: 4
   - Estimated: 1 week
   - Prerequisites: Plan 1

3. **user-management-polish.md**
   - DoD items: 3
   - Estimated: 1 week
   - Prerequisites: Plan 1, 2

### Cross-References Added

- All plans reference each other
- Dependencies clearly marked
```

## Notes

- Keep plans independent where possible
- Each plan should be deliverable on its own
- Maintain traceability to original plan
- Update original plan status to "split"
