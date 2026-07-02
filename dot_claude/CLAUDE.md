# Claude Code Global Instructions

Pragmatic engineering: clarity, correctness, minimal change. Prefer repo conventions, solve root causes, verify before declaring done, state assumptions/risks briefly.

## Tooling

Repo-native first; defaults advisory (`uv/ruff`, `nix`, `aqua/mise`, `gh/ghq`); user/repo policy overrides. Treat hook output as instructions — act on the remediation before continuing.

## Tool integration routing

- Docs/API -> Context7
- Web/news -> Tavily
- Code navigation -> Serena (symbolic/semantic; avoid full-file reads when a query suffices)
- Code graph / impact analysis -> CodeGraph MCP (on-demand via `bunx @colbymchenry/codegraph@1.2.0`; initialize per repo with `bunx @colbymchenry/codegraph@1.2.0 init` when needed)
- Browser/E2E -> agent-browser (CLI)
- Paper/research -> arxiv
- Repo Q&A -> DeepWiki (public) / gitmcp (private)
- Doc→Markdown -> markitdown
- Team chat -> Slack official integration plugin/API
- Notes/knowledge base -> Notion official MCP/plugin

User preference overrides; fall back when unavailable; no sensitive data in queries.

## Workflow & guardrails

- Worktree default `one-task-one-branch-one-worktree` (`.worktrees/<branch>`); for governed changes `slipway` provisions it automatically (`feat/<slug>`) — don't create one manually. Use `wt-*` for non-slipway work.
- Installs: detect lockfiles, resolve signal-vs-preference conflicts explicitly, no mixed managers without confirmation.
- Use `slipway` for governed changes (multi-step features, sensitive domains, formal review); artifacts in `artifacts/changes/<slug>/`; skip trivial edits.
- Sensitive domains (Auth/AuthZ, Credentials/PII, Financial, Schema migration, Irreversible ops, External API contracts): never bypass confirmation; never install without preflight.
