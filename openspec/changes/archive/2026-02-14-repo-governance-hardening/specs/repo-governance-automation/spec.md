## ADDED Requirements

### Requirement: Renovate policy SHALL avoid overlap with repository-owned update workflows

The repository SHALL configure Renovate so that dependency update ownership is explicit and does not duplicate repository-owned update workflows.

#### Scenario: Renovate configuration enforces ownership boundaries

- **WHEN** maintainers review `.github/renovate.json`
- **THEN** overlapping update paths with repository-owned workflows are explicitly disabled or constrained

#### Scenario: Renovate keeps safe automerge scope

- **WHEN** Renovate creates update PRs
- **THEN** automerge behavior is restricted to explicitly allowed low-risk update types

### Requirement: Pull requests SHALL pass title policy validation

The repository SHALL enforce Conventional Commit style pull request titles using a dedicated GitHub Actions workflow.

#### Scenario: PR title workflow validates on PR updates

- **WHEN** a pull request is opened, edited, synchronized, or reopened
- **THEN** the PR title workflow validates the title against allowed conventional types

### Requirement: Repository SHALL run baseline security scans in CI

The repository SHALL provide a dedicated security workflow that scans the repository and uploads security findings in SARIF format.

#### Scenario: Trivy scan uploads SARIF

- **WHEN** the security workflow runs
- **THEN** filesystem vulnerability scan results are uploaded to GitHub Security as SARIF

#### Scenario: Gitleaks scan uploads SARIF

- **WHEN** the security workflow runs
- **THEN** secret scan results are uploaded to GitHub Security as SARIF

### Requirement: Repository SHALL publish a vulnerability disclosure policy

The repository SHALL include `SECURITY.md` that defines reporting channels, expectations, and scope.

#### Scenario: Security policy exists at repository root

- **WHEN** users inspect repository documentation
- **THEN** `SECURITY.md` provides private reporting guidance and response expectations
