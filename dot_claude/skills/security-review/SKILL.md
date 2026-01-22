# Security Review

Security guidelines and common vulnerability patterns to check.

## OWASP Top 10 Checklist

### 1. Injection

**Risk:** SQL, NoSQL, OS, LDAP injection

**Check:**

- [ ] All user inputs are validated
- [ ] Parameterized queries used (no string concatenation)
- [ ] ORM used correctly

**Bad:**

```python
# SQL Injection vulnerable
query = f"SELECT * FROM users WHERE id = {user_id}"
cursor.execute(query)
```

**Good:**

```python
# Parameterized query
cursor.execute("SELECT * FROM users WHERE id = ?", (user_id,))

# Or with ORM
User.query.filter_by(id=user_id).first()
```

### 2. Broken Authentication

**Check:**

- [ ] Strong password requirements
- [ ] Rate limiting on login attempts
- [ ] Secure session management
- [ ] MFA available for sensitive operations

### 3. Sensitive Data Exposure

**Check:**

- [ ] No secrets in code or config files
- [ ] HTTPS enforced
- [ ] Sensitive data encrypted at rest
- [ ] Proper logging (no sensitive data logged)

**Bad:**

```python
# Hardcoded secret
API_KEY = "sk-1234567890abcdef"
```

**Good:**

```python
# From environment
API_KEY = os.environ.get("API_KEY")
if not API_KEY:
    raise ValueError("API_KEY not configured")
```

### 4. XML External Entities (XXE)

**Check:**

- [ ] XML parsing disables external entities
- [ ] Use JSON instead of XML where possible

### 5. Broken Access Control

**Check:**

- [ ] Authorization checked on every request
- [ ] Principle of least privilege
- [ ] CORS properly configured

**Bad:**

```python
# Missing authorization check
@app.get("/admin/users")
def list_users():
    return db.get_all_users()
```

**Good:**

```python
@app.get("/admin/users")
def list_users(current_user: User = Depends(get_current_user)):
    if not current_user.is_admin:
        raise HTTPException(403, "Admin access required")
    return db.get_all_users()
```

### 6. Security Misconfiguration

**Check:**

- [ ] Debug mode disabled in production
- [ ] Default credentials changed
- [ ] Error messages don't leak information
- [ ] Security headers set (CSP, HSTS, etc.)

### 7. Cross-Site Scripting (XSS)

**Check:**

- [ ] User input escaped before rendering
- [ ] Content-Security-Policy header set
- [ ] HttpOnly flag on cookies

**Bad:**

```html
<!-- Vulnerable to XSS -->
<div>{{ user_input }}</div>
```

**Good:**

```html
<!-- Auto-escaped in most frameworks -->
<div>{{ user_input | escape }}</div>
```

### 8. Insecure Deserialization

**Check:**

- [ ] Avoid deserializing untrusted data
- [ ] Use safe serialization formats (JSON over pickle)

**Bad:**

```python
# Dangerous - arbitrary code execution
import pickle
data = pickle.loads(user_data)
```

**Good:**

```python
import json
data = json.loads(user_data)
```

### 9. Using Components with Known Vulnerabilities

**Check:**

- [ ] Dependencies regularly updated
- [ ] Security advisories monitored
- [ ] No deprecated packages

```bash
# Check for vulnerabilities
pip-audit  # Python
npm audit  # Node.js
```

### 10. Insufficient Logging & Monitoring

**Check:**

- [ ] Authentication failures logged
- [ ] Access control failures logged
- [ ] No sensitive data in logs
- [ ] Logs protected from tampering

## Quick Security Checklist

```
[ ] No hardcoded secrets
[ ] Input validation on all user data
[ ] Parameterized queries
[ ] Authentication on protected routes
[ ] Authorization checks
[ ] HTTPS enforced
[ ] Secure cookie flags
[ ] Rate limiting
[ ] Error handling doesn't leak info
[ ] Dependencies up to date
```
