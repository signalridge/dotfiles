## Context

The repository currently encodes stronger workflow governance in Claude than in Codex/OpenCode:

- Claude has explicit Guardrails section and active hook scripts wired in settings.
- Codex/OpenCode mainly rely on instruction text and do not provide Claude-equivalent runtime guardrails.
- OpenCode strict mode intentionally disables Claude hook bridge, but policy text does not fully explain the enforcement boundary.
- Search and research-subagent routing intent is also inconsistent between policy and runtime (Tavily-first intent vs mixed runtime defaults/fallback chains).

This asymmetry causes user-facing inconsistency for L3/L4 routing, risk handling, and OpenSpec workflow expectations.

## Evidence Snapshot (verified 2026-02-21)

| Finding                                                                                                                 | Outcome                      | Primary Evidence                                                                                      |
| ----------------------------------------------------------------------------------------------------------------------- | ---------------------------- | ----------------------------------------------------------------------------------------------------- |
| Claude hooks provide deterministic runtime decision controls (`allow` / `ask` / `deny`) with matcher-based interception | Confirmed                    | [Claude Code Hooks Guide](https://docs.claude.com/en/docs/claude-code/hooks-guide)                    |
| Codex policy model is AGENTS instruction-chain based (current dir -> parents -> home)                                   | Confirmed                    | [Codex AGENTS Guide](https://developers.openai.com/codex/guides/agents-md/)                           |
| OpenCode rules layer includes AGENTS traversal and `CLAUDE.md` compatibility fallback                                   | Confirmed                    | [OpenCode Rules](https://opencode.ai/docs/rules/)                                                     |
| OpenCode config is merged across multiple scopes with explicit precedence                                               | Confirmed                    | [OpenCode Config](https://opencode.ai/docs/config/)                                                   |
| Managed AGENTS policy text in Claude/Codex/OpenCode already states Tavily-first search intent                           | Confirmed                    | `dot_claude/CLAUDE.md.tmpl`, `dot_codex/AGENTS.md.tmpl`, `private_dot_config/opencode/AGENTS.md.tmpl` |
| Codex runtime has Tavily MCP configured and enabled                                                                     | Confirmed                    | `~/.codex/config.toml`, `codex mcp list`                                                              |
| Claude runtime has Tavily MCP configured and connectable in this environment                                            | Confirmed                    | `~/.claude.json`, `claude mcp list`                                                                   |
| OpenCode runtime currently has no configured MCP servers, while oh-my-opencode search path is Exa-oriented              | Confirmed gap                | `opencode mcp list`, `private_dot_config/opencode/oh-my-opencode.jsonc`                               |
| oh-my-opencode default `librarian` model/provider chain routes to GLM (`zai-coding-plan/glm-4.7`)                       | Confirmed                    | oh-my-opencode `AGENTS.md`, `docs/configurations.md`                                                  |
| Local managed oh-my-opencode config does not override `librarian`/`explore`/`oracle` model routes                       | Confirmed gap                | `private_dot_config/opencode/oh-my-opencode.jsonc`                                                    |
| Upstream guidance states `explore`/`librarian` should run in background; synchronous waits are discouraged              | Confirmed                    | oh-my-opencode `sisyphus-prompt.md`                                                                   |
| `No assistant or tool response found` denotes empty assistant/tool message stream in task formatter                     | Confirmed diagnostic         | oh-my-opencode `src/tools/background-task/modules/formatters.ts`                                      |
| Codex/OpenCode Pre-Analysis risk checks are generic while Claude is guardrail-bound                                     | Confirmed gap                | `dot_codex/AGENTS.md.tmpl`, `private_dot_config/opencode/AGENTS.md.tmpl`, `dot_claude/CLAUDE.md.tmpl` |
| Codex/OpenCode do not currently have local `context/guardrails.md` equivalent                                           | Confirmed path-closure gap   | `dot_claude/context/guardrails.md` exists; Codex/OpenCode context path missing                        |
| OpenSpec single-change validation requires positional arg; `--changes` validates all                                    | Confirmed bug                | OpenSpec `docs/cli.md`, `src/commands/validate.ts`; current `opencode.jsonc.tmpl`                     |
| OpenSpec currently generates OpenCode commands under `.opencode/command/`                                               | Confirmed                    | OpenSpec `docs/supported-tools.md`, `src/core/command-generation/adapters/opencode.ts`                |
| Latest OpenCode docs emphasize `commands` paths and fallback behavior controls                                          | Confirmed                    | OpenCode docs (`rules`, `commands`)                                                                   |
| Codex public docs do not define Claude-style runtime hook policy gating semantics                                       | Confirmed nuance             | [Codex AGENTS Guide](https://developers.openai.com/codex/guides/agents-md/)                           |
| Sisyphus planner toggles are runtime-inactive when `disabled=true`                                                      | Confirmed nuance             | oh-my-opencode source (`src/plugin-handlers/agent-config-handler.ts`)                                 |
| `superpowers:writing-plans` exists in current environment                                                               | Confirmed no issue           | `~/.agents/skills/superpowers/writing-plans/SKILL.md`                                                 |
| Repository `.gitignore` currently ignores `openspec/` and tracked OpenSpec artifacts are `0`                            | Confirmed governance gap     | `.gitignore`, `git ls-files` result                                                                   |
| `codex-manage doctor` currently checks only `core-*.md` counts, not `opsx-*` readiness                                  | Confirmed implementation gap | `dot_local/bin/executable_codex-manage.tmpl`                                                          |
| Guardrails requirements in delta specs are not yet machine-anchor explicit                                              | Confirmed testability gap    | current change delta specs before this revision                                                       |

## Goals / Non-Goals

**Goals:**

- Add Guardrails parity at policy level for Codex/OpenCode.
- Align L3+ pre-analysis risk checklist with guardrail-triggered review semantics.
- Close guardrail-path references so Codex/OpenCode policy references are resolvable in runtime environments.
- Clarify hard-enforced vs instruction-enforced boundaries for Codex/OpenCode with accurate tool capability wording.
- Clarify OpenSpec wrapper ownership/sync guidance to reduce operator ambiguity.
- Clarify OpenCode command-surface compatibility across `.opencode/command` and `.opencode/commands` variants.
- Establish explicit OpenSpec artifact versioning policy in-repo with default local-only posture (`openspec/` ignored by default) and explicit opt-in tracking path.
- Remove stale Sisyphus planner residue from disabled profile.
- Add Codex doctor checks for OpenSpec wrapper readiness.
- Add cross-tool Tavily MCP-first routing requirements with runtime-parity checks (Claude/Codex/OpenCode).
- Ensure OpenCode search/runtime policy explicitly resolves Tavily-vs-Exa precedence.
- Add explicit OpenCode subagent model-route governance for `librarian`/`explore`/`oracle` to prevent unintentional GLM fallback.
- Document and test empty subagent response diagnostics (`No assistant or tool response found`) as execution-channel failures.
- Unify opsx command syntax references so each tool's AGENTS policy matches its command surface (hyphen for Codex/OpenCode, colon for Claude).
- Fix spec-verify command template to use correct openspec CLI argument syntax.
- Add machine-verifiable Guardrails acceptance anchors to reduce ambiguous interpretation and improve deterministic testing.

**Non-Goals:**

- Enabling Claude compatibility bridge in OpenCode strict mode.
- Implementing new runtime hook subsystem for Codex.
- Reworking existing OpenSpec lifecycle semantics or tool-specific wrapper generation mechanics.
- Changing upstream OpenSpec command generation behavior directly in this repository.
- Treating Sisyphus planner-toggle cleanup as a production incident fix (it is governance clarity work).

## Decisions

1. Keep strict-mode architecture unchanged; improve boundary clarity and enforceability guidance.

- We will not enable OpenCode Claude hook bridge.
- We will explicitly document runtime enforcement gaps and required confirmation-first behavior for high-risk actions.

2. Treat guardrails parity as instruction-level governance for Codex/OpenCode and close path references.

- Codex/OpenCode gain explicit Guardrails sections and post-change report expectations.
- Pre-analysis risk item is aligned to guardrail-triggered checks.
- Guardrails reference text must point to a path that is actually available in Codex/OpenCode runtime context.

3. Extend Codex doctor as a practical readiness gate for OpenSpec wrappers.

- Add diagnostic checks for required `opsx-*` wrapper prompt presence.
- Keep checks warning-level to avoid blocking workflows in partially initialized environments.

4. Correct runtime-boundary wording based on actual tool capabilities.

- Codex policy language SHALL state "limited runtime hook capability" rather than "no runtime hooks".
- OpenCode policy language SHALL state strict-mode behavior plus fallback caveat and explicit isolation option (`OPENCODE_DISABLE_CLAUDE_CODE=1` when needed).
- Claude policy language SHALL continue to classify hook-enforced controls as runtime-enforced (`allow` / `ask` / `deny`) and distinguish them from instruction-only constraints.

5. Clarify OpenSpec wrapper authority and OpenCode command-surface compatibility.

- Tool-specific prompt/wrapper materialization sources and refresh behavior are documented so operators understand where to update.
- Documentation SHALL explicitly address `.opencode/command` (OpenSpec-generated path) and `.opencode/commands` (current OpenCode docs/runtime surface), including managed compatibility expectations.

6. Define OpenSpec artifact versioning policy as a governance requirement.

- This repository SHALL keep `openspec/` ignored by default and document that OpenSpec artifacts are local working state unless ignore policy is intentionally changed.
- The policy SHALL also document the auditability trade-off and the explicit opt-in path for teams that need version-controlled OpenSpec artifacts.

7. Unify opsx command syntax references per tool surface.

- Codex AGENTS uses `/opsx-*` (hyphen) matching actual `~/.codex/prompts/opsx-*.md` file names.
- OpenCode AGENTS uses `/opsx-*` (hyphen) matching OpenCode command invocation style.
- Claude AGENTS uses `/opsx:*` (colon) matching Claude Code slash command syntax.
- Cross-tool disambiguation is documented once in each AGENTS file; all other references use the tool-native form.
- Correction: OpenSpec applies colon -> hyphen transformation for OpenCode command content generation. We SHALL not preserve the previous "regardless of tool" claim.

8. Fix spec-verify command template.

- `openspec validate --changes <change-name>` is incorrect CLI usage; `--changes` validates all changes, positional arg validates a single change.
- Fix to `openspec validate <change-name>` for single-change verification.

9. Make Guardrails requirements machine-verifiable.

- Require stable section/keyword anchors for Guardrails and high-risk operation policy wording so tests can validate behavior by deterministic pattern matching.

10. Keep Sisyphus planner-toggle cleanup as clarity/auditability work.

- With `sisyphus_agent.disabled=true`, planner toggles are runtime-inactive in upstream behavior.
- Removing toggles remains useful to avoid operator confusion and to keep rendered config semantically minimal.

11. Enforce Tavily MCP-first routing as a cross-tool governance rule.

- Policy text is not sufficient; runtime readiness must be verified.
- Claude/Codex/OpenCode SHALL expose a deterministic fallback statement when Tavily MCP is unavailable.
- OpenCode SHALL explicitly document/encode precedence between oh-my-opencode Exa websearch defaults and Tavily-first governance.

12. Make OpenCode research subagent routing explicit and deterministic.

- Managed config SHALL explicitly set model routes for `librarian`, `explore`, and `oracle` (or explicitly document opt-in to upstream default chains).
- Unintentional fallback to `zai-coding-plan/glm-4.7` SHALL be treated as a governance drift risk.

13. Treat empty subagent response formatting as an execution diagnostic, not business success.

- `No assistant or tool response found` indicates missing assistant/tool stream and SHALL trigger retry/escalation handling guidance.
- Policy guidance SHALL reinforce background-mode usage for `explore`/`librarian` calls where applicable.

## Risks / Trade-offs

- [Risk] Codex/OpenCode remain weaker than Claude for runtime blocking semantics -> Mitigation: explicit enforcement-boundary language + confirmation-first policy + diagnostics.
- [Risk] Guardrails path closures may drift across tools -> Mitigation: define a canonical managed source and assert resolvability in tests/docs.
- [Risk] OpenCode command path differences (`command` vs `commands`) may cause operator confusion -> Mitigation: publish compatibility mapping and identify authoritative managed path.
- [Risk] OpenSpec artifacts remain git-ignored and governance changes are less auditable by default -> Mitigation: enforce explicit local-only posture, document trade-offs, and document explicit opt-in tracking path.
- [Risk] Additional policy text may drift from generated wrappers -> Mitigation: codex doctor wrapper checks + documented wrapper ownership.
- [Risk] Guardrails wording remains too loose for tests -> Mitigation: define fixed section title/anchor keywords/high-risk wording and assert via tests.
- [Risk] Upstream docs can shift and invalidate governance assumptions -> Mitigation: keep dated evidence snapshot with authoritative links in this design and refresh during OpenSpec update cycles.
- [Risk] Tavily-first intent drifts from runtime (especially OpenCode MCP disabled/unconfigured states) -> Mitigation: add runtime readiness assertions and explicit fallback behavior wording.
- [Risk] Research subagents silently route to unexpected providers/models (e.g., GLM chain) -> Mitigation: explicit per-agent model-route overrides and configuration assertions.
- [Risk] Operators misread `No assistant or tool response found` as content-level failure only -> Mitigation: classify as execution-channel diagnostic and add retry/escalation guidance in policy/tests.
- [Trade-off] Warning-level diagnostics can still allow risky sessions -> Acceptable because hard failures would break valid bootstrap/partial environments.
- [Risk] ff/apply prompts can still auto-advance internally -> Mitigation: out of scope for this repo; keep Execution Gate constraints at AGENTS policy layer.

## Migration Plan

1. Update Codex/OpenCode AGENTS policy templates:

- Add Guardrails section.
- Align L3+ pre-analysis risk guidance.
- Add runtime-enforcement-boundary and confirmation-first requirements with accurate capability wording.
- Ensure guardrail references resolve to a managed path.
- Add OpenCode strict fallback boundary guidance (`AGENTS -> CLAUDE` fallback + optional disable mode).
- Add Tavily MCP-first routing section with explicit fallback behavior wording.
- Clarify OpenSpec wrapper ownership/sync semantics.
- Clarify OpenCode command-surface compatibility (`command` vs `commands`) and managed expectations.
- Clarify OpenCode Exa websearch default versus Tavily-first governance precedence.
- Audit and unify opsx command syntax references (hyphen for Codex/OpenCode, colon for Claude).
- Add machine-verifiable Guardrails anchors (section title + required category tokens + high-risk operation anchor wording).

2. Update Codex doctor diagnostics:

- Add `opsx-*` prompt coverage checks.

3. Decide and encode OpenSpec artifact versioning posture:

- Keep `.gitignore` default as `openspec/` ignored.
- Update docs/spec text so local-only baseline and explicit opt-in tracking path are both explicit and testable.

4. Update OpenCode config:

- Fix `spec-verify` command template to use correct positional argument syntax.
- Optionally remove stale Sisyphus planner residue fields while keeping disabled profile explicit.
- Add explicit managed model-route overrides for `librarian`, `explore`, and `oracle` (or explicit documented opt-in to upstream defaults).
- Align search configuration with Tavily-first policy (including explicit runtime fallback behavior).

5. Update documentation:

- Clarify OpenSpec wrapper/prompt ownership by tool surface.
- Add command-path compatibility notes for OpenCode runtime surfaces.
- Record validated evidence links/paths used for governance claims.
- Add OpenSpec versioning policy note (default local-only) and its audit trade-offs, including explicit opt-in tracking guidance.

6. Sync main specs:

- Update `opencode-native-configuration` main spec scenario for sisyphus_agent to match clarity-oriented delta expectation.

7. Update tests:

- Assert policy/config behavior (guardrails references, strict-mode boundary wording, command-path compatibility wording, Sisyphus residue cleanup).
- Assert spec-verify command uses correct syntax.
- Assert AGENTS opsx references use correct tool-native syntax.
- Assert Guardrails machine anchors (section title + required category tokens + high-risk wording).
- Assert OpenSpec versioning posture is explicit (for example `.gitignore` and/or docs expectation checks).
- Assert Tavily-first policy anchors across Claude/Codex/OpenCode and runtime-readiness evidence paths.
- Assert OpenCode managed config includes explicit `librarian`/`explore`/`oracle` model-route stance.
- Assert execution-diagnostic guidance exists for empty subagent responses and background usage expectation.

8. Maintain evidence snapshot:

- Keep external-document evidence links current for Claude/Codex/OpenCode and refresh snapshot date on substantial policy updates.

9. Run verification:

- `bash tests/test_opencode_config_rendering.sh`
- targeted checks for Codex doctor and AGENTS content consistency.
- `openspec validate align-routing-guardrails`

## Open Questions

- Should we standardize a shared guardrails projection path (for example `~/.agents/context/guardrails.md`) or keep per-tool mirrored paths?
- Should this repo manage compatibility links for both `.opencode/command` and `.opencode/commands`, or select one authoritative path per OpenCode version policy?
- Should Codex gain a richer user-configurable hook policy surface beyond legacy notify behavior in future upstream releases?
- Should OpenCode strict-mode policy include machine-checkable assertions that `OPENCODE_DISABLE_CLAUDE_CODE=1` is present for full isolation workflows?
- Should OpenCode retain Exa websearch as explicit fallback or disable it entirely when Tavily MCP-first policy is enforced?
