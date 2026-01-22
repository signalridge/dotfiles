# /debug - Systematic Debugging

Debug issues using the ISOLATE → TRACE → VERIFY methodology.

## Usage

```
/debug <error message or description>
/debug The API returns 500 when user has no profile
/debug pytest fails on test_auth with AttributeError
```

## Methodology

### Phase 1: ISOLATE

**Goal:** Narrow down the problem scope

1. Reproduce the issue - Get exact error message
2. Identify boundaries - Which component? When did it last work?
3. Separate symptoms from cause - Trace data flow backward

### Phase 2: TRACE

**Goal:** Find the root cause

1. Follow execution path: Entry → Function calls → Error
2. Check data at each step: Input → Intermediate → Output
3. Add diagnostic logging if needed

**Common culprits:**

- Null/undefined values
- Type mismatches
- Off-by-one errors
- Race conditions
- State mutations

### Phase 3: VERIFY

**Goal:** Confirm the fix works

1. Propose minimal fix - Change only what's necessary
2. Test the fix - Original issue + regressions + edge cases
3. Document if needed - Why bug occurred, why fix is correct

## Complexity Assessment

```
Score = 0
+ Stack trace present        → +2
+ Multiple error locations   → +2
+ Cross-module issue         → +3
+ Async/timing related       → +3
+ State management issue     → +2

≥5 Complex → Use error-resolver agent
≥2 Medium  → Standard debug
<2 Simple  → Quick fix
```

## Related

- **Agent:** `agents/debug/error-resolver` - For complex issues (5-phase workflow)
- **Command:** `/test` - Run tests after fix
- **Skill:** Use `python-best-practices` for Python-specific debugging
