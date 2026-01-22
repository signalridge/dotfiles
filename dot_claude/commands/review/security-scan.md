# /security-scan - Quick Security Scan

Fast security analysis for immediate feedback.

## Usage

```
/security-scan                    # Scan recent changes
/security-scan path/to/file.py    # Scan specific file
```

## Workflow

### 1. Identify Scope

```bash
git diff --name-only HEAD~1
```

### 2. Quick Checks

```bash
# Secrets detection
grep -rn "password\|secret\|api_key\|token" --include="*.py" --include="*.js"

# Dependency audit
uv pip audit        # Python
npm audit           # Node.js
```

### 3. Apply Security Skill

Load `skills/security-review/SKILL.md` checklist for:

- OWASP Top 10
- Language-specific patterns
- Common vulnerabilities

## Output

```markdown
## Security Scan: [scope]

### Quick Results

- Secrets found: X locations
- Dependency issues: X packages
- Code patterns: X concerns

### Action Required

1. [Critical issue]
2. [High issue]
```

## Related

- **Deep analysis:** `/security-review-deep` for thorough review
- **Skill:** `skills/security-review/` - Full OWASP checklist
- **Tools:** `bandit`, `semgrep`, `gitleaks` for automation
