# /worktree - Worktree Workflow Guide

Standardize workspace isolation for implementation tasks across Claude, Codex, and OpenCode.

## Policy

- Default model: `one-task-one-branch-one-worktree`.
- Start implementation tasks in a dedicated worktree under `.worktrees/<branch>` when isolation helps preserve rollback clarity.
- Small deterministic updates may remain in the main workspace when isolation overhead is unnecessary.

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
