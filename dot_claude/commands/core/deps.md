# /deps - Dependency Management

Analyze, add, update, or audit project dependencies.

## Actions

### Analyze Dependencies

```bash
# Python (uv)
uv tree                    # Show dependency tree
uv pip list --outdated     # Check for updates

# Node.js
npm ls                     # Show dependency tree
npm outdated               # Check for updates

# Nix
nix flake metadata         # Show flake inputs
nix flake update --dry-run # Preview updates
```

### Add Dependency

Before adding, check:

1. Is this dependency necessary? Can stdlib solve it?
2. Is it actively maintained? Check last commit, issues
3. What's the license?
4. What transitive dependencies does it bring?

```bash
# Python - ALWAYS use uv, never pip
uv add package-name
uv add --dev pytest       # Dev dependency

# Node.js
npm install package-name
npm install -D package    # Dev dependency

# Nix
# Add to flake.nix inputs or shell.nix
```

### Update Dependencies

```bash
# Python
uv lock --upgrade         # Update all
uv lock --upgrade-package name  # Update specific

# Node.js
npm update                # Update within semver
npm install pkg@latest    # Update to latest

# Nix
nix flake update          # Update flake inputs
```

### Security Audit

```bash
# Python
uv pip audit              # Check for vulnerabilities

# Node.js
npm audit                 # Security audit
npm audit fix             # Auto-fix if possible

# General
gh api /repos/{owner}/{repo}/vulnerability-alerts
```

## Checklist for New Dependencies

- [ ] Verified necessity (not in stdlib)
- [ ] Checked maintenance status (recent commits, responsive maintainer)
- [ ] Reviewed license compatibility
- [ ] Checked security advisories
- [ ] Reviewed transitive dependencies
- [ ] Added to appropriate section (runtime vs dev)
- [ ] Updated lock file
- [ ] Tested that build still works

## Red Flags

- No updates in 2+ years
- Many open security issues
- Excessive transitive dependencies
- Unclear or incompatible license
- Single maintainer with no activity
