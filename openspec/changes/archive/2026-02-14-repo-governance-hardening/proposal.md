## Why

Repository automation currently lacks explicit governance around dependency update ownership, PR title policy enforcement, and a dedicated security baseline workflow. This creates avoidable PR churn and weaker security signal quality in CI.

## What Changes

- Align Renovate behavior with existing repository-owned update workflows to avoid duplicate automation paths.
- Add a PR title workflow that enforces Conventional Commit style on pull requests.
- Add a dedicated security workflow for filesystem vulnerability scan + secret scan reporting.
- Add `SECURITY.md` with a clear vulnerability reporting and handling policy for this repository.

## Capabilities

### New Capabilities

- `repo-governance-automation`: Repository governance policy for dependency automation, PR metadata quality gate, and security baseline checks.

### Modified Capabilities

- (none)

## Impact

- `.github/renovate.json` policy behavior and automerge rules.
- New workflow files in `.github/workflows/`.
- New repository policy document `SECURITY.md`.
- CI/security signal quality in GitHub Actions and Security tab.
