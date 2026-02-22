## Context

AI key storage behavior has already shifted from legacy `claude-code/...` paths to a shared helper model in `dot_local/bin/lib/ai/core.tmpl`, where namespace selection is tied to runtime tool context:

- `AI_TOOL_CONTEXT=claude` -> `claude/...`
- `AI_TOOL_CONTEXT=codex` -> `codex/...`
- `AI_TOOL_CONTEXT=opencode` -> `opencode/...`

The previous design target (single `ai-tools/...` with `AI_TOOLS_GOPASS_PREFIX`) no longer matches the implemented repository architecture. This document aligns design decisions with the existing project.

## Goals / Non-Goals

**Goals:**

- Define the canonical gopass namespace policy used by current wrappers/libraries (tool-scoped prefixes).
- Use a single canonical key path format across all entrypoints.
- Define migration behavior that matches current operations (manual re-add via `*-manage`).
- Validate prefix/provider/account segments to avoid malformed paths.

**Non-Goals:**

- Replacing gopass, chezmoi, or introducing a new unified CLI entrypoint.
- Supporting legacy path reads at runtime.
- Changing how providers/accounts are selected in Codex/Claude.

## Decisions

1. **Tool-context namespace selection**
   - Namespace prefix is selected by `AI_TOOL_CONTEXT` in shared core:
     - `claude`, `codex`, `opencode`.
   - Rationale: preserves operational isolation and keeps each wrapper stack self-describing in gopass paths.
   - Alternative: one shared `ai-tools` prefix (not aligned with current implementation/tests).

2. **Canonical path format**
   - Use `<prefix>/providers/<provider>/accounts/<encoded_account>/api_key`.
   - `encoded_account` uses existing base64url encoding to remain path-safe.
   - Rationale: stable, avoids special characters, and keeps all wrappers on one helper contract.
   - Alternative: `<provider>@<account>` (rejected due to special character ambiguity).

3. **Hard cutover (no runtime legacy fallback)**
   - Only the canonical path is used at runtime.
   - Rationale: reduces ongoing complexity and ensures operators migrate once.
   - Alternative: dual-read fallback (rejected by requirement).

4. **Migration by managed key rewrite**
   - Migration is done by operators through `claude-manage add-key`, `codex-manage add-key`, and `opencode-manage add-key`.
   - Rationale: matches current shipped behavior; avoids introducing unverified migration binaries.

## Risks / Trade-offs

- **[Risk] Missing keys after cutover** -> Mitigation: provide explicit manual migration guidance and key checks (`*-token --check`).
- **[Risk] Invalid env prefix** → Mitigation: validate prefix and reject invalid segments with explicit errors.
- **[Trade-off] No runtime fallback** → Acceptable given explicit migration requirement and reduced complexity.

## Migration Plan

1. Keep canonical path logic and validation in shared core (`dot_local/bin/lib/ai/core.tmpl`).
2. Keep runtime on canonical-only path helpers (no legacy fallback reads).
3. Document manual migration: re-add keys using `*-manage add-key`, verify with `*-token --check`, then remove old entries.
4. Verify behavior via wrapper and list logic tests.

Rollback: re-add keys into previous paths manually if needed and adjust helper logic in a dedicated follow-up change.

## Open Questions

- Do we need a dedicated migration CLI in future, or is manual managed migration sufficient long-term?
- Should cross-tool key sharing be reintroduced later, or is tool-scoped isolation the desired steady state?
