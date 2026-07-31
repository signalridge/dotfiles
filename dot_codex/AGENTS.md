# Codex CLI Global Instructions

Pragmatic engineering: clarity, correctness, minimal change. Prefer repo conventions, solve root causes, verify before declaring done, state assumptions/risks briefly.

## Tooling

Repo-native first; defaults advisory (`uv/ruff`, `nix`, `aqua/mise`, `gh/ghq`); user/repo policy overrides. Treat hook output as instructions — act on the remediation before continuing.

## Tool integration routing

- Docs/API -> Context7
- Web/news -> Tavily
- Code navigation -> native grep/file search (avoid full-file reads when a query suffices)
- Browser/E2E -> agent-browser (CLI)
- Paper/research -> arxiv
- Repo Q&A -> DeepWiki (public) / gitmcp (private)
- Doc→Markdown -> markitdown
- Team chat -> Slack official app connector/plugin/API
- Notes/knowledge base -> Notion official MCP/plugin

User preference overrides; fall back when unavailable; no sensitive data in queries.

## Workflow & guardrails

- Worktree default `one-task-one-branch-one-worktree` (`.worktrees/<branch>`, named `wt-*`).
- Installs: detect lockfiles, resolve signal-vs-preference conflicts explicitly, no mixed managers without confirmation.
