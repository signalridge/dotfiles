## 0. OpenSpec Artifact Versioning Posture

- [x] 0.1 Decide and document repository policy for OpenSpec artifacts (default explicit `local-only`).
- [x] 0.2 Align `.gitignore` and managed documentation to the selected local-only posture so lifecycle auditability trade-offs are explicit.

## 1. Guardrails Policy Parity and Path Closure

- [x] 1.1 Add Guardrails section to `dot_codex/AGENTS.md.tmpl` with sensitive categories and post-change report expectation.
- [x] 1.2 Add Guardrails section to `private_dot_config/opencode/AGENTS.md.tmpl` with same governance semantics.
- [x] 1.3 Align Codex/OpenCode L3+ Pre-Analysis risk item to guardrail-triggered checks.
- [x] 1.4 Define and implement a resolvable guardrails reference path for Codex/OpenCode policy text (canonical source + rendering/projection rule).
- [x] 1.5 Add machine-verifiable Guardrails anchors in policy/spec expectations: fixed section name, required sensitive-category tokens, and fixed high-risk operation wording.

## 2. Runtime Boundary Accuracy

- [x] 2.1 Update Codex boundary wording to reflect limited runtime hook capability (notify-oriented) rather than "no hooks", and require confirmation-first behavior for high-risk operations.
- [x] 2.2 Update OpenCode strict/compat boundary wording to include AGENTS -> CLAUDE fallback caveat and explicit isolation option (`OPENCODE_DISABLE_CLAUDE_CODE=1`).
- [x] 2.3 Add/adjust assertions to keep boundary wording machine-checkable in rendered policy docs where practical.

## 3. OpenSpec Routing and Command-Surface Compatibility

- [x] 3.1 Audit all opsx command references in `dot_codex/AGENTS.md.tmpl` and ensure consistent hyphen form (`/opsx-*`) throughout; add a single cross-tool note that Claude uses `/opsx:*`.
- [x] 3.2 Audit all opsx command references in `private_dot_config/opencode/AGENTS.md.tmpl` and ensure consistent hyphen form (`/opsx-*`); add a single cross-tool note that Claude uses `/opsx:*`.
- [x] 3.3 Verify `dot_claude/CLAUDE.md.tmpl` consistently uses colon form (`/opsx:*`) and cross-references Codex hyphen form only in disambiguation section.
- [x] 3.4 Clarify OpenCode command-surface compatibility in managed docs/policy for `.opencode/command` (OpenSpec output) and `.opencode/commands` (current OpenCode docs/runtime).
- [x] 3.5 Ensure existing managed symlink topology (`~/.config/opencode/commands/core`) remains explicitly documented as authoritative in this repo.

## 4. Diagnostics and Configuration Hardening

- [x] 4.1 Extend `dot_local/bin/executable_codex-manage.tmpl` doctor output with `opsx-*` wrapper readiness checks.
- [x] 4.2 Fix `spec-verify` command template in `private_dot_config/opencode/opencode.jsonc.tmpl`: change `openspec validate --changes <change-name>` to `openspec validate <change-name>`.
- [x] 4.3 Remove stale Sisyphus planner residue (`planner_enabled`, `replace_plan`, `default_builder_enabled`) from `private_dot_config/opencode/oh-my-opencode.jsonc` while preserving strict disabled posture.

## 5. Main Spec Sync

- [x] 5.1 Update `openspec/specs/opencode-native-configuration/spec.md` scenario for `sisyphus_agent` to align with clarity-oriented disabled-profile expectation.
- [x] 5.2 Ensure spec text does not classify disabled Sisyphus planner toggles as functional runtime breakage.

## 6. Tests and Verification

- [x] 6.1 Update `tests/test_opencode_config_rendering.sh` assertions for: spec-verify syntax, policy boundary wording, and command-surface compatibility notes.
- [x] 6.2 Add assertions that rendered AGENTS files use correct tool-native opsx syntax.
- [x] 6.3 Add checks that guardrails references in rendered Codex/OpenCode policy resolve to an available managed path.
- [x] 6.4 Add checks that Guardrails machine anchors are present (section title + required category tokens + high-risk wording).
- [x] 6.5 Add checks that Sisyphus planner residue fields are absent when `sisyphus_agent.disabled=true`.
- [x] 6.6 Add checks that OpenSpec artifact versioning posture is explicit and consistent with repository policy.
- [x] 6.7 Run targeted repository tests to verify rendered configuration and guardrail policy consistency.
- [x] 6.8 Run OpenSpec validation for this change.

## 7. External Docs Baseline

- [x] 7.1 Record and maintain a dated evidence snapshot for Claude/Codex/OpenCode/oh-my-opencode governance claims in `design.md`.
- [x] 7.2 On substantial routing/policy updates, refresh links and snapshot date before archive.

## 8. Tavily MCP-First Search Routing

- [x] 8.1 Add explicit Tavily MCP-first routing requirements/scenarios for Codex/OpenCode policy and fallback wording.
- [x] 8.2 Extend diagnostics coverage to report Tavily MCP runtime readiness for managed tool surfaces (Codex/Claude/OpenCode guidance or checks).
- [x] 8.3 Clarify OpenCode Exa websearch default versus Tavily-first governance precedence in managed policy/docs.
- [x] 8.4 Add assertions for Tavily-first anchor wording and runtime-readiness evidence paths.
- [x] 8.5 Add explicit OpenCode MCP provisioning expectation (Tavily present or documented exception path).

## 9. OpenCode Subagent Model Routing and Empty-Response Diagnostics

- [x] 9.1 Add managed model-route stance for `librarian`/`explore`/`oracle` in `private_dot_config/opencode/oh-my-opencode.jsonc` (explicit override or explicit opt-in to upstream defaults).
- [x] 9.2 Add policy guidance that `explore`/`librarian` are background-first and document synchronous-call caveats.
- [x] 9.3 Add policy/test guidance for handling `No assistant or tool response found` as execution-channel diagnostics (retry/escalation), not business-success output.
- [x] 9.4 Add assertions that managed config/policy prevents unintentional default GLM routing drift for research subagents.
