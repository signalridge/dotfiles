# Zig + C Interop Deep Template

Use this file when C interop is more than a single `@cImport` and needs production structure.

## 1. Suggested Repository Layout

```text
.
├── build.zig
├── build.zig.zon
├── src/
│   ├── main.zig
│   ├── root.zig
│   └── ffi/
│       ├── c_api.zig
│       └── adapter.zig
├── vendor/
│   └── mylib/
│       ├── include/
│       │   └── mylib.h
│       └── src/
│           └── mylib.c
└── test/
    └── ffi_integration_test.zig
```

## 2. `build.zig` Template (Vendored C Sources)

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const c_lib = b.addStaticLibrary(.{
        .name = "mylib_c",
        .target = target,
        .optimize = optimize,
    });
    c_lib.linkLibC();
    c_lib.addIncludePath(b.path("vendor/mylib/include"));
    c_lib.addCSourceFiles(.{
        .root = b.path("vendor/mylib/src"),
        .files = &.{"mylib.c"},
    });

    const exe = b.addExecutable(.{
        .name = "app",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    exe.linkLibrary(c_lib);
    exe.linkLibC();

    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_exe.step);
}
```

## 3. `build.zig` Template (System C Library)

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

    // Example: link system lib + headers
    exe.linkSystemLibrary("m");
    exe.linkLibC();

    b.installArtifact(exe);
}
```

If the project depends on `pkg-config`, document required packages and platform differences explicitly.

## 4. Zig Wrapper Template (`src/ffi/c_api.zig`)

```zig
const c = @cImport({
    @cInclude("mylib.h");
});

pub const ApiError = error{
    InitFailed,
    InvalidInput,
    Unknown,
};

pub fn init() ApiError!void {
    const rc = c.mylib_init();
    if (rc == 0) return;
    if (rc == -1) return ApiError.InitFailed;
    return ApiError.Unknown;
}

pub fn process(input: []const u8, out: []u8) ApiError!usize {
    if (input.len == 0) return ApiError.InvalidInput;
    const n = c.mylib_process(input.ptr, input.len, out.ptr, out.len);
    if (n < 0) return ApiError.Unknown;
    return @intCast(n);
}
```

## 5. Safe Adapter Template (`src/ffi/adapter.zig`)

```zig
const std = @import("std");
const c_api = @import("c_api.zig");

pub fn run(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    try c_api.init();

    var buf = try allocator.alloc(u8, input.len * 2);
    errdefer allocator.free(buf);

    const n = try c_api.process(input, buf);
    return buf[0..n];
}
```

Rule: keep raw C pointers in one module, expose Zig-native types from adapter layer.

## 6. Integration Test Template (`test/ffi_integration_test.zig`)

```zig
const std = @import("std");
const adapter = @import("../src/ffi/adapter.zig");

test "ffi adapter roundtrip" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const out = try adapter.run(allocator, "abc");
    defer allocator.free(out);

    try std.testing.expect(out.len > 0);
}
```

## 7. ABI and Ownership Checklist

1. State who owns each allocation boundary (C side vs Zig side).
2. Convert C status codes to typed Zig errors immediately.
3. Avoid passing temporary Zig slices to long-lived C storage.
4. Keep one canonical place for `@cImport` declarations.
5. Keep C compiler flags deterministic across platforms.

## 8. Debugging Checklist

```bash
zig build --help
zig build test
zig build -Doptimize=ReleaseSafe
zig build -Dtarget=x86_64-linux-gnu -Doptimize=ReleaseSafe
```

If interop failures are target-specific, capture failing target triple and toolchain details in the report.

## 9. Release Readiness Checklist

- C headers and include paths are version-pinned.
- C and Zig boundaries are covered by integration tests.
- ReleaseSafe build is green on required targets.
- Cross-target failures are explicit and reproducible.
