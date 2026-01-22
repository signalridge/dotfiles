# /context-save - Save Session Context

Save current session context for later resumption or reference.

## Usage

```
/context-save [NAME]
```

## What Gets Saved

### Project State

- Current branch and status
- Recent commits
- Modified files
- Open tasks/todos

### Session Context

- Key decisions made
- Problems encountered and solutions
- Important file locations
- Patterns discovered

### Next Steps

- Incomplete tasks
- Planned work
- Blockers and dependencies

## Output Format

Creates `.claude/context/YYYY-MM-DD-NAME.md`:

````markdown
# Context: [NAME]

Generated: YYYY-MM-DD HH:MM

## Project State

### Git Status

Branch: feature/xyz
Status: 3 files modified, 1 untracked

### Recent Activity

- commit abc123: "feat: add user validation"
- commit def456: "test: add validation tests"

## Session Summary

### Accomplished

- [x] Implemented user validation
- [x] Added unit tests

### In Progress

- [ ] Integration tests (blocked on API mock)

### Key Decisions

1. Used Pydantic for validation (over dataclasses) because...
2. Chose eager loading for user relations because...

## Important Locations

### Key Files

- `src/models/user.py:45` - User validation logic
- `tests/test_user.py` - Validation tests
- `src/api/routes.py:123` - API endpoint

### Patterns Used

- Repository pattern for data access
- Factory functions for test fixtures

## Next Session

### Start Here

1. Set up API mock for integration tests
2. Run: `uv run pytest tests/integration/`

### Commands to Remember

```bash
# Run specific test
uv run pytest tests/test_user.py -v

# Check validation
uv run python -c "from src.models import validate; validate({})"
```
````

### Watch Out For

- API mock needs Redis running
- Validation errors return 422, not 400

````

## Automatic Triggers

Consider auto-saving context:
- Before ending session
- After major milestone
- Before switching branches
- When hitting a blocker

## Loading Context

```bash
# List saved contexts
ls .claude/context/

# Read specific context
cat .claude/context/2024-01-15-user-feature.md
````

In new session:

```
Read .claude/context/2024-01-15-user-feature.md and continue from where we left off
```
