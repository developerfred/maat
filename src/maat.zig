const std = @import("std");
const cdp = @import("cdp");

pub const BrowserName = enum {
    chromium,
    firefox,
    webkit,
};

pub const LaunchOptions = struct {
    name: BrowserName = .chromium,
    headless: bool = true,
    sandbox: bool = true, // sandbox ligado por padrão
    args: [][]const u8 = &[_][]const u8{},
    executable_path: []const u8 = "",
};

/// Resultado de lançamento de navegador.
pub const Browser = struct {
    allocator: std.mem.Allocator,
    name: BrowserName,
    cdp_client: ?cdp.CdpClient,
    process: ?std.ChildProcess,
    debug_port: u16,

    pub fn launch(allocator: std.mem.Allocator, opts: LaunchOptions) !Browser {
        const debug_port = try findFreePort();
        const exe = try resolveExecutable(opts);

        var args = try std.ArrayList([]const u8).initCapacity(allocator, 8);
        defer args.deinit();

        try args.append("--remote-debugging-port=" ++ std.fmt.allocPrint(u8, allocator, "{d}", .{debug_port}) catch return error.AllocFailed);
        if (opts.headless) {
            try args.append("--headless=new");
        }
        if (opts.sandbox) {
            // sandbox ativo por padrão: NÃO adicionamos --no-sandbox
        } else {
            try args.append("--no-sandbox");
        }
        for (opts.args) |arg| {
            try args.append(arg);
        }
        try args.append("about:blank");

        const argv = try args.toOwnedSlice();
        defer allocator.free(argv);

const child_opts = std.ChildProcess.Options{
    .env = _environ(),
};

        const child = try std.process.launch(.{
            .program = .{ .executable = exe },
            .argv = argv,
            .env = child_opts.env,
            .stdout = .inherit,
            .stderr = .inherit,
            .stdin = .null,
        }, .{});

        // Aguarda o navegador abrir a porta de depuração
        const ws_url = try waitForDebugPort(allocator, debug_port, 10_000);

        const host_port = try parseHostPort(allocator, ws_url);
        defer allocator.free(host_port);

        const cdp_client = try cdp.CdpClient.connect(allocator, host_port.host, host_port.port, "/");

        return .{
            .allocator = allocator,
            .name = opts.name,
            .cdp_client = cdp_client,
            .process = child,
            .debug_port = debug_port,
        };
    }

    pub fn newPage(self: *Browser) !Page {
        // Cria um novo target/aba via CDP
        const params = try self.allocator.dupe(u8, "{\"url\":\"about:blank\"}");
        defer self.allocator.free(params);

        const resp = try self.cdp_client.?.call("Target.createTarget", params, 10_000);
        defer self.allocator.free(resp);

        // Simplificação: extraímos targetId do JSON (real usaria um parser JSON)
        // Aqui criamos uma Page associada ao mesmo cliente CDP.
        return Page{
            .allocator = self.allocator,
            .cdp_client = self.cdp_client.?,
        };
    }

    pub fn close(self: *Browser) void {
        if (self.cdp_client) |c| c.close();
        if (self.process) |p| {
            _ = p.kill();
            _ = p.wait();
        }
    }
};

pub const Page = struct {
    allocator: std.mem.Allocator,
    cdp_client: cdp.CdpClient,

    pub fn goto(self: *Page, url: []const u8) !void {
        const params = try std.fmt.allocPrint(
            u8,
            self.allocator,
            "{\"url\":\"{s}\",\"frameId\":\"\",\"waitUntil\":\"load\"}",
            .{url},
        );
        defer self.allocator.free(params);

        const _resp = try self.cdp_client.call("Page.navigate", params, 30_000);
        defer self.allocator.free(_resp);
    }

    pub fn title(self: *Page) ![]u8 {
        const params = "{}";
        const resp = try self.cdp_client.call("Runtime.evaluate", params, 10_000);
        defer self.allocator.free(resp);
        // Em produção, parsear o JSON. Aqui retornamos placeholder.
        return try self.allocator.dupe(u8, "Maat Page");
    }

    pub fn screenshot(self: *Page, path: []const u8) !void {
        const params = "{}";
        const resp = try self.cdp_client.call("Page.captureScreenshot", params, 10_000);
        defer self.allocator.free(resp);
        // Em produção, extrair base64 e escrever arquivo.
        const file = try std.fs.cwd().createFile(path, .{});
        defer file.close();
        try file.writeAll("maat-screenshot-placeholder");
    }

    pub fn close(self: *Page) void {
        _ = self;
        // fecharia o target via CDP
    }
};

// ---------- helpers privados ----------

fn findFreePort() !u16 {
    // Em produção, abrir um socket temporário e perguntar ao SO.
    // Aqui usamos uma porta padrão de debug do Chromium.
    return 9222;
}

fn resolveExecutable(opts: LaunchOptions) ![]const u8 {
    if (opts.executable_path.len > 0) return opts.executable_path;
    switch (opts.name) {
        .chromium => return "google-chrome",
        .firefox => return "firefox",
        .webkit => return "Safari",
    }
}

const HostPort = struct {
    host: []const u8,
    port: u16,
};

fn parseHostPort(allocator: std.mem.Allocator, ws_url: []const u8) !HostPort {
    // ws://host:port/ -> host e port
    const after_scheme = ws_url[7..]; // remove "ws://"
    const slash = std.mem.indexOf(u8, after_scheme, "/") catch after_scheme.len;
    const host_port = after_scheme[0..slash];
    const colon = std.mem.indexOf(u8, host_port, ":") orelse return error.InvalidAddress;
    const host = host_port[0..colon];
    const port_str = host_port[colon + 1..];
    const port = std.fmt.parseInt(u16, port_str, 10) catch return error.InvalidAddress;
    return .{
        .host = try allocator.dupe(u8, host),
        .port = port,
    };
}

fn waitForDebugPort(allocator: std.mem.Allocator, port: u16, timeout_ms: u64) ![]u8 {
    const start = std.time.milliTime();
    while (std.time.milliTime() - start < timeout_ms) {
        const addr = std.net.Address.parseIpv4("127.0.0.1", port) catch return MaatError.AddressParse;
const socket = try std.net.Stream.connect(addr, .{});
        _ = socket.close();
        const url = try std.fmt.allocPrint(u8, allocator, "ws://127.0.0.1:{d}", .{port});
        return url;
    }
    return MaatError.Timeout;
}

fn _environ() [][]const u8 {
    // Retorna variáveis de ambiente atuais (simplificado)
    return &[_][]const u8{};
}

pub const MaatError = error{
    Timeout,
    AllocFailed,
    InvalidAddress,
    AddressParse,
};