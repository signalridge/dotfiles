## 1. OpenSpec Artifacts

- [x] 1.1 Create proposal, design, and delta specs for `worktree-first-ai-workflow`.
- [x] 1.2 Capture L3+ pre-analysis in `design.md` with similar patterns, dependencies, conventions, and risk areas.

## 2. Repository Worktree Baseline

- [x] 2.1 Add `.worktrees/` to repository `.gitignore`.
- [x] 2.2 Ensure shell-facing guidance references `.worktrees/` as canonical local path.

## 3. Prompt Visibility (Scheme 1)

- [x] 3.1 Add a managed `starship` custom module to display current worktree context when inside `.worktrees/*`.
- [x] 3.2 Keep prompt output stable and non-intrusive (no output outside worktree paths).
- [x] 3.3 Add test assertions that prompt config contains worktree indicator anchors.
- [x] 3.4 Ensure prompt module degrades safely for non-standard worktree paths (no render errors, optional hidden indicator).

## 4. Worktree Helper Commands

- [x] 4.1 Add `wt-new` helper to create/switch worktrees under `.worktrees/<branch>`.
- [x] 4.2 Add `wt-go` helper to jump to existing worktrees.
- [x] 4.3 Add `wt-ls` helper to list worktrees.
- [x] 4.4 Add `wt-rm` helper with explicit confirmation by default.
- [x] 4.5 Add `wt-prune` helper to prune stale worktree metadata.
- [x] 4.6 Handle `wt-new` target path collisions gracefully (descriptive error when existing path is not current-repo worktree).

## 5. Cross-Tool Shared Command Layer (Scheme 3, unified)

- [x] 5.1 Add shared `worktree` command documentation under `dot_agents/commands/core/` (single source of truth).
- [x] 5.2 Ensure command projection surfaces this command across Claude/Codex/OpenCode command paths.
- [x] 5.3 Avoid OpenCode-only `wt-switch` behavior that cannot reliably change user shell CWD.
- [x] 5.4 Keep shared command wording strictly guidance-oriented (no claims of direct shell CWD switching).

## 6. Policy Templates

- [x] 6.1 Add `Worktree Gate (L2+)` guidance to `dot_claude/CLAUDE.md.tmpl`.
- [x] 6.2 Add `Worktree Gate (L2+)` guidance to `dot_codex/AGENTS.md.tmpl`.
- [x] 6.3 Add `Worktree Gate (L2+)` guidance to `private_dot_config/opencode/AGENTS.md.tmpl`.

## 7. Tests

- [x] 7.1 Add/adjust test assertions for `.worktrees/` ignore baseline.
- [x] 7.2 Add/adjust test assertions for prompt worktree indicators in managed starship config.
- [x] 7.3 Add/adjust test assertions for worktree gate anchors in AGENTS templates.
- [x] 7.4 Add/adjust test assertions for shared cross-tool worktree command projection anchors.
- [x] 7.5 Add explicit machine-checkable anchor assertions listed in `design.md` (files + patterns).
- [x] 7.6 Add coverage for `wt-new` collision handling behavior.

## 8. Verification

- [x] 8.1 Run `bash tests/test_opencode_config_rendering.sh`.
- [x] 8.2 Run `bash tests/test_manage_list_logic.sh`.
- [x] 8.3 Run `bash tests/run.sh`.
- [x] 8.4 Run `openspec validate worktree-first-ai-workflow`.
