## 1. Spec Artifacts

- [x] 1.1 Write proposal/design/tasks for `opencode-full-feature-profile`.
- [x] 1.2 Add delta specs for `opencode-native-configuration` and `opencode-workflow-integration`.
- [x] 1.3 Validate OpenSpec artifacts (`openspec validate --changes opencode-full-feature-profile`).

## 2. OpenCode Feature Expansion

- [x] 2.1 Expand `opencode.jsonc.tmpl` with explicit `agent`, `command`, `lsp`, `formatter`, `share`, `autoupdate`, and `tui` sections.
- [x] 2.2 Keep provider/model derivation and permission baseline deterministic.
- [x] 2.3 Expand `oh-my-opencode.jsonc.tmpl` governance profile and remove stale unsupported managed keys.

## 3. Workflow and Script Compatibility

- [x] 3.1 Replace `chezmoi apply --no-scripts` with `--exclude scripts` in all manage scripts.
- [x] 3.2 Extend `opencode-manage doctor` with advanced feature readiness checks (`command`/`lsp`/`formatter` + binary availability).
- [x] 3.3 Verify all AI manage scripts for consistency and no stale `--no-scripts` usage.

## 4. Tests and Docs

- [x] 4.1 Update OpenCode rendering tests for newly managed sections and schema-safe keys.
- [x] 4.2 Add a regression test that blocks `--no-scripts` reintroduction.
- [x] 4.3 Update `docs/opencode-provider.md` with full-feature profile guidance.
- [x] 4.4 Run full tests (`bash tests/run.sh`).
