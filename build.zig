const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const net_module = b.addModule("net_client", .{
        .root_source_file = b.path("src/net_client.zig"),
        .target = target,
        .optimize = optimize,
    });

    const cdp_module = b.addModule("cdp", .{
        .root_source_file = b.path("src/cdp.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &[_]std.Build.Module.Import{
            .{ .name = "net_client", .module = net_module },
        },
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

    const graph_module = b.addModule("graph", .{
        .root_source_file = b.path("src/graph.zig"),
        .target = target,
        .optimize = optimize,
    });

    const security_module = b.addModule("security", .{
        .root_source_file = b.path("src/security.zig"),
        .target = target,
        .optimize = optimize,
    });

    const rate_limit_module = b.addModule("rate_limit", .{
        .root_source_file = b.path("src/rate_limit.zig"),
        .target = target,
        .optimize = optimize,
    });

    const page_module = b.addModule("page", .{
        .root_source_file = b.path("src/page.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &[_]std.Build.Module.Import{
            .{ .name = "cdp", .module = cdp_module },
            .{ .name = "options", .module = options_module },
            .{ .name = "security", .module = security_module },
        },
    });

    const browser_module = b.addModule("browser", .{
        .root_source_file = b.path("src/browser.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &[_]std.Build.Module.Import{
            .{ .name = "cdp", .module = cdp_module },
            .{ .name = "options", .module = options_module },
            .{ .name = "helpers", .module = helpers_module },
            .{ .name = "page", .module = page_module },
        },
    });

    const context_module = b.addModule("context", .{
        .root_source_file = b.path("src/context.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &[_]std.Build.Module.Import{
            .{ .name = "cdp", .module = cdp_module },
            .{ .name = "options", .module = options_module },
            .{ .name = "page", .module = page_module },
        },
    });

    const webkit_module = b.addModule("webkit", .{
        .root_source_file = b.path("src/webkit.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &[_]std.Build.Module.Import{
            .{ .name = "cdp", .module = cdp_module },
            .{ .name = "options", .module = options_module },
            .{ .name = "helpers", .module = helpers_module },
        },
    });

    const firefox_module = b.addModule("firefox", .{
        .root_source_file = b.path("src/firefox.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &[_]std.Build.Module.Import{
            .{ .name = "cdp", .module = cdp_module },
            .{ .name = "options", .module = options_module },
            .{ .name = "helpers", .module = helpers_module },
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
            .{ .name = "graph", .module = graph_module },
            .{ .name = "page", .module = page_module },
            .{ .name = "browser", .module = browser_module },
            .{ .name = "context", .module = context_module },
            .{ .name = "webkit", .module = webkit_module },
            .{ .name = "firefox", .module = firefox_module },
            .{ .name = "security", .module = security_module },
            .{ .name = "rate_limit", .module = rate_limit_module },
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

    const graph_example_module = b.addModule("graph_example", .{
        .root_source_file = b.path("examples/graph_example.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &[_]std.Build.Module.Import{
            .{ .name = "maat", .module = maat_module },
        },
    });

    const full_example_module = b.addModule("full_example", .{
        .root_source_file = b.path("examples/full_example.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &[_]std.Build.Module.Import{
            .{ .name = "maat", .module = maat_module },
        },
    });

    const memory_test_module = b.addModule("memory_test", .{
        .root_source_file = b.path("src/memory_test.zig"),
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

    const graph_example_exe = b.addExecutable(.{
        .name = "graph-example",
        .root_module = graph_example_module,
    });
    b.installArtifact(graph_example_exe);
    const graph_example_run_cmd = b.addRunArtifact(graph_example_exe);
    graph_example_run_cmd.step.dependOn(b.getInstallStep());
    const graph_example_step = b.step("graph-example", "Run graph example");
    graph_example_step.dependOn(&graph_example_run_cmd.step);

    const full_example_exe = b.addExecutable(.{
        .name = "full-example",
        .root_module = full_example_module,
    });
    b.installArtifact(full_example_exe);
    const full_example_run_cmd = b.addRunArtifact(full_example_exe);
    full_example_run_cmd.step.dependOn(b.getInstallStep());
    const full_example_step = b.step("full-example", "Run full example");
    full_example_step.dependOn(&full_example_run_cmd.step);

    const test_cmd = b.addTest(.{
        .root_module = main_module,
    });
    test_cmd.step.dependOn(b.getInstallStep());
    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&test_cmd.step);

    const memory_test_cmd = b.addTest(.{
        .root_module = memory_test_module,
    });
    memory_test_cmd.step.dependOn(b.getInstallStep());
    const memory_test_step = b.step("memory-test", "Run memory tests");
    memory_test_step.dependOn(&memory_test_cmd.step);
}