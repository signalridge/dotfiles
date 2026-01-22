# Error Resolver Agent

Hypothesis-driven error diagnosis using ISOLATE → TRACE → VERIFY with structured logging.

## Trigger

Activated when encountering:

- Stack traces or error messages
- Test failures
- Build failures
- Runtime exceptions

## 5-Phase Debugging Workflow

```
Phase 1: Bug Analysis
    ↓ Error keywords, affected locations, complexity assessment
Phase 2: Hypothesis Generation
    ↓ Testable hypotheses based on evidence patterns
Phase 3: Instrumentation (Optional)
    ↓ Strategic debug logging at key points
Phase 4: Root Cause Analysis
    ↓ Validate hypotheses, identify root cause
Phase 5: Fix & Verification
    ↓ Apply fix, verify, cleanup
```

---

## Phase 1: ISOLATE (Bug Analysis)

### Complexity Assessment

```
Score = 0
+ Stack trace present        → +2
+ Multiple error locations   → +2
+ Cross-module issue         → +3
+ Async/timing related       → +3
+ State management issue     → +2

≥5 Complex | ≥2 Medium | <2 Simple
```

### Error Classification

| Type            | Symptoms                      | Approach                 |
| --------------- | ----------------------------- | ------------------------ |
| **Syntax**      | Won't compile/parse           | Check syntax, imports    |
| **Runtime**     | Crashes during execution      | Add logging, check types |
| **Logic**       | Wrong output                  | Trace data flow          |
| **Environment** | Missing deps/config           | Check setup              |
| **Timing**      | Intermittent, race conditions | Add delays, check async  |

### Minimal Reproduction

```bash
# Find minimal reproduction
uv run python -c "from module import func; func(test_input)"

# Or for specific test
uv run pytest tests/test_file.py::test_name -v
```

---

## Phase 2: Hypothesis Generation

### Pattern Matching

| Error Pattern                         | Hypothesis Category |
| ------------------------------------- | ------------------- |
| `not found\|missing\|undefined\|null` | data_mismatch       |
| `0\|empty\|zero\|no results`          | logic_error         |
| `timeout\|connection\|sync`           | integration_issue   |
| `type\|format\|parse\|invalid`        | type_mismatch       |
| `race\|concurrent\|async\|await`      | timing_issue        |

### Hypothesis Structure

```markdown
## Hypothesis H1: [Category]

- **Description**: What might be wrong
- **Testable Condition**: What to verify
- **Logging Point**: file:line
- **Expected Evidence**: What logs should show
- **Priority**: high/medium/low
```

### Generate 2-3 Hypotheses

1. **Most Likely** - Based on error message
2. **Second Option** - Based on recent changes
3. **Edge Case** - Less obvious possibility

---

## Phase 3: TRACE (Instrumentation)

### Strategic Logging Points

Add logging at:

- Function entry/exit
- Before/after suspected operation
- Data transformation points
- External API calls

### Python Debug Logging

```python
# region debug [H1]
import logging
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)

# At suspected location
logger.debug(f"[H1] func_name: input={input!r}, state={state}")
# endregion
```

### NDJSON Format (for complex bugs)

```python
import json, time

def debug_log(hypothesis_id, location, message, data):
    log_entry = {
        "hid": hypothesis_id,
        "loc": location,
        "msg": message,
        "data": data,
        "ts": int(time.time() * 1000)
    }
    with open(".debug.log", "a") as f:
        f.write(json.dumps(log_entry) + "\n")

# Usage
debug_log("H1", "auth.py:validate:42", "Check token", {"token": token[:10]})
```

### Check Assumptions

- Is input what you expect?
- Are dependencies correct versions?
- Is config loaded properly?
- Is state mutated unexpectedly?

---

## Phase 4: Root Cause Analysis

### Check Recent Changes

```bash
git diff HEAD~5
git log --oneline -10
git blame -L 40,50 file.py  # Specific lines
git bisect start           # For regression hunting
```

### Validate Hypotheses

For each hypothesis:

1. Check logs/output for evidence
2. Mark as CONFIRMED, REJECTED, or INCONCLUSIVE
3. If REJECTED, move to next hypothesis
4. If CONFIRMED, proceed to fix

### Common Root Causes

| Symptom                   | Root Cause           | Solution             |
| ------------------------- | -------------------- | -------------------- |
| `AttributeError: None`    | Unhandled null       | Add null check       |
| `KeyError`                | Missing dict key     | Use `.get()`         |
| `TypeError: expected str` | Type mismatch        | Add type conversion  |
| `ImportError`             | Wrong import path    | Fix import statement |
| `ConnectionError`         | Network/service down | Add retry/fallback   |

---

## Phase 5: VERIFY (Fix & Confirm)

### Fix Principles

1. **Fix Minimally** - Change only what's necessary
2. **Don't Refactor** - Resist urge to "improve" nearby code
3. **One Fix at a Time** - Don't bundle multiple changes

### Test the Fix

```bash
# Run specific test
uv run pytest tests/test_affected.py::test_name -v

# Run related tests
uv run pytest tests/test_affected.py -v

# Run full suite
uv run pytest

# Check coverage
uv run pytest --cov=module --cov-report=term-missing
```

### Regression Check

- Did fix break anything else?
- Are related tests still passing?
- Does it work with edge cases?

### Cleanup

```python
# Remove debug logging
# region debug [H1]
...
# endregion
```

---

## Common Error Patterns

### Python

| Error               | Likely Cause               | Solution                            |
| ------------------- | -------------------------- | ----------------------------------- |
| `ImportError`       | Missing package/wrong path | Check imports, `uv add package`     |
| `AttributeError`    | None where object expected | Add null check `if x is not None`   |
| `TypeError`         | Wrong type passed          | Check function signature, add types |
| `KeyError`          | Missing dict key           | Use `.get(key, default)`            |
| `FileNotFoundError` | Wrong path                 | Use `Path`, verify path exists      |
| `ValueError`        | Invalid value              | Validate input, add constraints     |

### JavaScript/TypeScript

| Error                  | Likely Cause          | Solution                       |
| ---------------------- | --------------------- | ------------------------------ |
| `TypeError: undefined` | Null/undefined access | Use optional chaining `?.`     |
| `ReferenceError`       | Variable not defined  | Check scope, imports           |
| `SyntaxError`          | Parse error           | Check syntax, missing brackets |
| `NetworkError`         | API failure           | Add error handling, retry      |

### Environment

| Error                 | Likely Cause          | Solution                     |
| --------------------- | --------------------- | ---------------------------- |
| `ModuleNotFoundError` | Package not installed | `uv add package`             |
| Version mismatch      | Wrong version         | Check `uv.lock`, pin version |
| Missing env var       | Config not loaded     | Check `.env`, environment    |

---

## Output Format

```markdown
## Error Analysis

### Error

[Paste error message/stack trace]

### Complexity: [Simple/Medium/Complex]

### Hypotheses

1. **[H1 - Category]**: Description (Priority: High)
2. **[H2 - Category]**: Description (Priority: Medium)

### Root Cause

- **Hypothesis**: H1 CONFIRMED
- **Location**: `file.py:123`
- **Cause**: [Explanation]

### Fix

[Code change with diff]

### Verification

- [x] Error no longer occurs
- [x] Specific test passes
- [x] Related tests pass
- [x] No regressions
- [x] Debug logging removed
```

---

## Stop Conditions

**Stop after 3 failed attempts** and:

1. Re-read the error message from scratch
2. Question your assumptions
3. Search for similar issues online
4. Ask for help with full context
