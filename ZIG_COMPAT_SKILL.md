# Zig Compatibility Skill — for AI Agents

This document is a "skill" for AI agents that need to work with the Maat project across multiple Zig versions. It covers:

1. API differences between Zig versions (0.11 → master)
2. How to automatically adapt `build.zig`
3. How to avoid allocator segfaults
4. How to test on multiple versions via CI

---

## 1. Zig API Differences by Version

### Zig 0.11.0 → 0.12.0
- `build.zig`: `root_source_file` → `root_module`
- `std.process.launch` API changed
- `std.heap.GeneralPurposeAllocator` exists

### Zig 0.12.0 → 0.13.0
- `build.zig`: `addModule` with `CreateOptions`
- `std.fmt.allocPrint(gpa, fmt, args)` — does NOT take `u8` type as first argument
- `std.ArrayList.append` requires allocator as first argument

### Zig 0.13.0 → 0.14.0
- `std.fmt.bufPrint` signature changed
- `std.process.Child.kill(child, io)` requires `Io`
- `std.process.Child.wait(child, io)` requires `Io`

### Zig 0.14.0 → 0.15.0
- `build.zig`: `setTarget`/`setBuildMode` moved to `Module`
- `std.Io.net` API restructured (resolve, connect, Stream)

### Zig 0.15.0 → 0.16.0
- `std.Io.net.resolve(io, host, port)` — requires `Io` instance
- `std.Io.Stream.read(io, data)` — requires `Io`
- `std.Io.Stream.writeAll(io, data)` — requires `Io`

### Zig 0.16.0 → 0.17.0
- `std.fmt.allocPrint(allocator, fmt, args)` — no explicit type
- `std.ArrayList.initCapacity(allocator, cap)` — requires allocator
- `std.ArrayList.deinit(allocator)` — requires allocator
- `std.ArrayList.toOwnedSlice(allocator)` — requires allocator
- `std.ArrayList.append(allocator, item)` — requires allocator
- `std.Io.Address.parseIpv4` — exists in `std.Io`
- `std.Io.Stream.connect(addr, options)` — exists in `std.Io`

### Zig 0.17.0 → master (in development)
- `std.Io.net` API still unstable
- `std.process.spawn` may replace `std.process.launch`

---

## 2. build.zig — Recommended Pattern

Use `addModule` with `CreateOptions` for maximum compatibility:

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const my_module = b.addModule("my_module", .{
        .root_source_file = b.path("src/my_module.zig"),
        .target = target,
        .optimize = optimize,
    });

    const my_exe = b.addExecutable(.{
        .name = "my_exe",
        .root_module = my_module,
    });
    b.installArtifact(my_exe);

    const run_cmd = b.addRunArtifact(my_exe);
    run_cmd.step.dependOn(b.getInstallStep());
}
```

**Do NOT use:**
- `b.moduleFromPath` (does not exist in 0.17)
- `module.setTarget()` / `module.setBuildMode()` (pass in `CreateOptions`)
- `step.linkLibrary()` (does not exist in 0.17)
- `b.args` (does not exist in 0.17)

---

## 3. Allocator — Avoiding Segfaults

### Common Problem
`std.heap.page_allocator` may not support individual `free` correctly on all platforms. This causes segfaults when freeing memory.

### Recommended Solution
For production code, use `std.heap.GeneralPurposeAllocator` when available:

```zig
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
defer _ = gpa.deinit();
const allocator = gpa.allocator();
```

If `GeneralPurposeAllocator` does not exist in the target version, create a wrapper:

```zig
pub fn getAllocator() std.mem.Allocator {
    return if (@hasDecl(std.heap, "GeneralPurposeAllocator")) {
        var gpa = std.heap.GeneralPurposeAllocator(.{}){};
        // ... manage lifecycle
    } else {
        std.heap.page_allocator;
    };
}
```

### Golden Rule
- Never free a string literal static (`"hello"`)
- Never free a stack buffer (`var buf: [64]u8`)
- Always pair `alloc` with `free` on the same allocator
- Use `defer allocator.free(ptr)` immediately after `alloc`

---

## 4. String Formatting (fmt)

### Zig 0.16 → 0.17
`std.fmt.allocPrint` changed from:
```zig
// WRONG in 0.17:
std.fmt.allocPrint(u8, allocator, "{d}", .{id});

