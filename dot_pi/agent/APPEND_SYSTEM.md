# Pi Coding Agent Global Instructions

Pragmatic engineering: clarity, correctness, minimal change. Prefer repo conventions, solve root causes, verify before declaring done, state assumptions/risks briefly.

## Tooling

Repo-native first; defaults advisory (`uv/ruff`, `nix`, `aqua/mise`, `gh/ghq`); user/repo policy overrides. Treat hook output as instructions — act on the remediation before continuing.

## Tool integration routing

MCP tools are provided by the `pi-mcp-adapter` extension; servers are configured in `~/.pi/agent/mcp.json`.

- Docs/API -> Context7
- Web/news -> pi-web-access `web_search`; Research for multi-step sourced work, including when sources conflict
- Web content extraction -> pi-web-access `fetch_content`/`get_search_content`; repository content -> DeepWiki/gitmcp
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

## Authentication safety

- Built-in OpenAI Codex OAuth is allowed.
- Never read or reuse browser cookies, browser profiles, password stores, or signed-in web sessions for model or search authentication. Never use reverse-engineered/private AI web endpoints.
- Do not install or configure Pi extensions that provide those capabilities. Web research must use API/MCP providers; ordinary browser/E2E work does not authorize access to signed-in AI websites.

## Local CLI toolbelt

All installed (aqua/mise/nix). Prefer these over POSIX defaults — don't fall back to `grep`/`find`/`sed` out of habit. hypa rewrites shell/grep/find transparently, so name the tool you actually want:

- text search -> `rg`; structural/AST search & rewrite -> `ast-grep` (`sg`)
- file search -> `fd`
- JSON / YAML / multi-format -> `jq` / `yq` / `dasel`
- in-place edit -> `sd` (literal by default; avoids `sed -i` escaping)
- diff -> `difft` (syntax-aware), `delta` (git pager)
- code stats -> `tokei`
- HTTP -> `xh`; load test -> `oha`; DNS -> `doggo`
- disk / process -> `dust`, `duf`, `procs`, `btm`
- benchmark -> `hyperfine`; watch & rerun -> `watchexec`; job queue -> `pueue`
- task runner -> `just`

Full inventory (VCS, k8s, security, media, docs): `~/.harnesses/skills/dev/toolbelt/SKILL.md`.

## Workflow & guardrails

- Route an already-bounded code change to Implement; use general-purpose only when investigation and execution are genuinely inseparable.
- The host may pass one of the catalogue keys shown in the Agent tool description as `tier` on an Agent call for deliberate routing. If omitted, `agentTiers.defaultTier` applies; the agent inherits the parent only when no default tier is configured. A passed key selects a named profile; `model` and `thinking` are not callable parameters.
- Agent runs are bounded by the repository defaults `defaultMaxTurns: 80`, `defaultMaxToolCalls: 300`, and `graceTurns: 5`; omit `max_turns` so those defaults apply. Only request a smaller explicit `max_turns` for unusually narrow tasks; never pass `0` or a larger value to disable or weaken the safety budget.
- Use dynamic workflows for broad decomposable work that benefits from parallel independent evidence, not routine edits. Keep one writer in a shared checkout, use the configured token budget, and do not nest Agent delegation inside workflow children.
- Worktree default is `one-task-one-branch-one-worktree` (`.worktrees/<branch>`, named `wt-*`) only when applicable repository instructions allow it. Any repository prohibition wins. The chezmoi source tree forbids all worktrees and branch switching; never request workflow `isolation: "worktree"` there.
- Installs: detect lockfiles, resolve signal-vs-preference conflicts explicitly, no mixed managers without confirmation.
