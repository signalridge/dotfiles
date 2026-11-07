{{- /* Shared global agent instructions. Rendered by dot_claude/CLAUDE.md.tmpl
       and dot_codex/AGENTS.md.tmpl via
       {{ template "agent-instructions.md" dict "harness" "<claude|codex>" }}. */ -}}
{{- $h := .harness -}}
# {{ get (dict "claude" "Claude Code" "codex" "Codex CLI") $h }} Global Instructions

Pragmatic engineering: clarity, correctness, minimal change. Prefer repo conventions, solve root causes, verify before declaring done, state assumptions/risks briefly.

## Tooling

Repo-native first; defaults advisory (`uv/ruff`, `nix`, `aqua/mise`, `gh/ghq`); user/repo policy overrides. Treat hook output as instructions — act on the remediation before continuing.

## Tool integration routing

- Docs/API -> Context7
- Web/news -> Tavily
{{ if eq $h "claude" -}}
- Code navigation -> native Grep/Glob + Explore subagent (avoid full-file reads when a query suffices)
{{ else -}}
- Code navigation -> native grep/file search (avoid full-file reads when a query suffices)
{{ end -}}
- Browser/E2E -> agent-browser (CLI)
- Paper/research -> arxiv
- Repo Q&A -> DeepWiki (public) / gitmcp (private)
- Doc→Markdown -> markitdown
{{ if eq $h "claude" -}}
- Team chat -> Slack official integration plugin/API
{{ else if eq $h "codex" -}}
- Team chat -> Slack official app connector/plugin/API
{{ end -}}
- Notes/knowledge base -> Notion official MCP/plugin

User preference overrides; fall back when unavailable; no sensitive data in queries.

## Local CLI toolbelt

All installed (aqua/mise/nix). Prefer these over POSIX defaults — don't fall back to `grep`/`find`/`sed` out of habit:

- text search -> `rg`; structural/AST search & rewrite -> `ast-grep` (`sg`)
- file search -> `fd`
- JSON / YAML / multi-format -> `jq` / `yq` / `dasel`
- in-place edit -> `sd` (literal by default; avoids `sed -i` escaping)
- diff -> `difft` (syntax-aware), `delta` (git pager)
- code stats -> `tokei`
- HTTP -> `xh`; load test -> `oha`; DNS -> `doggo`
- disk / process -> `dust`, `duf`, `procs`, `btop`
- benchmark -> `hyperfine`; watch & rerun -> `watchexec`; job queue -> `pueue`
- task runner -> `just`

Full inventory (VCS, k8s, security, media, docs): `~/.harnesses/skills/dev/toolbelt/SKILL.md`.

## Repository guardrails

- In `~/.local/share/chezmoi`, never run `git worktree add`, `git switch`, or
  `git checkout -b`. The live source is the shared `main` checkout; edit it directly.
- Never read or reuse browser cookies, browser profiles, password stores, or signed-in
  web sessions for model/search authentication. Never use private AI endpoints.

## Workflow & guardrails

- Worktree isolation is repository-controlled. Outside chezmoi, follow the target
  repository's policy; inside chezmoi, the no-worktree rule above always wins.
- Installs: detect lockfiles, resolve signal-vs-preference conflicts explicitly, no mixed managers without confirmation.