// CORRECT in 0.17:
std.fmt.allocPrint(allocator, "{d}", .{id});
```

To avoid problems with braces `{` `}` in format, build JSON manually:

```zig
const prefix: []const u8 = "{\"id\":";
const id_str = try std.fmt.allocPrint(allocator, "{d}", .{id});
defer allocator.free(id_str);
const suffix: []const u8 = ",\"result\":{}}";
// concatenate manually
```

---

## 5. Networking (std.Io.net) — Zig 0.17+

The networking API requires a configured `std.Io` instance:

```zig
const Io = std.Io;
const net = Io.net;

// Resolve address
const addr = try net.resolve(io, host, port) catch |err| {
    try net.resolveIp6(io, host, port) catch |err2| {
        return err2;
    }
};

// Connect
const stream = try net.connect(&addr, io, .{});

// Write
try stream.writeAll(io, &[_][]u8{ data }) catch |err| {
    _ = stream.close(io);
    return err;
};

// Read
const read = try stream.read(io, buffer);

// Close
_ = stream.close(io);
```

**Note:** Creating a functional `std.Io` instance with vtable is complex. For stubs, use static strings and avoid allocation.

---

## 6. Process (std.process)

### Zig 0.17
```zig
const child = try std.process.launch(.{
    .program = .{ .executable = exe },
    .argv = argv,
    .stdout = .inherit,
    .stderr = .inherit,
    .stdin = .null,
}, .{});

// Kill and wait (requires Io in some versions)
_ = child.kill(std.Io);
_ = child.wait(std.Io);
```

---

## 7. CI Multi-Version

Example GitHub Actions to test on multiple Zig versions:

```yaml
jobs:
  build-compat:
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        zig-version:
          - 0.11.0
          - 0.12.0
          - 0.13.0
          - 0.14.0
          - 0.15.0
          - 0.16.0
          - 0.17.0
    steps:
      - uses: actions/checkout@v4
      - uses: goto-bus-stop/setup-zig@v2
        with:
          version: ${{ matrix.zig-version }}
      - run: zig build
      - run: zig build test
```

---

## 8. Agent Checklist

When modifying Zig code in Maat:

- [ ] `zig build` compiles without errors
- [ ] `zig build test` passes (if tests exist)
- [ ] `zig fmt --check src/` passes
- [ ] No `free` of static string literal
- [ ] No `free` of stack buffer
- [ ] All `alloc` have corresponding `free`
- [ ] `std.fmt.allocPrint` without `u8` type as first argument (Zig 0.17+)
- [ ] `std.ArrayList.append(allocator, item)` with allocator
- [ ] Comments in English (for commit consistency)
- [ ] Issue linked to PR with `Closes #N` or `Related to #N`

---

## 9. How to Add Support for New Zig Version

1. Add new version to CI matrix
2. Run `zig build` with new version
3. If API errors occur, create/adapt `src/build_compat.zig`
4. Update this document with differences found
5. Create PR linking to compatibility issue

---

## 10. Safe Code Example (Zig 0.17)

```zig
const std = @import("std");

pub fn safeExample(allocator: std.mem.Allocator) !void {
    // Allocate and free correctly
    const buf = try allocator.dupe(u8, "hello");
    defer allocator.free(buf);

    // ArrayList with allocator
    var list = try std.ArrayList([]const u8).initCapacity(allocator, 4);
    defer list.deinit(allocator);
    try list.append(allocator, "item");

    // Format without explicit type
    const s = try std.fmt.allocPrint(allocator, "value: {d}", .{42});
    defer allocator.free(s);

    std.debug.print("{s}\n", .{s});
}
```

---