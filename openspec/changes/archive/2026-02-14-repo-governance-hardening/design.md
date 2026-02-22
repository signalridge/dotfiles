## Context

This dotfiles repository already has mature automation for version pin updates (`update-versions`, `update-flake-lock`, `update-aqua-packages`) and baseline CI checks. However, repository governance is still missing three practical controls:

1. clear ownership boundaries for dependency bots vs repository workflows,
2. PR title policy enforcement,
3. an explicit security workflow that uploads findings into GitHub Security.

Without these controls, maintainers can receive duplicated dependency PRs, inconsistent PR metadata, and limited centralized security telemetry.

## Goals / Non-Goals

**Goals:**

- Keep Renovate enabled while removing overlap with repository-owned update paths.
- Add non-invasive PR title validation using Conventional Commit semantics.
- Add a security workflow with SARIF uploads suitable for a dotfiles/scripts repository.
- Provide a repository security policy document with private disclosure guidance.

**Non-Goals:**

- Introducing release automation (`release-please`, `goreleaser`) in this repository.
- Replacing existing CI/test workflows.
- Enforcing branch protection changes through code (repository admin action remains manual).

## Decisions

1. **Renovate remains the single dependency bot**
   - Keep Renovate and do not introduce Dependabot.
   - Disable/avoid overlapping manager scope where repository workflows are already authoritative.
   - Rationale: one bot + explicit ownership reduces duplicate PRs and noise.

2. **PR title quality gate via semantic PR title action**
   - Add dedicated workflow using `amannn/action-semantic-pull-request`.
   - Keep `requireScope: false` to reduce friction for docs/chore PRs.
   - Rationale: lightweight enforcement aligned with conventional commit discipline.

3. **Security baseline via dedicated workflow + SARIF upload**
   - Filesystem vulnerability scanning with Trivy SARIF upload.
   - Secret scanning with Gitleaks SARIF upload.
   - Rationale: integrates findings into GitHub Security UI without coupling to language-specific scanners.

4. **Security policy as repository-level contract**
   - Add `SECURITY.md` with scope, reporting path, and response expectations.
   - Use GitHub private vulnerability reporting as the primary channel.
   - Rationale: clear expectations for external reporters and maintainers.

## Risks / Trade-offs

- **[Risk] Security scans can produce noisy findings** -> Mitigation: scope scanner mode to repository filesystem and route findings through SARIF for triage.
- **[Risk] PR title gate may block some contributor flows** -> Mitigation: allow all common conventional types and no mandatory scope.
- **[Trade-off] Renovate scope reduction may leave some updates manual** -> Acceptable because repository-owned workflows already cover key update paths.

## Migration Plan

1. Add OpenSpec artifacts for this change.
2. Update `.github/renovate.json` to align ownership boundaries and safe automerge defaults.
3. Add `.github/workflows/pr-title.yml`.
4. Add `.github/workflows/security.yml`.
5. Add `SECURITY.md`.
6. Run pre-commit checks locally and merge through normal PR flow.

Rollback: revert the commit(s) adding these files/configs and re-run CI.

## Open Questions

- Should security workflow checks become required status checks in branch protection?
- Should Renovate major updates be grouped separately per ecosystem beyond current policy?
