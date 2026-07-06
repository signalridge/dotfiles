# Pi Coding Agent Global Instructions

Pragmatic engineering: clarity, correctness, minimal change. Prefer repo conventions, solve root causes, verify before declaring done, state assumptions/risks briefly.

## Tooling

Repo-native first; defaults advisory (`uv/ruff`, `nix`, `aqua/mise`, `gh/ghq`); user/repo policy overrides. Treat hook output as instructions — act on the remediation before continuing.

## Tool integration routing

MCP tools are provided by the `pi-mcp-adapter` extension; servers are configured in `~/.pi/agent/mcp.json`.

- Docs/API -> Context7
- Web/news, deep research -> Tavily (single searches; scout/researcher subagents for multi-step)
- Web content fetch (PDF/GitHub/YouTube/local-video) -> pi-web-access `fetch_content`
- Code navigation, semantic -> Serena (MCP; symbol/reference queries — avoid full-file reads)
- Code navigation, in-Pi -> readseek (hash-anchored read/edit/grep + structural maps; no MCP round-trip)
- Long-context / evidence compression -> hypa (rewrites shell/read/grep/find/ls, proxies MCP)
- Browser/E2E -> agent-browser (CLI)
- Repo Q&A -> DeepWiki (public) / gitmcp (private)
- Notes/knowledge base -> Notion official MCP/plugin when available

Code-nav layering: serena for semantic "who calls / where defined" across the repo;
readseek for safe hash-anchored edits and local structural maps; hypa when context is
large. They complement — don't invoke all three for one lookup.

User preference overrides; fall back when unavailable; no sensitive data in queries.

## Workflow & guardrails

- Worktree default `one-task-one-branch-one-worktree` (`.worktrees/<branch>`); for governed changes `slipway` provisions it automatically (`feat/<slug>`) — don't create one manually. Use `wt-*` for non-slipway work.
- Installs: detect lockfiles, resolve signal-vs-preference conflicts explicitly, no mixed managers without confirmation.
- Use `slipway` for governed changes (multi-step features, sensitive domains, formal review); artifacts in `artifacts/changes/<slug>/`; skip trivial edits.
- Sensitive domains (Auth/AuthZ, Credentials/PII, Financial, Schema migration, Irreversible ops, External API contracts): never bypass confirmation; never install without preflight.

## Subagent delegation (proactive)

Actively delegate to `subagent` (pi-subagents) instead of doing everything inline
in the main loop. Reach for a subagent by default when the work fits one of these:

- Cross-file / cross-directory recon where only the conclusion is needed -> `scout`
  or `context-builder` (they read excerpts and return findings, not full dumps).
- Reviewing a diff or code quality -> fresh-context `reviewer` (adversarial review,
  file/line evidence, does NOT edit files unless explicitly asked).
- Multi-step external research -> `researcher`, paired with `scout` for local code
  context; combine when a question spans web evidence + repo state.
- Multiple independent, non-conflicting tasks -> run them as parallel `subagent`
  tasks rather than serially.

Principles: parallelize when tasks are independent; use fresh context for review;
do writes with a single `worker` only when implementation is explicitly requested
(never several writers in one worktree); make cost visible via a normal
`subagent(...)` call, not hidden background automation. Skip delegation for trivial
or single-point questions, direct commands, highly private requests, or when the
user asks not to delegate — then just do it yourself.
