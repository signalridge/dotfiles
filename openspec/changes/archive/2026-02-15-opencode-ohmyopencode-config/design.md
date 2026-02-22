## Pre-Analysis

- **Similar patterns**:
  - `dot_claude/commands/symlink_core.tmpl`
  - `dot_codex/prompts/symlink_core-*.md.tmpl`
  - `dot_claude/symlink_skills.tmpl`, `dot_codex/symlink_skills.tmpl`
  - `dot_local/bin/executable_{claude,codex}-manage.tmpl` and companion wrappers
- **Dependencies**:
  - `private_dot_config/opencode/opencode.jsonc.tmpl`
  - `private_dot_config/opencode/oh-my-opencode.jsonc.tmpl`
  - `dot_local/bin/lib/ai/core.tmpl`, `dot_local/bin/lib/ai/opencode.tmpl`
  - `dot_local/bin/executable_opencode-{manage,with,token}.tmpl`
  - `dot_custom/alias.sh`, `dot_custom/functions.sh`
- **Conventions**:
  - account format: `provider` or `provider@label`
  - key path: tool-scoped `gopass` namespace
  - commands source-of-truth: `dot_agents/commands/core`
  - skills source-of-truth: `~/.agents/skills`
- **Risk areas**:
  - upstream schema drift
  - strict runtime isolation hiding unmanaged assets
  - docs/tests claiming parity without proving runtime operability

## Context

### Upstream constraints (docs + source)

1. OpenCode has layered config precedence and rich top-level config surface.
2. OpenCode loads commands/skills from native paths (`command(s)`, `skill(s)`, `skills.paths`).
3. `OPENCODE_DISABLE_EXTERNAL_SKILLS` disables external `.claude`/`.agents` scanning.
4. oh-my-opencode `claude_code.commands/skills=false` only disables Claude-source ingestion; OpenCode-source loading still exists.
5. oh-my-opencode schema exposes high-value operational controls beyond baseline config (`agents`, `categories`, `disabled_*`, `sisyphus`, `background_task`, `experimental`).
6. oh-my-opencode `experimental` is broad and potentially high-impact; each field requires explicit policy decisions instead of implicit defaults.

## Design Principles

- **Coverage-first**: include all high-value operational features required for parity.
- **No over-design**: avoid speculative knobs without clear repo benefit.
- **Determinism-first**: explicit managed paths over implicit discovery.
- **Testability-first**: each behavior in scope must have a concrete validation path.

## Feature Selection Rule

A config feature is included only if it meets all of:

1. Stable in upstream schema/source.
2. Improves reliability/security/workflow ergonomics.
3. Fits existing repository conventions.
4. Can be tested in this repository.

## Decisions

1. **OpenCode config ownership stays explicit**
   - Keep managed path: `private_dot_config/opencode/*` -> `~/.config/opencode/*`.

2. **Adopt curated native config profile (not maximal profile)**
   - Keep baseline fields and add selected operational fields:
     - `instructions`
     - `default_agent`
     - `watcher.ignore`
     - `compaction`
     - policy fields that improve day-2 operations

3. **Add explicit OpenCode-native command projection**
   - Keep a layered command mirror under `~/.config/opencode/commands/` (Claude-style directory symlink pattern).
   - Avoid separate flat compatibility aliases under `~/.config/opencode/command/` to reduce projection drift.

4. **Add explicit OpenCode skill projection/path wiring**
   - Project global shared skills into `~/.config/opencode/skills`.
   - Keep project `.agents/skills` via recursive oh-my source configuration for deterministic nested discovery.

5. **Retain no-Claude runtime policy with operability guarantees**
   - Keep no-Claude prompt isolation and compatibility toggles disabled.
   - Keep strict mode behavior only with managed projection coverage.

6. **Use oh-my features deliberately**
   - Expand only high-value sections: `categories`, `agents`, `background_task`, `tmux`, `websearch`, `notification`, selected `disabled_*` controls.

7. **Codify explicit oh-my advanced policy (not best-effort defaults)**
   - Use a managed profile for:
     - orchestration (`sisyphus_agent`, `sisyphus.tasks`),
     - category/agent behavior (`categories`, selected `agents` overrides),
     - operational controls (`background_task`, `tmux`, browser/websearch),
     - guardrails (`disabled_hooks` and selected `disabled_*` governance).

8. **Pin user-confirmed experimental matrix**
   - The managed profile SHALL set:
     - `truncate_all_tool_outputs=false`
     - `aggressive_truncation=false`
     - `auto_resume=false`
     - `preemptive_compaction=false`
     - `dynamic_context_pruning.enabled=true`
     - `dynamic_context_pruning.notification="detailed"`
     - `dynamic_context_pruning.turn_protection.enabled=true`
     - `dynamic_context_pruning.turn_protection.turns=4`
     - `dynamic_context_pruning.strategies.deduplication.enabled=true`
     - `dynamic_context_pruning.strategies.supersede_writes.enabled=true`
     - `dynamic_context_pruning.strategies.supersede_writes.aggressive=false`
     - `dynamic_context_pruning.strategies.purge_errors.enabled=true`
     - `dynamic_context_pruning.strategies.purge_errors.turns=6`
     - `task_system=true`
     - `plugin_load_timeout_ms=15000`
     - `safe_hook_creation=true`

