const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Módulo CDP
    const cdp_module = b.addModule("cdp", .{
        .root_source_file = b.path("src/cdp.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Módulo Maat (importa CDP)
    const maat_module = b.addModule("maat", .{
        .root_source_file = b.path("src/maat.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &[_]std.Build.Module.Import{
            .{ .name = "cdp", .module = cdp_module },
        },
    });

    // Módulo main (importa Maat)
    const main_module = b.addModule("main", .{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &[_]std.Build.Module.Import{
            .{ .name = "maat", .module = maat_module },
        },
    });

    // Biblioteca Maat
    const maat_lib = b.addLibrary(.{
        .name = "maat",
        .root_module = maat_module,
    });
    b.installArtifact(maat_lib);

    // Executável Maat
    const maat_exe = b.addExecutable(.{
        .name = "maat",
        .root_module = main_module,
    });
    b.installArtifact(maat_exe);

    // Step `zig build run`
    const run_cmd = b.addRunArtifact(maat_exe);
    run_cmd.step.dependOn(b.getInstallStep());
    const run_step = b.step("run", "Run the example");
    run_step.dependOn(&run_cmd.step);

    // Step `zig build test`
    const test_cmd = b.addTest(.{
        .root_module = main_module,
    });
    test_cmd.step.dependOn(b.getInstallStep());
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&test_cmd.step);
}