# /review - Code Review

Run a focused review for correctness, security, and maintainability.

## Usage

```text
/review
/review <path>
```

## Steps

1. Determine review scope (changed files or target path).
2. Inspect correctness and security risks first.
3. Check test impact and missing coverage.
4. Return findings with file references and severity.

## Output

- Critical issues (must fix)
- High-priority issues
- Optional improvements
