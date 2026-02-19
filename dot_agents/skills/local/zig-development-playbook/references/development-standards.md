# Zig Development Standards

## 1. Structure

- Keep `build.zig` and `build.zig.zon` at project root.
- Keep source layout predictable (`src/main.zig`, module roots).

## 2. Formatting and Naming

- Run `zig fmt --check .`.
- Prefer community naming style:
  - functions: `camelCase`
  - variables: `snake_case`
  - types: `PascalCase`

## 3. Error Handling

- Never ignore error unions.
- Use `try` for direct propagation.
- Use `catch` only for fallback or wrapping.
- Use `switch` on errors for exhaustive handling when needed.

## 4. Allocator and Ownership

- Pass allocator explicitly to APIs that allocate.
- Pair allocation/free paths explicitly.
- Prefer `init`/`deinit` lifecycle APIs for owned structures.
- Use `errdefer` to roll back partial state on failure.

## 5. Build Modes

- `Debug`: diagnostics-first.
- `ReleaseSafe`: optimized with safety checks.
- `ReleaseFast`: speed-first.
- `ReleaseSmall`: size-first.

Default release verification target: `ReleaseSafe`.

## 6. build.zig Conventions

- Prefer `b.standardTargetOptions(.{})` and `b.standardOptimizeOption(.{})`.
- Keep install behavior explicit via `b.installArtifact(...)`.
- Keep `run` step for local dev where appropriate.

## 7. Verification Minimum

```bash
zig fmt --check .
zig build test
zig build -Doptimize=ReleaseSafe
```

Add `-Dtarget=...` builds for each required release target.
