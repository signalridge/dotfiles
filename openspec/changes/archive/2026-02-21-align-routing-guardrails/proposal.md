## Why

Validated review against local OpenSpec source and latest upstream docs (Codex, OpenCode, oh-my-opencode, Claude) shows several material mismatches in the current change definition:

- Guardrails parity is incomplete: Codex/OpenCode still use generic risk labels while Claude binds L3+ risk checks to `context/guardrails.md`.
- Guardrail path closure is missing: this repo currently ships `dot_claude/context/guardrails.md`; direct `context/guardrails.md` references in Codex/OpenCode are unresolved unless a shared path is provisioned.
- OpenCode command-surface guidance is ambiguous across versions: OpenSpec currently generates `.opencode/command/opsx-*.md`, while latest OpenCode docs emphasize `.opencode/commands` and `~/.config/opencode/commands`.
- `spec-verify` template currently uses incorrect OpenSpec CLI syntax (`openspec validate --changes <change-name>`).
- OpenSpec artifacts are currently excluded from Git by repository `.gitignore` (`openspec/`), so lifecycle artifacts are not version-controlled, weakening spec-first auditability.
- Codex doctor currently checks only `core-*.md` prompt projection and does not verify `opsx-*` wrapper readiness.
- Guardrails requirements are not yet machine-testable enough (missing stable anchor terms/sections for deterministic assertions).
- Tavily-first search policy is currently instruction-level consistent but runtime-level inconsistent:
  - Codex/Claude policy text says "Tavily MCP first".
  - Codex has `mcp_servers.tavily` configured and Claude reports Tavily MCP connectivity.
  - OpenCode currently reports no configured MCP servers (`opencode mcp list`) while oh-my-opencode websearch path is Exa-oriented.
- OpenCode subagent routing can unexpectedly fall to GLM defaults:
  - oh-my-opencode upstream defaults `librarian` to `zai-coding-plan/glm-4.7` provider chain.
  - Local managed `oh-my-opencode.jsonc` does not explicitly override `librarian`/`explore`/`oracle` model routes.
- `No assistant or tool response found` is an execution-channel symptom in oh-my-opencode task formatting (empty assistant/tool message stream), and must be treated as a routing/execution diagnostic signal rather than a successful business response.
- Latest tool docs confirm governance-boundary differences that must be reflected in policy text:
  - Claude hooks support deterministic runtime enforcement (`allow` / `ask` / `deny`).
  - Codex AGENTS docs define instruction-chain governance (local/parent/home), not Claude-style runtime hook gating.
  - OpenCode rules/config docs define AGENTS + `CLAUDE.md` fallback and multi-scope config precedence.
- Runtime enforcement boundary wording is imprecise:
  - Claude has explicit runtime hook scripts and blocking/ask semantics.
  - Codex has limited hook capability (notify-oriented), not Claude-equivalent multi-event policy gating.
  - OpenCode strict mode disables Claude hook bridge, but AGENTS -> CLAUDE fallback remains available unless explicitly disabled.

These gaps produce inconsistent L3/L4 routing and weaken policy auditability for sensitive changes.

## What Changes

- Add explicit Guardrails sections to Codex/OpenCode AGENTS policy so sensitive domains and required post-change reporting are consistently enforced at instruction level.
- Align L3+ Pre-Analysis risk checklist in Codex/OpenCode with guardrails-triggered review workflow used by Claude.
- Close guardrail reference paths by defining a resolvable canonical guardrails source for Codex/OpenCode policy text.
- Add explicit runtime-capability boundary policy for Codex/OpenCode (what is hard-enforced vs instruction-enforced) using accurate tool-capability wording.
- Document OpenCode strict-mode fallback boundary, including when `OPENCODE_DISABLE_CLAUDE_CODE=1` is required for full CLAUDE fallback isolation.
- Clarify OpenSpec wrapper/prompt authority and sync ownership across Claude, Codex, and OpenCode to reduce prompt-drift confusion.
- Add explicit OpenCode command-path compatibility guidance for `.opencode/command` and `.opencode/commands` surfaces.
- Add explicit Tavily MCP-first routing requirements across Claude/Codex/OpenCode, including runtime readiness checks and fallback boundary wording.
- Clarify OpenCode Tavily-vs-Exa search boundary so policy intent and runtime defaults cannot silently diverge.
- Add explicit OpenCode subagent model-route overrides for `librarian`/`explore`/`oracle` (or explicit opt-in exception policy) to prevent unintended GLM fallback routes.
- Add execution diagnostics guidance for empty subagent responses (`No assistant or tool response found`), including background-mode usage expectation for `explore`/`librarian` and retry/escalation rules.
- Add explicit repository policy for OpenSpec artifact versioning with a documented default local-only mode (`openspec/` ignored by default) and clear opt-in tracking path.
- Harden Codex doctor diagnostics to include OpenSpec wrapper readiness checks (opsx prompt coverage), not only core prompt projection.
- Make Guardrails requirements machine-verifiable in specs/policy (fixed section title + fixed sensitive-category anchors + fixed high-risk operation wording).
- Keep Sisyphus planner-toggle cleanup as an auditability improvement when `sisyphus_agent.disabled=true` (not treated as a functional blocker).
- Unify opsx command syntax references across AGENTS policy files: Codex/OpenCode AGENTS SHALL use hyphen form (`/opsx-*`) consistently, matching their actual prompt file naming, and explicitly note the Claude colon-form (`/opsx:*`) difference only in cross-tool disambiguation sections.
- Fix OpenCode `spec-verify` command template to use correct `openspec validate` positional argument syntax for single-change verification.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `codex-config-enhancements`: Add guardrail-path resolvability and accurate runtime-boundary wording requirements; include opsx syntax consistency, wrapper readiness diagnostics, and Tavily-first runtime search readiness.
- `opencode-workflow-integration`: Require strict-mode fallback boundary documentation and command-surface compatibility guidance; keep guardrail/runtime policy parity, opsx syntax consistency, Tavily-first search boundary wording, and subagent execution diagnostics.
- `opencode-native-configuration`: Fix `spec-verify` template syntax, treat disabled-agent planner-toggle cleanup as clarity-oriented governance, and add explicit search/subagent model-route stance requirements.

## Impact

- `dot_codex/AGENTS.md.tmpl`
- `dot_codex/config.toml.tmpl` (Tavily MCP readiness and diagnostics alignment)
- `private_dot_config/opencode/AGENTS.md.tmpl`
- `dot_claude/settings.json.tmpl` and project-level Claude MCP enablement posture (Tavily runtime parity checks)
- `dot_claude/CLAUDE.md.tmpl` (cross-tool disambiguation consistency checks)
- `dot_claude/context/guardrails.md` and/or shared guardrails projection path (path-closure decision)
- `dot_local/bin/executable_codex-manage.tmpl`
- `private_dot_config/opencode/oh-my-opencode.jsonc`
- `private_dot_config/opencode/commands/symlink_core.tmpl` (if command-path compatibility bridge is implemented)
- `README.md` (OpenSpec ownership clarification)
- `.gitignore` (OpenSpec local-only baseline alignment: `openspec/` ignored by default)
- `private_dot_config/opencode/opencode.jsonc.tmpl` (spec-verify command template fix)
- `tests/test_opencode_config_rendering.sh` and related assertions for updated governance/config behavior
