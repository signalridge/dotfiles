# /review - Code Review

Perform a structured code review using the review-code skill.

## Usage

```
/review                     # Review staged/uncommitted changes
/review path/to/file.py     # Review specific file
/review --security          # Focus on security (uses security-scanning plugin)
/review --quick             # Quick pass, critical issues only
```

## Workflow

1. **Identify scope**

   ```bash
   git diff --name-only HEAD
   git diff --cached --name-only
   ```

2. **Apply review skill**
   - Load `skills/review-code/` for full review
   - Or use `security-scanning` plugin for `--security` flag

3. **Generate report** using skill's output format

## Review Dimensions

See `skills/review-code/SKILL.md` for complete rules:

| Dimension    | Prefix | Focus                       |
| ------------ | ------ | --------------------------- |
| Security     | SEC    | XSS, injection, credentials |
| Architecture | ARCH   | Coupling, SRP, abstractions |
| Correctness  | CORR   | Null checks, error handling |
| Performance  | PERF   | Algorithms, I/O, memory     |
| Readability  | READ   | Naming, complexity          |
| Testing      | TEST   | Coverage, assertions        |

## Output Format

```markdown
## Code Review: [filename]

### Critical Issues

- [SEC-001] [line:123] Description

### High Priority

- [ARCH-002] [line:45] Description

### Summary

- Critical: X | High: Y | Medium: Z
```

## Related

- **Skill:** `skills/review-code/` - Full rule definitions
- **Agent:** `agents/review/code-auditor` - For comprehensive audits
- **Quick:** `/review --quick` for fast checks
