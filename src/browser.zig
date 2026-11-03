const std = @import("std");
const cdp = @import("cdp");
const options = @import("options");
const helpers = @import("helpers");
const context = @import("context");

pub const Browser = struct {
    allocator: std.mem.Allocator,
    name: BrowserName,
    cdp_client: cdp.CdpClient,
    debug_port: u16,
    process: ?std.process.Child,

    pub fn launch(allocator: std.mem.Allocator, opts: options.LaunchOptions) !Browser {
        const debug_port = try helpers.findFreePort();
        _ = if (opts.protocol == .cdp) .cdp else options.defaultProtocolFor(opts.name);
        _ = resolveExecutable(opts);

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

        // Lançamento simulado (stub - navegador real será lançado separadamente)
        const child: ?std.process.Child = null;

        // Aguardar porta de depuração (stub)
        _ = try waitForDebugPort(debug_port, 15_000);

        // Conectar via CDP WebSocket (stub)
        const cdp_client = try cdp.CdpClient.connect(allocator, "127.0.0.1", debug_port, "/");

        return .{
            .allocator = allocator,
            .name = opts.name,
            .cdp_client = cdp_client,
            .debug_port = debug_port,
            .process = child,
        };
    }

    pub fn newPage(self: *Browser) !page.Page {
        const params = try self.allocator.dupe(u8, "{\"url\":\"about:blank\"}");
        defer self.allocator.free(params);

        const resp = try self.cdp_client.call("Target.createTarget", params, 10_000);
        _ = resp;

        return page.Page{
            .allocator = self.allocator,
            .cdp_client = self.cdp_client,
        };
    }

    pub fn newContext(self: *Browser) !context.BrowserContext {
        const context_id = try self.allocator.dupe(u8, "context-" ++ std.fmt.allocPrint(self.allocator, "{d}", .{self.debug_port}) catch "0");
        defer self.allocator.free(context_id);

        return context.BrowserContext{
            .allocator = self.allocator,
            .name = self.name,
            .cdp_client = self.cdp_client,
            .context_id = context_id,
        };
    }

    pub fn close(self: *Browser) void {
        self.cdp_client.close();
        if (self.process) |p| {
            _ = p.kill();
            _ = p.wait();
        }
    }
};

const page = @import("page");

fn resolveExecutable(opts: options.LaunchOptions) ![]const u8 {
    if (opts.executable_path.len > 0) return opts.executable_path;
    switch (opts.name) {
        .chromium => return "google-chrome",
        .firefox => return "firefox",
        .webkit => return "Safari",
    }
}

fn findFreePort() !u16 {
    return 9222;
}

fn waitForDebugPort(port: u16, timeout_ms: u64) !void {
    _ = port;
    _ = timeout_ms;
    return;
}