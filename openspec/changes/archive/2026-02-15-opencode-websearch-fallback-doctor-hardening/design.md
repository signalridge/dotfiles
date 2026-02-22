## Context

The managed OpenCode stack in this repository intentionally uses strict no-Claude compatibility and gopass-backed secret management. A direct `oh-my-opencode` Tavily websearch default introduces a startup dependency on `TAVILY_API_KEY` in process environment, which conflicts with the repository's runtime key strategy and causes avoidable startup failures.

At the same time, script audit shows diagnostics quality gaps that affect operator confidence: summary color escapes are rendered as literals in `*-manage doctor` outputs, and some account-removal prompts use variable-interpolated `printf` format strings.

## Goals / Non-Goals

**Goals:**

- Ensure managed OpenCode defaults are startup-safe without requiring globally exported Tavily keys.
- Make `opencode-manage doctor` explicitly explain websearch provider readiness when Tavily is configured.
- Hardening of `manage` diagnostics/prompt output in a minimal, backward-compatible way.
- Keep behavior aligned with strict no-Claude policy and current repository workflow.

**Non-Goals:**

- Re-designing MCP topology (user has already implemented native MCP strategy).
- Migrating all shell scripts to strict ShellCheck-clean style.
- Broad refactoring of account workflows unrelated to this failure mode.

## Decisions

### Decision 1: Keep oh-my websearch default at `exa`

- **Choice:** Managed `oh-my-opencode.jsonc` default remains `websearch.provider = "exa"`.
- **Why:** `exa` does not create a hard startup requirement on `TAVILY_API_KEY` in current plugin behavior, so OpenCode launches reliably under existing repo defaults.
- **Alternative considered:** Keep `tavily` as default and require env export. Rejected because it violates repository's gopass-first key posture and creates fragile startup coupling.

### Decision 2: Add provider-specific readiness logic to doctor

- **Choice:** `opencode-manage doctor` reads configured websearch provider and emits Tavily-specific warning when `TAVILY_API_KEY` is absent.
- **Why:** Operators need immediate explanation of readiness state without reading upstream plugin source.
- **Alternative considered:** Generic provider-only display with no key checks. Rejected because it misses the exact failure condition users hit.

### Decision 3: Apply minimal hardening to shared manage UX

- **Choice:** Fix summary rendering (`echo -e`) and account prompt formatting (`printf '%s'`) in manage scripts.
- **Why:** These are low-risk, high-signal correctness fixes discovered during script audit.
- **Alternative considered:** defer to future lint cleanup. Rejected because these are concrete runtime quality issues, not style-only findings.

## Risks / Trade-offs

- **[Risk]** `exa` default may differ from teams expecting Tavily-first websearch.  
  **Mitigation:** Document explicit override path and doctor warning behavior for Tavily mode.
- **[Risk]** Shell script hardening touches shared manage scripts used daily.  
  **Mitigation:** Keep edits minimal and covered by existing test suite plus direct `*-manage doctor` execution.

## Migration Plan

1. Update managed templates and scripts.
2. Run full repository tests plus syntax checks.
3. Validate runtime doctor output on local machine.
4. Update docs and spec artifacts.
5. Archive the change once verification passes.

## Open Questions

- None for this change scope.
