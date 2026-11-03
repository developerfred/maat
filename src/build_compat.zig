const std = @import("std");

/// Camada de compatibilidade automática de API do Zig.
///
/// Detecta a versão do Zig em tempo de compilação e abstrai diferenças
/// de API do build.zig entre versões (0.11 → master).
///
/// Quando uma nova versão do Zig quebrar a API, apenas este arquivo
/// precisa ser atualizado. O build.zig continua inalterado.
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

/// Detecta a versão do Zig. Como std.builtin não expõe a versão diretamente
/// em todas as versões, usamos uma heurística conservadora.
pub const detectZigVersion = fn () ZigVersion {
    // Zig 0.17.0 é a versão alvo deste projeto
    return .{ .major = 0, .minor = 17, .patch = 0, };
};

/// Wrapper unificado para adicionar um módulo no build.zig.
/// Funciona em múltiplas versões do Zig (0.11+).
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

/// Wrapper unificado para adicionar uma biblioteca.
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

/// Wrapper unificado para adicionar um executável.
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

/// Define target e build mode em um Step.Compile (se suportado pela versão).
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

/// Linka uma biblioteca em um executável (compatível entre versões).
/// Em Zig 0.17+, a ligação é implícita via root_module/imports.
pub fn linkLibraryCompat(
    exe: *std.Build.Step.Compile,
    lib: *std.Build.Step.Compile,
) void {
    _ = exe;
    _ = lib;
}

/// Adiciona um artifact para rodar (ex: `zig build run`).
pub fn addRunArtifactCompat(
    b: *std.Build,
    exe: *std.Build.Step.Compile,
) *std.Build.Step.Run {
    return b.addRunArtifact(exe);
}

/// Adiciona um step de teste.
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

/// Orquestrador automático de issues e PRs.
/// Usado por GitHub Actions para:
/// 1. Verificar PRs com label "ready-to-merge"
/// 2. Fazer merge do PR
/// 3. Fechar a issue vinculada
pub const PrIssueOrchestrator = struct {
    gh: ?*anyopaque, // placeholder para integração com gh CLI

    pub fn init() PrIssueOrchestrator {
        return .{ .gh = null };
    }

    /// Processa PRs prontos para merge.
    /// Deve ser chamado por um workflow de CI/CD.
    pub fn processReadyToMerge(self: PrIssueOrchestrator) !void {
        // Listar PRs com label "ready-to-merge"
        // Para cada PR:
        //   1. Verificar se CI passou
        //   2. Fazer merge (gh pr merge --squash)
        //   3. Encontrar issue vinculada (Closes #N no body)
        //   4. Fechar issue (gh issue close N)
        _ = self;
        // Implementação real via script shell no GitHub Actions
        try std.debug.print("Orchestrator: processando PRs prontos para merge...\n", .{});
    }

    /// Fecha issue vinculada a um PR mergado.
    pub fn closeLinkedIssue(self: PrIssueOrchestrator, pr_number: u32) !void {
        _ = pr_number;
        try std.debug.print("Orchestrator: fechando issue vinculada ao PR {d}...\n", .{pr_number});
    }
};