const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const cdp_module = b.addModule("cdp", .{
        .root_source_file = b.path("src/cdp.zig"),
        .target = target,
        .optimize = optimize,
    });

    const options_module = b.addModule("options", .{
        .root_source_file = b.path("src/options.zig"),
        .target = target,
        .optimize = optimize,
    });

    const helpers_module = b.addModule("helpers", .{
        .root_source_file = b.path("src/helpers.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &[_]std.Build.Module.Import{
            .{ .name = "options", .module = options_module },
        },
    });

    const page_module = b.addModule("page", .{
        .root_source_file = b.path("src/page.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &[_]std.Build.Module.Import{
            .{ .name = "cdp", .module = cdp_module },
            .{ .name = "options", .module = options_module },
        },
    });

    const maat_module = b.addModule("maat", .{
        .root_source_file = b.path("src/maat.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &[_]std.Build.Module.Import{
            .{ .name = "cdp", .module = cdp_module },
            .{ .name = "options", .module = options_module },
            .{ .name = "helpers", .module = helpers_module },
            .{ .name = "page", .module = page_module },
        },
    });

    const main_module = b.addModule("main", .{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &[_]std.Build.Module.Import{
            .{ .name = "maat", .module = maat_module },
        },
    });

    const maat_lib = b.addLibrary(.{
        .name = "maat",
        .root_module = maat_module,
    });
    b.installArtifact(maat_lib);

    const maat_exe = b.addExecutable(.{
        .name = "maat",
        .root_module = main_module,
    });
    b.installArtifact(maat_exe);

    const run_cmd = b.addRunArtifact(maat_exe);
    run_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "Run the example");
    run_step.dependOn(&run_cmd.step);

    const test_cmd = b.addTest(.{
        .root_module = main_module,
    });
    test_cmd.step.dependOn(b.getInstallStep());
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&test_cmd.step);
}