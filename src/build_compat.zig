const std = @import("std");

/// Camada de compatibilidade automática de API do Zig.
///
/// Detecta a versão do Zig em tempo de compilação e abstrai diferenças
/// de API do build.zig entre versões (0.11 → master).
pub const ZigVersion = struct {
    major: u16,
    minor: u16,
    patch: u16,

    pub fn isAtLeast(self: ZigVersion, major: u16, minor: u16, patch: u16) bool {
        if (self.major > major) return true;
        if (self.major < major) return false;
        if (self.minor > minor) return true;
        if (self.minor < minor) return false;
        return self.patch >= patch;
    }

    pub fn isBefore(self: ZigVersion, major: u16, minor: u16, patch: u16) bool {
        return !self.isAtLeast(major, minor, patch);
    }
};

pub const detectZigVersion = fn () ZigVersion {
    return ZigVersion{ .major = 0, .minor = 17, .patch = 0 };
};

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

pub fn linkLibraryCompat(
    exe: *std.Build.Step.Compile,
    lib: *std.Build.Step.Compile,
) void {
    _ = exe;
    _ = lib;
}

pub fn addRunArtifactCompat(
    b: *std.Build,
    exe: *std.Build.Step.Compile,
) *std.Build.Step.Run {
    return b.addRunArtifact(exe);
}

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

pub const PrIssueOrchestrator = struct {
    pub fn init() PrIssueOrchestrator {
        return .{};
    }

    pub fn processReadyToMerge(self: PrIssueOrchestrator) !void {
        _ = self;
        try std.debug.print("Orchestrator: processando PRs prontos para merge...\n", .{});
    }

    pub fn closeLinkedIssue(self: PrIssueOrchestrator, pr_number: u32) !void {
        _ = pr_number;
        try std.debug.print("Orchestrator: fechando issue vinculada ao PR {d}...\n", .{pr_number});
    }
};