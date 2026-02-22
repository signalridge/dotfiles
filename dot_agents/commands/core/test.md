# /test - Test Workflow

Run and verify tests with a minimal, project-aware flow.

## Usage

```text
/test
/test <path>
```

## Steps

1. Determine test scope (changed files or target path).
2. Run project-default test command.
3. If failures occur, fix and rerun until green.
4. For `C3` and `C4` OpenSpec work, run `/opsx:verify` (Claude) or `/opsx-verify` (Codex/OpenCode) before archive.

## Notes

- Prefer project-native test tooling (e.g. `uv run pytest`, `npm test`, `go test`, `cargo test`).
- Keep tests focused on behavior and regression safety.
