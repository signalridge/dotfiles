# /worktree - Worktree Workflow Guide

Standardize workspace isolation for medium/large tasks across Claude, Codex, and OpenCode.

## Policy

- Default model: `one-task-one-branch-one-worktree`.
- For L2+ changes, start in a dedicated worktree under `.worktrees/<branch>`.
- L1 quick edits may remain in main workspace.

## Canonical Commands

- Create and enter: `wt-new <branch> [base-ref]`
- Jump to existing: `wt-go <branch-or-path>`
- List all: `wt-ls`
- Remove (confirmation-first): `wt-rm <branch-or-path>`
- Prune stale metadata: `wt-prune`

## Diagnostics

Run:

```bash
git worktree list
git check-ignore -v .worktrees
```

## Boundaries

- This command is guidance-oriented and does not directly change your shell CWD by itself.
- Use shell-level `wt-*` commands for actual directory switching.
- Avoid force removal unless explicitly requested and risk is understood.
