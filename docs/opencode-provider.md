# OpenCode Provider Tools

Manage `OpenCode` + `oh-my-opencode` with the same `manage/with/token` workflow used by existing AI tooling, while keeping runtime strictly native (no Claude compatibility bridge).

## Overview

| Tool / Config                             | Purpose                                                                         | Managed By                                              |
| ----------------------------------------- | ------------------------------------------------------------------------------- | ------------------------------------------------------- |
| `opencode-manage`                         | Interactive account lifecycle (`switch/create/update/remove/test/list/current`) | `dot_local/bin/executable_opencode-manage.tmpl`         |
| `opencode-with`                           | Temporary account-scoped launch with runtime overrides                          | `dot_local/bin/executable_opencode-with.tmpl`           |
| `opencode-token`                          | API key + account config helper for wrappers                                    | `dot_local/bin/executable_opencode-token.tmpl`          |
| `~/.config/opencode/opencode.jsonc`       | OpenCode global model/provider/plugin/permission baseline                       | `private_dot_config/opencode/opencode.jsonc.tmpl`       |
| `~/.config/opencode/oh-my-opencode.jsonc` | oh-my-opencode orchestration defaults + guardrails                              | `private_dot_config/opencode/oh-my-opencode.jsonc.tmpl` |
| `~/.config/opencode/AGENTS.md`            | User-level global instruction baseline for OpenCode                             | `private_dot_config/opencode/AGENTS.md.tmpl`            |
| `opencodeProviderAccount`                 | Data-driven selector (`provider` or `provider@label`)                           | `~/.config/chezmoi/chezmoi.toml`                        |

## Daily Workflow

```bash
# Interactive account manager
opencode-manage

# Launch with temporary account context
opencode-with
opencode-with deepseek@private

# Token/config helper
opencode-token --config deepseek@private
opencode-token --check qwen@work

# One-shot readiness diagnostics
opencode-manage doctor
```

Aliases:

- `ocm` -> `opencode-manage`
- `ocw` -> `opencode-with`

## Account and Key Model

- Native providers (for example `openai`, `anthropic`, `google`) use OpenCode native auth flow (`opencode auth login <provider>`).
- Third-party providers use `gopass`-backed keys under:
  - `opencode/providers/{provider}/accounts/{base64url(label)}/api_key`
- Default account is controlled by `opencodeProviderAccount` in chezmoi data.

## Native-Only Runtime Policy

`oh-my-opencode` Claude compatibility ingestion is hard-disabled:

```json
"claude_code": {
  "mcp": false,
  "commands": false,
  "skills": false,
  "agents": false,
  "hooks": false,
  "plugins": false
}
```

Additional guardrails:

- `disabled_hooks` includes `"claude-code-hooks"`
- `sisyphus.tasks.claude_code_compat = false`
- `opencode-with` exports runtime isolation flags:
  - `OPENCODE_DISABLE_CLAUDE_CODE_PROMPT=1`
  - `OPENCODE_DISABLE_EXTERNAL_SKILLS=1`

This prevents implicit `~/.claude` prompt/skill ingestion and keeps runtime behavior deterministic.

Scope note (upstream behavior): OpenCode still has project instruction fallback (`AGENTS.md` then `CLAUDE.md`). Managed policy keeps `AGENTS.md` as the authoritative project instruction file.

## User-Level Instructions

OpenCode has native user-level instruction support via `AGENTS.md`:

- `~/.config/opencode/AGENTS.md` is loaded as a global instruction source.
- If `OPENCODE_CONFIG_DIR` is set, `OPENCODE_CONFIG_DIR/AGENTS.md` is preferred over global config dir `AGENTS.md`.
- Project-level `AGENTS.md` chain remains active when reading project files.

Managed `opencode.jsonc` also keeps explicit project instruction discovery:

- `AGENTS.md`
- `.opencode/AGENTS.md`

## Shared Skills and Commands Integration

