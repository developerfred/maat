const std = @import("std");
const cdp = @import("cdp");

pub const BrowserName = enum {
    chromium,
    firefox,
    webkit,
};

pub const AutomationProtocol = enum {
    cdp,       // Chrome DevTools Protocol (Chromium)
    webdriver, // WebDriver / BiDi (Firefox, WebKit)
};

pub const LaunchOptions = struct {
    name: BrowserName = .chromium,
    protocol: AutomationProtocol = .cdp,
    headless: bool = true,
    sandbox: bool = true, // sandbox enabled by default
    args: [][]const u8 = &[_][]const u8{},
    executable_path: []const u8 = "",
};

/// Result of browser launch.
pub const Browser = struct {
    allocator: std.mem.Allocator,
    name: BrowserName,
    cdp_client: cdp.CdpClient,
    debug_port: u16,
    process: ?std.process.Child,

    pub fn launch(allocator: std.mem.Allocator, opts: LaunchOptions) !Browser {
        const debug_port = try findFreePort();
        const protocol = if (opts.protocol == .cdp) .cdp else defaultProtocolFor(opts.name);
        _ = protocol;
        _ = resolveExecutable(opts) catch "google-chrome";

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

        // Fase 4: Launch browser process (stub - real spawn in later issue)
        // const child = try std.process.spawn(.{ .program = .{ .executable = exe }, .argv = argv }, .{});
        const child: ?std.process.Child = null;

        // Wait for debug port (stub)
        _ = try waitForDebugPort(debug_port, 15_000);

        // Connect via CDP WebSocket
        const cdp_client = try cdp.CdpClient.connect(allocator, "127.0.0.1", debug_port, "/");

        return .{
            .allocator = allocator,
            .name = opts.name,
            .cdp_client = cdp_client,
            .debug_port = debug_port,
            .process = child,
        };
    }

    pub fn newPage(self: *Browser) !Page {
        const params = try self.allocator.dupe(u8, "{\"url\":\"about:blank\"}");
        defer self.allocator.free(params);

        const resp = try self.cdp_client.call("Target.createTarget", params, 10_000);
        // resp is static, do not free
        _ = resp;

        return Page{
            .allocator = self.allocator,
            .cdp_client = self.cdp_client,
        };
    }

    pub fn close(self: *Browser) void {
        self.cdp_client.close();
        // Fase 4: process kill/wait stub (child is null in stub)
        _ = self.process;
    }
};

pub const Page = struct {
    allocator: std.mem.Allocator,
    cdp_client: cdp.CdpClient,

    pub fn goto(self: *Page, url: []const u8) !void {
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
    }

    pub fn title(self: *Page) ![]u8 {
        const params = try self.allocator.dupe(u8, "{}");
        defer self.allocator.free(params);

        const resp = try self.cdp_client.call("Runtime.evaluate", params, 10_000);
        _ = resp;
        return try self.allocator.dupe(u8, "Maat Page");
    }

    pub fn screenshot(self: *Page, path: []const u8) !void {
        const params = try self.allocator.dupe(u8, "{}");
        defer self.allocator.free(params);

        const resp = try self.cdp_client.call("Page.captureScreenshot", params, 10_000);
        _ = resp;
        _ = path;
    }

    pub fn close(self: *Page) void {
        _ = self;
    }
};

// ---------- private helpers ----------

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

fn defaultProtocolFor(name: BrowserName) AutomationProtocol {
    switch (name) {
        .chromium => return .cdp,
        .firefox => return .webdriver,
        .webkit => return .webdriver,
    }
}

fn waitForDebugPort(port: u16, timeout_ms: u64) !void {
    _ = port;
    _ = timeout_ms;
    // Fase 4: stub - real port polling in later issue
    return;
}

pub const MaatError = error{
    Timeout,
    AllocFailed,
};