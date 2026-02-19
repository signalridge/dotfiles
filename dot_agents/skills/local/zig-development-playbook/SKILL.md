---
name: zig-development-playbook
description: End-to-end Zig engineering workflow for implementation, refactoring, debugging, testing, build.zig authoring, allocator and error-handling correctness, C interop, cross-compilation, and release checks. Use when tasks touch Zig source files, build.zig/build.zig.zon, Zig toolchain setup, or Zig project quality gates.
---

# Zig Development Playbook

Production workflow for Zig projects, designed in the same practical style as the existing Go engineering skills: clear triggers, reusable patterns, and strict verification gates.

## When to Use This Skill

- Building or modifying Zig applications/libraries.
- Creating or updating `build.zig` and `build.zig.zon`.
- Fixing Zig compile/test/build failures.
- Implementing allocator-sensitive code and ownership boundaries.
- Writing C interop code in Zig.
- Cross-compiling or preparing release artifacts.
- Performing Zig quality acceptance before merge/release.

## Core Concepts

### 1. Zig Engineering Primitives

| Primitive            | Purpose                                 |
| -------------------- | --------------------------------------- |
| `try` / `catch`      | Explicit error propagation and recovery |
| `defer` / `errdefer` | Deterministic cleanup and rollback      |
| `std.mem.Allocator`  | Explicit memory ownership and lifecycle |
| `build.zig`          | Reproducible project build graph        |
| `-Dtarget`           | Cross-compilation target selection      |
| `-Doptimize`         | Safety/performance trade-off            |

### 2. Zig Safety Model in Practice

- Prefer `Debug` and `ReleaseSafe` while implementing and validating behavior.
- Move to `ReleaseFast`/`ReleaseSmall` only when requested and measured.
- Treat unchecked ownership as a defect: allocation path and free path must be explicit.

## Quick Start

### New Project

```bash
mkdir <project-name>
cd <project-name>
zig init
zig build run
zig build test
```

### Existing Project

```bash
zig version
zig build --help
zig build test
```

If `zig` is missing, use `references/official-learning-path.md` for installation routes.

## Patterns

### Pattern 1: Standard `build.zig` Base

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "app",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_exe.step);
}
```

Use this as the default template unless the project has a stronger existing convention.

### Pattern 2: Error-Handling Contract

```zig
const std = @import("std");

fn readConfig(path: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    return try file.readToEndAlloc(std.heap.page_allocator, 1024 * 1024);
}
```

Rules:

- Never discard an error union.
- Prefer `try` for direct propagation.
- Use `catch` only for true fallback or context enrichment.

### Pattern 3: Allocator Ownership (`init`/`deinit`)

```zig
const std = @import("std");

const App = struct {
    allocator: std.mem.Allocator,
    buf: []u8,

    fn init(allocator: std.mem.Allocator, n: usize) !App {
        const buf = try allocator.alloc(u8, n);
        errdefer allocator.free(buf);

        return .{
            .allocator = allocator,
            .buf = buf,
        };
    }

    fn deinit(self: *App) void {
        self.allocator.free(self.buf);
    }
};
```

Rules:

- Define exactly who frees returned memory.
- Use `errdefer` when partial initialization can fail.
- Keep cleanup paths obvious and testable.

### Pattern 4: Testing Flow

```bash
zig test src/main.zig
zig build test
zig build -Doptimize=ReleaseSafe
```

Use file-level tests for isolation, then project-level tests for integration.

### Pattern 5: Cross-Compilation and Release

```bash
zig build -Dtarget=x86_64-linux-gnu -Doptimize=ReleaseSafe
zig build -Dtarget=aarch64-macos -Doptimize=ReleaseSafe
```

Report success/failure for each target explicitly; do not summarize ambiguous outcomes.

### Pattern 6: C Interop Baseline

```zig
const c = @cImport({
    @cInclude("stdio.h");
});

pub fn main() void {
    _ = c.printf("hello from C interop\n");
}
```

For nontrivial interop tasks, validate include paths and target ABI settings through `build.zig`.
For production-ready scaffolding, use `references/zig-c-interop-deep-template.md`.

## Operational Workflow

1. Discover context.

- Locate `build.zig`, source roots, tests, target requirements.

2. Implement minimally.

- Keep scope tight; avoid opportunistic refactors.

3. Verify in order.

- Format check, tests, primary build, optional cross-target builds.

4. Report clearly.

- Commands run, outcomes, residual risk.

## Acceptance Gate

Run the bundled quality gate script before claiming completion:

```bash
scripts/zig_quality_gate.sh <project-dir>
```

For release/cross-target tasks:

```bash
scripts/zig_quality_gate.sh <project-dir> --release-mode ReleaseSafe --targets x86_64-linux-gnu,aarch64-macos
```

Dotfiles integration acceptance is defined in `references/dotfiles-integration-standard.md`.

## Best Practices

### Do

- Use explicit ownership and cleanup semantics.
- Keep build options discoverable with `zig build --help`.
- Keep `build.zig` readable and composable.
- Prefer `ReleaseSafe` as the default release validation mode.

### Don't

- Don't hide allocation ownership.
- Don't swallow errors without intent.
- Don't claim cross-target support without building targets.
- Don't place custom skills under externally managed exact-sync namespaces.

## Resources

- Official learning and docs map: `references/official-learning-path.md`
- Zig coding/process standards: `references/development-standards.md`
- Zig ecosystem case studies (`Ghostty` etc.): `references/zig-ecosystem-projects.md`
- Deep C interop templates and checklists: `references/zig-c-interop-deep-template.md`
- Dotfiles namespace and conflict rules: `references/dotfiles-integration-standard.md`
- Reusable quality gate script: `scripts/zig_quality_gate.sh`