OpenCode and oh-my-opencode are wired to shared repository assets without Claude compatibility bridge:

- OpenCode command projection uses a single hierarchical symlink (same pattern as Claude):
  - `~/.config/opencode/commands/core` -> `~/.agents/commands/core`
  - Commands are discovered as `core/commit`, `core/review`, etc. via OpenCode's native `{command,commands}/**/*.md` glob.
  - Flat compatibility aliases under `~/.config/opencode/command/` are intentionally not managed.
- OpenCode global skills are projected explicitly:
  - `~/.config/opencode/skills` -> `~/.agents/skills`
- OpenCode `skills.paths` keeps project-local overlay:
  - `.agents/skills`
- oh-my-opencode `skills.sources` is kept strict and recursive for project-local skills:
  - `{ "path": ".agents/skills", "recursive": true }`

This allows reuse of existing skill/command ecosystem across Claude/Codex/OpenCode stacks.

## Parity Matrix

Cross-tool parity status against current managed Claude Code/Codex workflow:

| Capability                                               | Claude Code               | Codex                     | OpenCode + oh-my                             | Status                                |
| -------------------------------------------------------- | ------------------------- | ------------------------- | -------------------------------------------- | ------------------------------------- |
| Account lifecycle (`manage/with/token`)                  | yes                       | yes                       | yes                                          | parity                                |
| Shell alias/completion (`ccm/ccw`, `cxm/cxw`, `ocm/ocw`) | yes                       | yes                       | yes                                          | parity                                |
| Wrapper diagnostics (`*-manage doctor`)                  | yes                       | yes                       | yes                                          | parity                                |
| Shared command source (`~/.agents/commands/core`)        | directory symlink         | flat prompt links         | directory symlink (same as Claude)           | parity                                |
| Shared skills source (`~/.agents/skills`)                | symlink                   | symlink                   | global projection + project recursive source | parity                                |
| Third-party provider families                            | broad                     | broad (includes `harui`)  | broad (includes `harui`)                     | parity                                |
| User-level instruction file                              | `~/.claude/CLAUDE.md`     | `~/.codex/AGENTS.md`      | `~/.config/opencode/AGENTS.md`               | parity                                |
| OpenSpec workflow availability                           | wrappers (when generated) | wrappers (when generated) | plugin + managed command ecosystem           | parity with tool-specific entrypoints |
| Runtime no-Claude isolation                              | n/a                       | n/a                       | enabled (`claude_code.*=false` + env flags)  | intentional delta                     |

## Community Patterns Review

Representative community sources reviewed (via `ghq` clone):

- `github.com/LEI/dotfiles`
- `github.com/matchai/dotfiles`
- `github.com/olisikh/.dotfiles`
- `github.com/htkr/opencode-agent-profiles`

Patterns accepted into managed defaults:

