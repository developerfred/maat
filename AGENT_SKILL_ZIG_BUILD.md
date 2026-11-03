# Agent Skill: Zig Build & Compatibility for Maat

This skill helps AI agents work with Zig 0.17.0 build system and maintain compatibility across Zig versions.

## Build Commands

```bash
# Build library and executable
zig build

# Run the example (requires Chromium)
zig build run

# Run tests
zig build test

# Check formatting
zig fmt --check src/

# Format all source files
zig fmt src/
```

## Zig 0.17.0 API Reference

### Module Creation (build.zig)
```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const my_module = b.addModule("my_module", .{
        .root_source_file = b.path("src/my_module.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &[_]std.Build.Module.Import{
            .{ .name = "dep", .module = dep_module },
        },
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

### Allocator Usage (Zig 0.17)
```zig
// Correct - GeneralPurposeAllocator when available
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
defer _ = gpa.deinit();
const allocator = gpa.allocator();

// ArrayList with allocator
var list = try std.ArrayList([]const u8).initCapacity(allocator, 4);
defer list.deinit(allocator);
try list.append(allocator, "item");

// fmt.allocPrint without explicit type
const s = try std.fmt.allocPrint(allocator, "value: {d}", .{42});
defer allocator.free(s);
```

### Common Errors & Fixes

| Error | Fix |
|-------|-----|
| `root_source_file` not found | Use `root_module` with `addModule` |
| `std.fmt.allocPrint(u8, ...)` | Use `std.fmt.allocPrint(allocator, ...)` (no type) |
| `std.ArrayList.append(item)` | Use `std.ArrayList.append(allocator, item)` |
| `std.process.launch` not found | Check `std.process` API for version |
| unused capture in `catch` | Use `catch \|err\| { _ = err; }` or `catch |_|` |
| extra capture in for loop | Use `for (slice, 0..) \|*b, i\|` |
| `@intCast must have known result type` | Use `@as(u8, @intCast(value))` |

## Testing

```zig
test "test name" {
    try std.testing.expectEqual(expected, actual);
}
```

Run with: `zig build test`