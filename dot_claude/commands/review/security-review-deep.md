# /security-review-deep - Deep Security Analysis

Perform thorough security-focused code review using the security-review skill.

## Usage

```
/security-review-deep
/security-review-deep --pr <number>
/security-review-deep path/to/file.py
```

## Objective

Identify HIGH-CONFIDENCE security vulnerabilities with real exploitation potential.

**Principles:**

- Only flag issues with >80% confidence of actual exploitability
- Skip theoretical issues, style concerns, or low-impact findings
- Focus on vulnerabilities leading to unauthorized access, data breaches, or system compromise

## Workflow

### Step 1: Gather Context

```bash
git diff --name-only origin/HEAD...
git diff --merge-base origin/HEAD
```

### Step 2: Three-Phase Analysis

1. **Repository Context** - Identify existing security patterns
2. **Comparative Analysis** - Compare against established practices
3. **Vulnerability Assessment** - Trace data flow, identify injection points

### Step 3: Apply Security Plugin

Use `security-scanning` plugin skills for:

- OWASP Top 10 checklist (use `/security-scanning:security-sast`)
- Injection patterns (SQL, XSS, Command)
- Authentication/Authorization checks
- Sensitive data handling (use `/security-scanning:security-hardening`)

## Output Format

```markdown
## Security Review: [scope]

### CRITICAL (Exploitable)

- **[vuln-type]** `file:line` - Description
  - Exploitation: How it can be exploited
  - Fix: Recommended remediation

### HIGH (Likely Exploitable)

...

### Summary

Reviewed X files, found Y critical, Z high issues
```

## Related

- **Plugin:** `security-scanning` - OWASP checklist and patterns
- **Quick scan:** `/security-scan` for fast checks
- **General review:** `/review --security`
