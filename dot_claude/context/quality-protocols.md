# Quality Protocols

## Overview

Two complementary protocols ensure high-quality implementation:

1. **Confidence Check** - Pre-implementation assessment (prevents wrong direction)
2. **Self-Check** - Post-implementation verification (ensures correctness)

---

## Confidence Check Protocol

### Purpose

Prevent wasted effort by assessing confidence BEFORE starting implementation.

**ROI:** Spending 1-2 minutes on confidence check can save hours of wrong-direction work.

### Confidence Levels

| Level      | Score  | Criteria                                    | Action               |
| ---------- | ------ | ------------------------------------------- | -------------------- |
| **High**   | ≥90%   | All checks pass, clear path forward         | Proceed immediately  |
| **Medium** | 70-89% | Some uncertainty, multiple valid approaches | Present alternatives |
| **Low**    | <70%   | Missing information, unclear requirements   | STOP and clarify     |

### Checklist (5 Items)

#### 1. No Duplicate Implementations (25%)

- [ ] Searched codebase for similar functionality
- [ ] Checked if feature already exists elsewhere
- [ ] Verified no conflicting implementations

**How:** `grep -r "keyword" src/` or Task tool with Explore agent

#### 2. Architecture Compliance (25%)

- [ ] Uses existing tech stack (not reinventing)
- [ ] Follows established patterns in codebase
- [ ] Integrates with existing systems properly

**Anti-pattern:** Creating custom API when Supabase exists, adding new ORM when one is used

#### 3. Official Documentation Verified (20%)

- [ ] Checked official docs for the technology
- [ ] Not relying on memory or assumptions
- [ ] API/syntax verified as current

**How:** WebFetch official docs, Context7 MCP if available

#### 4. Similar Working Examples Found (15%)

- [ ] Found 3+ similar implementations in codebase
- [ ] Or found working OSS examples
- [ ] Understand the pattern thoroughly

#### 5. Root Cause Identified (15%) [For Bugs]

- [ ] Can reproduce the issue
- [ ] Understand WHY it happens
- [ ] Know the exact location of the problem

### Output Template

```markdown
## Confidence Assessment

**Level:** HIGH / MEDIUM / LOW (~XX%)

### Checklist Results

- [x] No duplicates: Searched src/, no existing implementation
- [x] Architecture: Using existing auth service
- [x] Docs verified: Checked JWT library docs
- [x] Examples: Found 3 similar patterns in codebase
- [x] Root cause: N/A (new feature)

### Decision

[Proceeding with implementation / Presenting alternatives / Requesting clarification]

### [If MEDIUM] Alternatives

1. Option A: [description] - Pros/Cons
2. Option B: [description] - Pros/Cons

### [If LOW] Missing Information

- Need clarification on: [specific questions]
```

---

## Self-Check Protocol

### Purpose

Verify implementation correctness with EVIDENCE, not assumptions.

**Rule:** No speculation - run actual tests, check actual output.

### Verification Checklist

| Check            | Method               | Pass Criteria        |
| ---------------- | -------------------- | -------------------- |
| **Tests**        | Run test suite       | All tests pass       |
| **Regressions**  | Run related tests    | No new failures      |
| **Requirements** | Compare with request | All requirements met |
| **Quality**      | Run linter           | No new warnings      |

### Verification Steps

#### 1. Run Tests

```bash
# Run relevant tests
pytest tests/feature/ -v
npm test -- --testPathPattern="feature"
```

Report: Number passed, failed, skipped

#### 2. Check Regressions

```bash
# Run broader test suite
pytest tests/ -v --tb=short
npm test
```

Compare with baseline - no new failures

#### 3. Verify Requirements

- Re-read original request
- Check each requirement is addressed
- Note any partial implementations

#### 4. Code Quality

```bash
# Run linter
ruff check src/
eslint src/
```

Should be clean or only pre-existing warnings

### Output Template

```markdown
## Self-Check Results

### Tests

- **Status:** PASS / FAIL
- **Results:** 15 passed, 0 failed, 2 skipped
- **Coverage:** 85% (if available)

### Regressions

- **Status:** NONE / FOUND
- **Details:** All 47 existing tests still pass

### Requirements

- **Status:** MET / PARTIAL / UNMET
- [x] Requirement 1: Implemented
- [x] Requirement 2: Implemented
- [ ] Requirement 3: Partial - [explanation]

### Quality

- **Status:** CLEAN / WARNINGS
- **Lint:** No new warnings
- **Types:** No type errors
```

---

## When to Apply

| Task Level    | Confidence Check | Self-Check   |
| ------------- | ---------------- | ------------ |
| L1 (trivial)  | Skip             | Skip         |
| L2 (simple)   | Optional         | Optional     |
| L3 (moderate) | **Required**     | **Required** |
| L4 (complex)  | **Required**     | **Required** |

---

## Integration with Workflow

### L3+ Task Flow

```
1. Receive task
2. Assess complexity → L3+
3. Run Confidence Check
   - HIGH: Continue
   - MEDIUM: Present alternatives, wait for decision
   - LOW: Stop, request clarification
4. Run Pre-Analysis Protocol
5. Create TodoWrite plan
6. Implement
7. Run Self-Check Protocol
8. Report results
```

### Failure Handling

**Confidence Check fails (LOW):**

- Do NOT proceed
- List what information is missing
- Ask specific questions

**Self-Check fails:**

- Do NOT mark task complete
- Report failures clearly
- Propose fixes or request guidance
