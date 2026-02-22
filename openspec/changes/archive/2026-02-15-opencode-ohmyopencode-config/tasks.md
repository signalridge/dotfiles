## 0. Spec Rebaseline (Completed)

- [x] 0.1 Re-investigate upstream OpenCode docs + source for high-value native features
- [x] 0.2 Re-investigate oh-my-opencode docs + source for command/skill/orchestration behavior
- [x] 0.3 Re-map repository-native Claude/Codex workflow patterns and OpenCode parity gaps
- [x] 0.4 Rewrite proposal/design/spec artifacts to "comprehensive, non-redundant" scope
- [x] 0.5 Validate rewritten spec artifacts with `openspec validate --changes opencode-ohmyopencode-config`
- [x] 0.6 Capture user-confirmed oh-my `experimental` matrix via interactive decisions and sync into spec constraints

## 1. OpenCode Curated Native Profile (Pending)

- [x] 1.1 Expand `private_dot_config/opencode/opencode.jsonc.tmpl` with selected high-value fields (`instructions`, `default_agent`, `watcher`, `compaction`, policy fields)
- [x] 1.2 Keep account-driven model/provider behavior deterministic while preserving explicit provider env/baseURL metadata
- [x] 1.3 Keep plugin ordering and permission baseline deterministic
- [x] 1.4 Add curated oh-my advanced profile fields in `private_dot_config/opencode/oh-my-opencode.jsonc.tmpl` (`agents`, richer `categories`, `sisyphus`, `background_task`, selected `disabled_*`)
- [x] 1.5 Apply approved `experimental` matrix exactly in managed template (including dynamic pruning + `task_system=true` + plugin timeout + safe hook creation)

## 2. Command/Skill Projection (Pending)

- [x] 2.1 Add managed OpenCode command projection from `dot_agents/commands/core` into OpenCode-native command paths
- [x] 2.2 Add managed skill projection/path wiring so required shared skills remain available in strict mode
- [x] 2.3 Validate projection behavior against OpenCode native loaders and oh-my command/skill assembly
- [x] 2.4 Add layered OpenCode command mirror (`commands/`) using Claude-style directory symlink topology
- [x] 2.5 Fix oh-my skill source recursion and remove command/prompt-as-skill mixing from managed defaults

## 3. no-Claude Policy with Operability (Pending)

- [x] 3.1 Keep no-Claude toggles and bridge-blocking policy explicit in `oh-my-opencode.jsonc`
- [x] 3.2 Keep wrapper runtime no-Claude flags explicit and consistent
- [x] 3.3 Ensure no-Claude strict mode does not break required managed workflow assets
- [x] 3.4 Verify no-Claude guardrails remain effective when advanced/experimental oh-my settings are enabled

## 4. Wrapper and UX Parity (Pending)

- [x] 4.1 Preserve `opencode-manage/with/token` lifecycle parity with native vs third-party auth split
- [x] 4.2 Add diagnostics workflow expectations for command/skill/plugin/auth readiness
- [x] 4.3 Keep `ocm/ocw` aliases and completion behavior aligned with Claude/Codex patterns
- [x] 4.4 Extend diagnostics expectations to include advanced oh-my policy state (`sisyphus/background/tmux/experimental/no-Claude`)

## 5. Documentation and Verification (Pending)

- [x] 5.1 Update `docs/opencode-provider.md` with feature matrix and troubleshooting
- [x] 5.2 Update README variants to reflect curated full-scope OpenCode behavior
- [x] 5.3 Expand tests for projection + strict-mode operability + wrapper policy invariants
- [x] 5.4 Add config rendering assertions for advanced oh-my profile and approved `experimental` matrix
- [x] 5.4a Add rendering assertions for layered projection templates (`commands`, `skills`) and recursive skill source settings
- [x] 5.5 Run `bash tests/run.sh`
- [x] 5.6 Run `openspec validate --changes opencode-ohmyopencode-config`

## 6. Latest-Needs Replan (Current)

- [x] 6.1 Re-verify upstream OpenCode user-level instruction support (`~/.config/opencode/AGENTS.md`, `OPENCODE_CONFIG_DIR` precedence) from latest source
- [x] 6.2 Sync spec/doc artifacts to explicitly cover user-level `AGENTS.md` behavior and instruction-chain expectations
- [x] 6.3 Re-audit repository Claude/Codex managed configuration surface and produce OpenCode parity gap matrix
- [x] 6.4 Investigate representative community OpenCode/oh-my configurations via source repositories (`ghq`-cloned) and extract reusable patterns
- [x] 6.5 Add managed user-level OpenCode `AGENTS.md` template aligned to current Claude/Codex workflow policy (without Claude compatibility bridge)
- [x] 6.6 Add `opencode-manage doctor` subcommand for runtime readiness checks (commands/skills/plugins/instruction files/auth)
- [x] 6.7 Update docs with parity matrix + community-pattern decisions + diagnostics flow
- [x] 6.8 Run post-apply runtime verification against real user paths (`~/.config/opencode/*`) in addition to template rendering tests

## 7. Post-Audit Gap Closure (Current)

- [x] 7.1 Re-sync upstream OpenCode/oh-my-opencode source snapshots to latest remote HEAD before final parity checks
- [x] 7.2 Close provider-family parity gap by adding missing OpenCode provider mapping aligned with existing Claude/Codex account families
- [x] 7.3 Expand managed OpenCode user-level `AGENTS.md` template to preserve cross-tool workflow rigor (OpenSpec gate + safety + source-of-truth paths)
- [x] 7.4 Clarify no-Claude policy scope in docs/spec artifacts to reflect upstream instruction fallback behavior boundaries
- [x] 7.5 Refresh installation pin alignment for OpenCode managed binary channel
- [x] 7.6 Re-run full verification (`tests/run.sh` + `openspec validate`) after post-audit changes

## 8. Three-Tool Optional Optimization (Current)

- [x] 8.1 Re-check latest upstream OpenCode + oh-my-opencode release/doc/source status and sync policy assumptions with concrete dates
- [x] 8.2 Close completion/command mismatch by making `doctor` command parity explicit across `claude-manage` / `codex-manage` / `opencode-manage`
- [x] 8.3 Re-align managed install pins to latest verified upstream versions where tooling channel allows it
- [x] 8.4 Extend tests to prevent future completion/doctor parity drift
- [x] 8.5 Re-run verification (`bash tests/run.sh` + `openspec validate --changes opencode-ohmyopencode-config`) after optional parity updates
