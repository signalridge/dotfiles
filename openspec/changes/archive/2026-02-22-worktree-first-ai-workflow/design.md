## Context

This repository already has a mature multi-tool workflow (`claude-manage`, `codex-manage`, OpenCode native config, OpenSpec lifecycle guidance), but `git worktree` is not currently first-class:

- No canonical project-local worktree directory exists.
- No explicit `.worktrees/` ignore rule exists.
- No helper command family exists for creating/jumping/removing worktrees.
- Shell prompt does not expose whether the current session is in a dedicated worktree.
- AGENTS policies discuss routing and risk controls, but do not enforce a dedicated-worktree habit for medium tasks.
- Command-layer guidance is not standardized across Claude/Codex/OpenCode for worktree workflow help.

As a result, multi-task AI sessions are easy to mix in one workspace, reducing isolation and increasing review/rollback cost.

## Pre-Analysis

- **Similar patterns**:
  - Existing doctor checks in `dot_local/bin/executable_claude-manage.tmpl` (runtime/config projection verification)
  - Existing doctor checks in `dot_local/bin/executable_codex-manage.tmpl` (prompt/link readiness checks)
  - Existing command-style shell helpers and completions in `dot_custom/functions.sh`
- **Dependencies**:
  - `git` CLI (`worktree list/add/remove/prune`, `check-ignore`)
  - `starship` prompt configuration (`private_dot_config/starship.toml`)
  - Shared command projection topology (`dot_agents/commands/core` -> tool-specific command surfaces)
- **Conventions**:
  - Shell helpers are user-facing zsh/bash functions in `dot_custom/functions.sh`
  - Prompt customizations are managed centrally in `private_dot_config/starship.toml`
  - AGENTS policies use requirement-style sections and cross-tool consistency notes
  - Tests rely on `assert_file_contains` + `jq` checks in `tests/test_opencode_config_rendering.sh`
- **Risk areas**:
  - `Irreversible Ops`: removing worktrees can discard local uncommitted changes if forced
  - Workflow governance drift: policy text and command behavior may diverge
  - Git ignore safety: missing ignore on `.worktrees/` pollutes repo status

## Goals

- Standardize a project-local worktree path convention: `.worktrees/<branch>`.
- Make the convention discoverable and executable through first-party helper commands.
- Add explicit L2+ worktree guidance to all three AGENTS templates.
- Make worktree state visible in prompt when operating inside `.worktrees/*`.
- Define worktree command guidance once in shared command source, then project to all three tool surfaces.
- Keep changes incremental and compatible with current tool boundaries.

## Spec Layering

- **Repository Baseline (repo-level)**: ignore rules and directory convention (`.worktrees/`).
- **Shell Interface (shell-level)**: `wt-*` lifecycle commands and prompt visibility.
- **Tool Integration (tool-level)**: AGENTS `Worktree Gate (L2+)` and command-layer usage guidance.
- **Cross-Tool Consistency (projection-level)**: shared command doc in `dot_agents/commands/core` and per-tool projection checks.

This layering avoids overlap:

- `worktree-first-ai-workflow/spec.md` defines baseline shell/tool behavior.
- `shared-ai-commands/spec.md` defines cross-tool command projection consistency.

## Non-Goals

- Introducing new OpenCode wrapper binaries.
- Replacing existing `claude-with` / `codex-with` launch model.
- Adding `--worktree` flags into `claude-with` / `codex-with` launchers (to avoid mixing launcher and workspace responsibilities).
- Enforcing hard runtime blocking when not in a worktree (policy + diagnostics first).
- Changing OpenSpec artifact versioning posture (`openspec/` remains local-only by default).
- Supporting nested worktree creation inside an existing worktree path.
- Supporting in-place worktree rename semantics (delete + recreate remains canonical).
- Supporting non-`starship` prompt engines in this change (out of scope for v1).

## Options Considered

1. **Policy-only** (AGENTS/docs only)

- Pros: minimal code changes.
- Cons: no execution path, no diagnostics, weak adoption.