- explicit user-level `~/.config/opencode/AGENTS.md` baseline
- hierarchical command symlink (matching Claude's directory symlink pattern)
- explicit global skills projection + recursive project skills source
- dedicated diagnostics entrypoint and completion parity (`claude-manage/codex-manage/opencode-manage doctor`)

Patterns intentionally not adopted:

- enabling Claude compatibility ingestion paths
- broad `allow` defaults for risky permissions (`edit`, `bash`, `external_directory`)
- profile-switch scripts that replace managed templates at runtime
- hard pinning community-specific plugins outside current repository workflow

## Curated Advanced Profile

Managed templates pin a curated (not maximal) advanced profile:

- `opencode.jsonc`:
  - `instructions`
  - `default_agent`
  - `watcher.ignore`
  - `compaction`
- `oh-my-opencode.jsonc`:
  - explicit `sisyphus_agent` + `sisyphus.tasks`
  - category routing + selected `agents` overrides
  - explicit `background_task`, `tmux`, `websearch`, browser engine
  - explicit disable-control governance (`disabled_hooks` + selected `disabled_*`)
  - explicit `experimental` matrix

Pinned `experimental` policy:

```json
{
  "truncate_all_tool_outputs": false,
  "aggressive_truncation": false,
  "auto_resume": false,
  "preemptive_compaction": false,
  "dynamic_context_pruning": {
    "enabled": true,
    "notification": "detailed",
    "turn_protection": { "enabled": true, "turns": 4 },
    "strategies": {
      "deduplication": { "enabled": true },
      "supersede_writes": { "enabled": true, "aggressive": false },
      "purge_errors": { "enabled": true, "turns": 6 }
    }
  },
  "task_system": true,
  "plugin_load_timeout_ms": 15000,
  "safe_hook_creation": true
}
```

## Plugin Chain and OpenSpec

OpenCode plugin order is pinned:

```json
"plugin": ["oh-my-opencode", "opencode-plugin-openspec"]
```

This keeps oh-my orchestration active while enabling `openspec-plan` agent injection when OpenSpec project markers are detected.

## Permission Baseline

Sensitive operations default to confirmation (`ask`):

- `edit`
- `bash`
- `external_directory`
- `webfetch`
- `websearch`
- `codesearch`
- `lsp`
- `task`
- `skill`

## Diagnostics Quick Checks

```bash
# Render-level checks
jq '.default_agent, .watcher.ignore, .compaction' ~/.config/opencode/opencode.jsonc
jq '.claude_code, .disabled_hooks, .sisyphus.tasks, .experimental' ~/.config/opencode/oh-my-opencode.jsonc

# Runtime isolation checks (wrapper path)
opencode-with deepseek@private --help >/dev/null

# One-shot workflow diagnostics
opencode-manage doctor

# Verify command projection symlink
readlink ~/.config/opencode/commands/core

# Verify global skills projection
readlink ~/.config/opencode/skills

# Verify user-level AGENTS baseline
test -f ~/.config/opencode/AGENTS.md
```

## Installation Ownership (Aqua First)

As of `2026-02-15`, installation responsibility follows upstream distribution reality:

| Component                  | Upstream Distribution                                         | Managed By                                | Why                                               |
| -------------------------- | ------------------------------------------------------------- | ----------------------------------------- | ------------------------------------------------- |
| `opencode`                 | GitHub release binaries + npm platform packages               | `aqua` (`anomalyco/opencode`)             | Native binary workflow, declarative toolchain fit |
| `oh-my-opencode`           | npm package with platform binaries via `optionalDependencies` | `mise` npm backend (`npm:oh-my-opencode`) | Not currently in standard aqua registry           |
| `opencode-plugin-openspec` | OpenCode plugin package                                       | OpenCode plugin chain                     | Runtime plugin fetch, no standalone binary        |

Current managed pins:

- `anomalyco/opencode@v1.2.4` (aqua)
- `npm:oh-my-opencode@3.5.5` (mise)

Latest upstream releases verified from GitHub API (`2026-02-15`):

- `anomalyco/opencode`: `v1.2.4` (published `2026-02-15T01:55:46Z`)
- `code-yeongyu/oh-my-opencode`: `v3.5.5` (published `2026-02-15T05:49:32Z`)

If standard aqua registry ever lags for a required version, keep `opencode` on aqua by adding a local/custom registry entry instead of moving back to ad-hoc installer scripts.

## Configuration Paths

Managed paths remain:

- `private_dot_config/opencode/opencode.jsonc.tmpl` -> `~/.config/opencode/opencode.jsonc`
- `private_dot_config/opencode/oh-my-opencode.jsonc.tmpl` -> `~/.config/opencode/oh-my-opencode.jsonc`
- `private_dot_config/opencode/commands/symlink_core.tmpl` -> `~/.config/opencode/commands/core`
- `private_dot_config/opencode/symlink_skills.tmpl` -> `~/.config/opencode/skills`

These are intentionally not merged into Claude/Codex config directories to keep OpenCode runtime boundaries explicit.
