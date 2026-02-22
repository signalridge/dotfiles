## Why

This change was originally drafted for a single tool-agnostic prefix (`ai-tools/...` via `AI_TOOLS_GOPASS_PREFIX`), but the project implementation evolved.

The current repository has already standardized on **tool-scoped canonical namespaces**:

- `claude/providers/...`
- `codex/providers/...`
- `opencode/providers/...`

This behavior is implemented in shared runtime helpers and verified by wrapper tests. The spec needs to be aligned to current project reality so requirements and tasks describe what is actually shipped.

## What Changes

- Align change intent to implemented behavior:
  - canonical namespace is **tool-scoped** (derived from runtime tool context), not environment-overridden
  - key format is `<tool-prefix>/providers/<provider>/accounts/<encoded_account>/api_key`
  - runtime uses canonical helpers only (no legacy fallback reads)
  - migration is operator-driven (re-add keys through `*-manage add-key`) rather than a dedicated migration binary
- Keep path safety validation for prefix/provider/account segments.

## Capabilities

### New Capabilities

- `ai-tools-gopass-namespace`: Canonical tool-scoped gopass namespace and validation for AI tool keys.

### Modified Capabilities

- (none)

## Impact

- `dot_local/bin/lib/ai/core.tmpl` key path generation, namespace resolution, and validation.
- `claude-token` / `codex-token` / `opencode-token` behavior via shared helpers.
- Wrapper behavior and list/switch/test flows relying on canonical path discovery.
- Documentation updates for current namespace behavior and manual migration guidance.
