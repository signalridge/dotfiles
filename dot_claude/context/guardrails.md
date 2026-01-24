# Guardrails - Sensitive Areas

Unified definition of sensitive areas requiring special handling.

## Sensitive Categories

| Category             | Examples                                   | Risk Level |
| -------------------- | ------------------------------------------ | ---------- |
| **Authentication**   | Login, OAuth, JWT, sessions, tokens        | Critical   |
| **Authorization**    | Permissions, roles, ACLs, policies         | Critical   |
| **Financial**        | Billing, payments, subscriptions, invoices | Critical   |
| **Security**         | Encryption, hashing, secrets, credentials  | Critical   |
| **Data Schema**      | Database migrations, model changes         | High       |
| **External APIs**    | Public endpoints, webhooks, integrations   | High       |
| **Irreversible Ops** | Data deletion, migrations, deployments     | High       |
| **PII/Privacy**      | User data, GDPR, personal information      | High       |

## Detection Patterns

### File Paths

```
**/auth/**
**/security/**
**/login/**
**/billing/**
**/payment/**
**/migrations/**
**/api/public/**
```

### Content Keywords

```
password, secret, token, credential, api_key, private_key
encrypt, decrypt, hash, salt
billing, payment, invoice, subscription
delete, drop, truncate, migrate
```

### Excluded (False Positives)

```
**/test_*.py
**/*_test.py
**/__mocks__/**
**/fixtures/**
```

## Required Actions

### Pre-Change

- Verify necessity of change
- Check for existing patterns
- Consider rollback strategy

### Post-Change (Report)

1. **Files changed** - List all modified files
2. **What was modified** - Brief description
3. **Intent/reasoning** - Why this change was needed
4. **Impact scope** - What else might be affected
5. **Rollback plan** - How to undo if needed

### Example Report

```markdown
## Guardrail Report: Authentication Change

**Files:** src/auth/login.py, src/auth/middleware.py
**Modified:** Token validation logic, session timeout
**Reason:** Fix security vulnerability CVE-2024-XXXX
**Impact:** All authenticated endpoints
**Rollback:** Revert commits abc123..def456
```

## Integration Points

This document is the Single Source of Truth (SSOT) for guardrails. Referenced by:

- `CLAUDE.md` - Collaboration Model section
- `coding-philosophy.md` - ALWAYS rules
- `security-scanning` plugin - security review skills
- `settings.json` - deny permissions