2. **Script-only** (`wt-*` only)

- Pros: immediate usability.
- Cons: no governance contract in specs/AGENTS; behavior can drift.

3. **Spec + policy + scripts + diagnostics (chosen)**

- Pros: end-to-end enforceability with low operational risk.
- Cons: touches multiple files and tests.

4. **OpenCode-only command extension (rejected)**

- Pros: quick local win for one tool.
- Cons: creates cross-tool behavior drift and duplicate maintenance burden.

## Decisions

1. Use `.worktrees/` as canonical local directory and add `.gitignore` rule.
2. Add `wt-*` helper family in `dot_custom/functions.sh`:
   - `wt-new`: create/switch to dedicated worktree
   - `wt-go`: jump into an existing worktree
   - `wt-ls`: list worktrees
   - `wt-rm`: remove a worktree with confirmation
   - `wt-prune`: prune stale worktree metadata
3. Keep `manage doctor` scoped to account/config responsibilities; do not make worktree readiness a doctor dependency.
4. Add a `Worktree Gate (L2+)` section to all AGENTS templates.
5. Add regression checks in existing shell test suite.
6. Add prompt visibility via `starship` custom module that only renders inside `.worktrees/*`.
7. Add a shared `worktree` command doc under `dot_agents/commands/core` and rely on existing projection to surface it in Claude/Codex/OpenCode.
8. For `wt-new`, fail fast on path collisions when target path exists but is not a worktree owned by current repository.
9. For non-standard worktree locations (not under `.worktrees/*`), prompt indicator behavior is allowed to be hidden, but must not error or break prompt rendering.
10. Keep `.openspec.yaml` minimal (`schema` + `created`) and place verification commands in tasks/tests instead of introducing non-standard YAML fields.

## Quantified Risks

| Risk                                    | Severity | Likelihood | Mitigation                                          | Confidence |
| --------------------------------------- | -------- | ---------- | --------------------------------------------------- | ---------- |
| `wt-rm --force` causes data loss        | High     | Low        | Confirmation-first default; explicit force mode     | Medium     |
| AGENTS/policy drift across three tools  | Medium   | High       | Anchor-based regression assertions                  | High       |
| Prompt module render failure            | Low      | Medium     | `starship` custom command degrades silently         | High       |
| Path collision at `.worktrees/<branch>` | Medium   | Medium     | Collision detection + descriptive fail-fast message | High       |

## Machine-Checkable Anchors

The following anchors are mandatory for regression tests:

| Anchor                                                           | File                                                                                                  | Check Pattern                       |
| ---------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- | ----------------------------------- |
| `.worktrees/`                                                    | `.gitignore`                                                                                          | `assert_file_contains`              |
| `Worktree Gate (L2+)`                                            | `dot_claude/CLAUDE.md.tmpl`, `dot_codex/AGENTS.md.tmpl`, `private_dot_config/opencode/AGENTS.md.tmpl` | `assert_file_contains`              |
| `wt-new()`                                                       | `dot_custom/functions.sh`                                                                             | function signature grep/assert      |
| `Path collision:` / `Nested worktree creation is not supported.` | `dot_custom/functions.sh`                                                                             | `assert_file_contains`              |
| Shared worktree command doc                                      | `dot_agents/commands/core`                                                                            | file exists + projection assertions |

## Compatibility Notes

- `ghq` + `tmux` integration remains unchanged in scope of this change. Session rename behavior continues to follow current `dev()` semantics.
- OpenCode background-task execution/runtime model is not changed by this change. Worktree workflow remains shell-path driven.
- If users manually enable disabled OpenCode agents/plugins, resulting behavior is outside this change scope; baseline guarantees apply only to managed default configuration.

## Validation Plan

- Run `bash tests/test_opencode_config_rendering.sh` to validate template assertions.
- Run `bash tests/test_manage_list_logic.sh` to ensure manage scripts still behave.
- Validate shared command projection contains new worktree command entry.
- Run `openspec validate worktree-first-ai-workflow` to validate artifact completeness.
