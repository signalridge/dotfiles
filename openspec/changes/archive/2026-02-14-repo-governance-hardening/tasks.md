## 1. OpenSpec Governance Artifacts

- [x] 1.1 Create proposal for repository governance hardening
- [x] 1.2 Create design for automation/security policy decisions
- [x] 1.3 Create capability spec for repository governance automation

## 2. Dependency Automation Policy

- [x] 2.1 Update `.github/renovate.json` to avoid overlap with repository-owned update workflows
- [x] 2.2 Restrict Renovate automerge to explicit low-risk update types

## 3. Governance Workflows

- [x] 3.1 Add `.github/workflows/pr-title.yml` for Conventional Commit PR title validation
- [x] 3.2 Add `.github/workflows/security.yml` for Trivy/Gitleaks SARIF reporting

## 4. Security Policy Documentation

- [x] 4.1 Add repository-level `SECURITY.md` with private disclosure guidance

## 5. Verification

- [x] 5.1 Run `pre-commit run --all-files`
- [x] 5.2 Mark OpenSpec tasks complete after implementation verification
