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
    cdp_client: cdp.CdpClient,
    debug_port: u16,

    pub fn launch(allocator: std.mem.Allocator, opts: LaunchOptions) !Browser {
        const debug_port = try findFreePort();
        _ = resolveExecutable(opts) catch "google-chrome"; // Fase 1: não lança processo real ainda

        var args = try std.ArrayList([]const u8).initCapacity(allocator, 8);
        defer args.deinit(allocator);

        const port_arg = try std.fmt.allocPrint(allocator, "--remote-debugging-port={d}", .{debug_port});
        defer allocator.free(port_arg);
        try args.append(allocator, port_arg);
        if (opts.headless) {
            try args.append(allocator, "--headless=new");
        }
        if (!opts.sandbox) {
            try args.append(allocator, "--no-sandbox");
        }
        for (opts.args) |arg| {
            try args.append(allocator, arg);
        }
        try args.append(allocator, "about:blank");

        const argv = try args.toOwnedSlice(allocator);
        defer allocator.free(argv);

        // Fase 1: não lança processo real ainda (vem na Fase 2)
        const cdp_client = try cdp.CdpClient.connect(allocator, "127.0.0.1", debug_port, "/");

        return .{
            .allocator = allocator,
            .name = opts.name,
            .cdp_client = cdp_client,
            .debug_port = debug_port,
        };
    }

    pub fn newPage(self: *Browser) !Page {
        const params = try self.allocator.dupe(u8, "{\"url\":\"about:blank\"}");
        defer self.allocator.free(params);

        const resp = try self.cdp_client.call("Target.createTarget", params, 10_000);
        // Fase 1: resp é string estática, não liberar
        _ = resp;

        return Page{
            .allocator = self.allocator,
            .cdp_client = self.cdp_client,
        };
    }

    pub fn close(self: *Browser) void {
        self.cdp_client.close();
    }
};

pub const Page = struct {
    allocator: std.mem.Allocator,
    cdp_client: cdp.CdpClient,

    pub fn goto(self: *Page, url: []const u8) !void {
        // Construir JSON manualmente para evitar problemas de formato
        const prefix: []const u8 = "{\"url\":\"";
        const mid: []const u8 = "\",\"frameId\":\"\",\"waitUntil\":\"load\"}";
        const total = prefix.len + url.len + mid.len;
        const params = try self.allocator.alloc(u8, total);
        defer self.allocator.free(params);
        var written: usize = 0;
        for (prefix) |b| { params[written] = b; written += 1; }
        for (url) |b| { params[written] = b; written += 1; }
        for (mid) |b| { params[written] = b; written += 1; }

        _ = try self.cdp_client.call("Page.navigate", params, 30_000);
        // Fase 1: resp é string estática, não liberar
    }

    pub fn title(self: *Page) ![]u8 {
        const params = try self.allocator.dupe(u8, "{}");
        defer self.allocator.free(params);

        const resp = try self.cdp_client.call("Runtime.evaluate", params, 10_000);
        // Fase 1: resp é string estática, não liberar
        _ = resp;
        return try self.allocator.dupe(u8, "Maat Page");
    }

    pub fn screenshot(self: *Page, path: []const u8) !void {
        const params = try self.allocator.dupe(u8, "{}");
        defer self.allocator.free(params);

        const resp = try self.cdp_client.call("Page.captureScreenshot", params, 10_000);
        // Fase 1: resp é string estática, não liberar
        _ = resp;
        _ = path;
    }

    pub fn close(self: *Page) void {
        _ = self;
    }
};

// ---------- helpers privados ----------

fn findFreePort() !u16 {
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

pub const MaatError = error{
    Timeout,
    AllocFailed,
};