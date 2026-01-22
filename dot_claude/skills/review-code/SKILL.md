---
name: review-code
description: Multi-dimensional code review with rule-based analysis. Covers security, architecture, correctness, performance, readability, and testing dimensions.
trigger: review code|code review|审查代码|代码审查
---

# Review Code Skill

Multi-dimensional code review using structured rule files for consistent, thorough analysis.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    Review Orchestrator                          │
│         collect → quick-scan → deep-review → report             │
└───────────────────────────┬─────────────────────────────────────┘
                            │
    ┌───────────┬───────────┼───────────┬───────────┬───────────┐
    ▼           ▼           ▼           ▼           ▼           ▼
┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐
│Security│ │  Arch  │ │Correct-│ │ Perf   │ │ Read-  │ │Testing │
│ Rules  │ │ Rules  │ │  ness  │ │ Rules  │ │ability │ │ Rules  │
└────────┘ └────────┘ └────────┘ └────────┘ └────────┘ └────────┘
```

## Review Dimensions

| Dimension        | Prefix | Focus Areas                           |
| ---------------- | ------ | ------------------------------------- |
| **Security**     | SEC    | XSS, injection, credentials, crypto   |
| **Architecture** | ARCH   | Coupling, layering, SRP, abstractions |
| **Correctness**  | CORR   | Null checks, error handling, logic    |
| **Performance**  | PERF   | Algorithms, I/O, memory leaks         |
| **Readability**  | READ   | Naming, complexity, documentation     |
| **Testing**      | TEST   | Coverage, assertions, test quality    |

## Severity Levels

| Level        | Prefix | Action Required       |
| ------------ | ------ | --------------------- |
| **Critical** | [C]    | Must fix before merge |
| **High**     | [H]    | Should fix            |
| **Medium**   | [M]    | Consider fixing       |
| **Low**      | [L]    | Nice to have          |

## Execution Flow

```
1. Collect Context
   └─ Identify files, tech stack, framework

2. Quick Scan
   └─ Load rules from rules/*.json
   └─ Run pattern matching
   └─ Identify high-risk areas

3. Deep Review (per dimension)
   └─ Apply dimension-specific rules
   └─ Check contextual patterns
   └─ Validate negative patterns

4. Generate Report
   └─ Group by severity
   └─ Include file:line references
   └─ Add fix examples
```

## Rule File Structure

Each `rules/*.json` file contains:

```json
{
  "dimension": "security",
  "prefix": "SEC",
  "rules": [
    {
      "id": "sql-injection",
      "category": "injection",
      "severity": "critical",
      "pattern": "regex pattern",
      "patternType": "regex|includes",
      "negativePatterns": ["patterns that exclude false positives"],
      "description": "What the issue is",
      "recommendation": "How to fix it",
      "fixExample": "// Before\n...\n// After\n..."
    }
  ]
}
```

## Usage

```bash
# Review specific files
/review src/auth/*.ts

# Review a directory
/review src/components/

# Review recent changes
/review $(git diff --name-only HEAD~1)
```

## Output Format

```markdown
## Code Review Report

### Critical Issues (Must Fix)

- **[SEC-001] SQL Injection** `src/db/query.ts:42`
  - Pattern: String concatenation in query
  - Fix: Use parameterized queries

### High Priority

- **[ARCH-002] Layer Violation** `src/components/UserList.tsx:15`
  - Pattern: Direct database access in component
  - Fix: Extract to service layer

### Medium Priority

...

### Summary

- Critical: 1
- High: 2
- Medium: 5
- Low: 3
```

## Rule Files Reference

| File                            | Rules                           |
| ------------------------------- | ------------------------------- |
| `rules/security-rules.json`     | XSS, injection, secrets, crypto |
| `rules/architecture-rules.json` | Coupling, layers, SRP           |
| `rules/correctness-rules.json`  | Null, errors, logic             |
| `rules/performance-rules.json`  | Complexity, I/O, memory         |
| `rules/readability-rules.json`  | Naming, nesting, magic values   |
| `rules/testing-rules.json`      | Assertions, coverage, quality   |