9. **Add wrapper-level diagnostics expectations**
   - Operators must be able to verify readiness of account/auth, key path, command/skill visibility, and plugin chain state.

10. **Make user-level instruction entrypoints explicit**

- OpenCode user-level instruction path (`~/.config/opencode/AGENTS.md`) and precedence behavior (`OPENCODE_CONFIG_DIR`) must be documented and testable in workflow guidance.

11. **Use community configs as validation input, not as direct policy source**

- Review representative community OpenCode/oh-my setups for missed capabilities.
- Accept only patterns consistent with repository guardrails (no-Claude runtime boundary, deterministic loading, testable behavior).
- Record accepted/rejected patterns in docs to keep future updates auditable.

12. **Keep provider-family parity with existing Claude/Codex account surface**

- Managed OpenCode provider map must cover third-party families already used in repository wrappers/configs.
- Model fallback and env/baseURL mappings must remain deterministic for those families.

13. **Document no-Claude scope against upstream instruction behavior**

- Runtime guardrails block implicit `~/.claude` prompt/skill ingestion.
- Upstream project instruction fallback (`AGENTS.md` then `CLAUDE.md`) remains a known behavior; managed policy keeps `AGENTS.md` authoritative.

14. **Keep three-tool diagnostics parity command-complete**

- Completion exposure and implemented subcommands must stay aligned across `claude-manage`, `codex-manage`, and `opencode-manage`.
- `doctor` is treated as a first-class day-2 workflow for all three wrappers.

15. **Use dot_agents as shared asset boundary, not runtime config boundary**

- Shared assets (commands/skills/policies) may be centralized under `dot_agents` or `~/.agents`.
- Tool runtime configs remain explicitly split (`~/.claude`, `~/.codex`, `~/.config/opencode`) to avoid cross-tool leakage.

16. **Track upstream release cadence explicitly for install policy**

- Managed pins should track latest known stable upstream releases where feasible.
- If aqua standard registry lags a required OpenCode version, prefer aqua custom/local registry extension over ad-hoc installer scripts.

## Architecture

### 1) Configuration layers

- `opencode.jsonc`: OpenCode core behavior, provider/model/policy, command/skill/plugin/mcp integration.
- `oh-my-opencode.jsonc`: orchestration strategy and no-Claude guardrails.
- wrapper runtime overlay (`opencode-with`): account-scoped launch and runtime policy flags.

### 1.1) oh-my advanced profile groups

- `orchestration`: `sisyphus_agent`, `sisyphus.tasks`, category/agent routing.
- `operability`: `background_task`, `tmux`, `notification`, `websearch`, browser engine.
- `policy`: `disabled_hooks` and selected `disabled_*` controls.
- `experimental`: explicit field-by-field managed decisions.

### 2) Asset projection model

- Source-of-truth remains:
  - commands: `dot_agents/commands/core`
  - skills: `~/.agents/skills`
- OpenCode command projection uses layered path only:
  - layered mirror (`commands/`)
- OpenCode and oh-my skill discovery is split by responsibility:
  - global shared skills via managed `~/.config/opencode/skills`
  - project shared skills via recursive `.agents/skills` source

### 3) Workflow parity model

- Keep `opencode-manage/with/token` as first-class operator interface.
- Preserve native-provider auth vs third-party gopass split.
- Keep alias/completion parity with Claude/Codex conventions.

### 4) Cross-tool abstraction model

- Shared layer:
  - `dot_agents/commands/core`
  - `~/.agents/skills`
  - shared governance principles mirrored into tool-local AGENTS/CLAUDE docs
- Tool-local layer:
  - Claude: `~/.claude/*`
  - Codex: `~/.codex/*`
  - OpenCode: `~/.config/opencode/*`
- Parity rule:
  - UX-level primitives (aliases/completion/manage lifecycle/doctor) should align unless a documented tool-specific constraint requires divergence.

## Risks / Trade-offs

- **Schema drift**: mitigated by explicit render + behavior tests.
- **Strict mode regressions**: mitigated by projection-first design and diagnostics checks.
- **no-Claude scope confusion**: mitigated by explicit docs on what is blocked vs upstream fallback behavior.
- **Config sprawl**: mitigated by selection rule and curated field set.
- **Experimental instability**: mitigated by explicit matrix pinning and test assertions.
- **`task_system=true` behavioral variance**: mitigated by no-Claude guardrails + workflow tests + docs caveats.

## Migration Plan

1. Rebaseline spec to curated full-scope model.
2. Implement command/skill projection and template updates.
3. Extend wrapper diagnostics.
4. Update docs and tests.
5. Validate with full test and OpenSpec validation.

## Resolved Choices

- Keep strict skill isolation as default.
- Keep no-Claude policy explicit and always-on for managed OpenCode wrappers.
- Allow `dynamic_context_pruning` and `task_system` under explicit pinned configuration and verification coverage.
