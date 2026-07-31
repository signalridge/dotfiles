# Pi Coding Agent Global Instructions

Pragmatic engineering: clarity, correctness, minimal change. Prefer repo conventions, solve root causes, verify before declaring done, state assumptions/risks briefly.

## Tooling

Repo-native first; defaults advisory (`uv/ruff`, `nix`, `aqua/mise`, `gh/ghq`); user/repo policy overrides. Treat hook output as instructions — act on the remediation before continuing.

## Tool integration routing

MCP tools are provided by the `pi-mcp-adapter` extension; servers are configured in `~/.pi/agent/mcp.json`.

- Docs/API -> Context7
- Web/news, deep research -> Tavily (single searches; general-purpose subagent for multi-step)
- Web content fetch (PDF/GitHub/YouTube/local-video) -> pi-web-access `fetch_content`
- Code navigation -> readseek (hash-anchored read/edit/grep + structural maps; no MCP round-trip)
- Long-context / evidence compression -> hypa (rewrites shell/read/grep/find/ls, proxies MCP)
- Browser/E2E -> agent-browser (CLI)
- Repo Q&A -> DeepWiki (public) / gitmcp (private)
- Paper/research -> arxiv
- Doc→Markdown -> markitdown
- Notes/knowledge base -> Notion official MCP/plugin when available

Code-nav layering: readseek for "who calls / where defined", safe hash-anchored edits and
local structural maps; hypa when context is large. They complement — don't invoke both
for one lookup.

User preference overrides; fall back when unavailable; no sensitive data in queries.

## Workflow & guardrails

- Worktree default `one-task-one-branch-one-worktree` (`.worktrees/<branch>`, named `wt-*`).
- Installs: detect lockfiles, resolve signal-vs-preference conflicts explicitly, no mixed managers without confirmation.
