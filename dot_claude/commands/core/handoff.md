# /handoff - Session Continuity

Generate a handoff document for multi-session work or team collaboration.

## When to Use

- Before ending a long session
- Switching between Claude instances
- Handing off to another developer
- Creating checkpoint for complex work

## Generate Handoff Document

### Step 1: Summarize Progress

```markdown
## Session Summary

### Completed

- [x] [What was accomplished]

### In Progress

- [ ] [Current task and state]

### Blocked/Deferred

- [ ] [What's waiting and why]
```

### Step 2: Document Current State

```markdown
## Current State

### Files Modified

- `path/to/file.py` - [Brief description of changes]

### Key Decisions Made

- [Decision]: [Rationale]

### Open Questions

- [Question that needs resolution]
```

### Step 3: Provide Context for Next Session

````markdown
## Next Steps

### Immediate (Start Here)

1. [First thing to do]

### Then

2. [Second priority]

### Commands to Run

```bash
# To verify current state
[command]

# To continue work
[command]
```
````

### Important Notes

- [Critical context the next session needs]

```

## Output Format

Save to: `.claude/handoff-YYYY-MM-DD.md` or display inline.

## Artifacts to Include
- Git diff summary (staged and unstaged)
- Test status
- Any error messages or stack traces
- Relevant file paths with line numbers
```
