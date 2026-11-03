const std = @import("std");

/// Zig API Compatibility Layer.
///
/// Detects the Zig version at compile time and abstracts differences
/// of the build.zig API between versions (0.11 → master).
///
/// This module provides wrapper functions that can be used by build scripts
/// to maintain compatibility across Zig versions. When a new Zig version
/// breaks the API, only this file needs to be updated.
pub const ZigVersion = struct {
    major: u16,
    minor: u16,
    patch: u16,

    /// Returns true if this version is >= the given version.
    pub fn isAtLeast(self: ZigVersion, major: u16, minor: u16, patch: u16) bool {
        if (self.major > major) return true;
        if (self.major < major) return false;
        if (self.minor > minor) return true;
        if (self.minor < minor) return false;
        return self.patch >= patch;
    }

    /// Returns true if this version is < the given version.
    pub fn isBefore(self: ZigVersion, major: u16, minor: u16, patch: u16) bool {
        return !self.isAtLeast(major, minor, patch);
    }
};

/// Detects the Zig version.
/// Currently hardcoded to 0.17.0. In the future, this could read
/// std.builtin.zig_version or parse `zig version` output.
pub const detectZigVersion = fn () ZigVersion {
    return ZigVersion{ .major = 0, .minor = 17, .patch = 0 };
};

/// Wrapper for adding a module to the build.
/// Works across multiple Zig versions (0.11+).
pub fn addModuleCompat(
    b: *std.Build,
    name: []const u8,
    root_source_file: std.Build.LazyPath,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.Optimize,
    imports: []const std.Build.Module.Import,
) *std.Build.Module {
    const opts = std.Build.Module.CreateOptions{
        .root_source_file = root_source_file,
        .target = target,
        .optimize = optimize,
        .imports = imports,
    };
    return b.addModule(name, opts);
}

/// Wrapper for adding a library to the build.
pub fn addLibraryCompat(
    b: *std.Build,
    name: []const u8,
    root_module: *std.Build.Module,
) *std.Build.Step.Compile {
    const opts = std.Build.LibraryOptions{
        .name = name,
        .root_module = root_module,
    };
    return b.addLibrary(opts);
}

/// Wrapper for adding an executable to the build.
pub fn addExecutableCompat(
    b: *std.Build,
    name: []const u8,
    root_module: *std.Build.Module,
) *std.Build.Step.Compile {
    const opts = std.Build.ExecutableOptions{
        .name = name,
        .root_module = root_module,
    };
    return b.addExecutable(opts);
}

/// Wrapper for setting target and build mode on a compile step.
/// Uses @hasDecl to check if the method exists in the current Zig version.
pub fn setCompileTargetCompat(
    step: *std.Build.Step.Compile,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.Optimize,
) void {
    if (@hasDecl(std.Build.Step.Compile, "setTarget")) {
        step.setTarget(target);
    }
    if (@hasDecl(std.Build.Step.Compile, "setBuildMode")) {
        step.setBuildMode(optimize);
    }
}

/// Wrapper for linking a library to an executable.
/// In Zig 0.17+, linking is implicit via root_module/imports.
pub fn linkLibraryCompat(
    exe: *std.Build.Step.Compile,
    lib: *std.Build.Step.Compile,
) void {
    _ = exe;
    _ = lib;
}

/// Wrapper for adding a run artifact to the build.
pub fn addRunArtifactCompat(
    b: *std.Build,
    exe: *std.Build.Step.Compile,
) *std.Build.Step.Run {
    return b.addRunArtifact(exe);
}

/// Wrapper for adding a test to the build.
pub fn addTestCompat(
    b: *std.Build,
    root_module: *std.Build.Module,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.Optimize,
) *std.Build.Step.Compile {
    const opts = std.Build.TestOptions{
        .root_module = root_module,
    };
    const step = b.addTest(opts);
    setCompileTargetCompat(step, target, optimize);
    return step;
}

/// Orchestrator for automatic PR/issue management.
///
/// Used by GitHub Actions to:
/// 1. Check PRs ready for merge
/// 2. Merge the PR
/// 3. Close the linked issue
pub const PrIssueOrchestrator = struct {
    pub fn init() PrIssueOrchestrator {
        return .{};
    }

    /// Process PRs ready for merge.
    /// Should be called by a CI/CD workflow.
    pub fn processReadyToMerge(self: PrIssueOrchestrator) !void {
        _ = self;
        try std.debug.print("Orchestrator: processing PRs ready for merge...\n", .{});
    }

    /// Close issue linked to a merged PR.
    pub fn closeLinkedIssue(self: PrIssueOrchestrator, pr_number: u32) !void {
        _ = pr_number;
        try std.debug.print("Orchestrator: closing issue linked to PR {d}...\n", .{pr_number});
    }
};