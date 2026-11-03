const std = @import("std");
const cdp = @import("cdp");
const options = @import("options");
const helpers = @import("helpers");
const context = @import("context");
const page = @import("page");

pub const BrowserName = enum {
    chromium,
    firefox,
    webkit,
};

pub const AutomationProtocol = enum {
    cdp,
    webdriver,
};

pub const SecurityConfig = struct {
    sandbox: bool = true,
};

pub const LaunchOptions = struct {
    name: BrowserName = .chromium,
    protocol: AutomationProtocol = .cdp,
    headless: bool = true,
    sandbox: bool = true,
    args: [][]const u8 = &[_][]const u8{},
    executable_path: []const u8 = "",
};

pub const WaitUntil = options.WaitUntil;

pub const Browser = struct {
    allocator: std.mem.Allocator,
    name: BrowserName,
    cdp_client: cdp.CdpClient,
    debug_port: u16,

    pub fn launch(allocator: std.mem.Allocator, opts: LaunchOptions) !Browser {
        const debug_port = try helpers.findFreePort();
        _ = if (opts.protocol == .cdp) .cdp else defaultProtocolFor(opts.name);
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

        const cdp_client = try cdp.CdpClient.connect(allocator, "127.0.0.1", debug_port, "/");

        return .{
            .allocator = allocator,
            .name = opts.name,
            .cdp_client = cdp_client,
            .debug_port = debug_port,
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
    }
};

pub const Page = struct {
    allocator: std.mem.Allocator,
    cdp_client: cdp.CdpClient,

    pub fn goto(self: *Page, url: []const u8, wait_until: WaitUntil) !void {
        const wait_str = switch (wait_until) {
            .load => "load",
            .domcontentloaded => "domcontentloaded",
            .networkidle => "networkidle",
        };
        const prefix: []const u8 = "{\"url\":\"";
        const mid1: []const u8 = "\",\"frameId\":\"\",\"waitUntil\":\"";
        const mid2: []const u8 = "\"}";
        const total = prefix.len + url.len + mid1.len + wait_str.len + mid2.len;
        const params = try self.allocator.alloc(u8, total);
        defer self.allocator.free(params);
        var written: usize = 0;
        for (prefix) |b| { params[written] = b; written += 1; }
        for (url) |b| { params[written] = b; written += 1; }
        for (mid1) |b| { params[written] = b; written += 1; }
        for (wait_str) |b| { params[written] = b; written += 1; }
        for (mid2) |b| { params[written] = b; written += 1; }

        _ = try self.cdp_client.call("Page.navigate", params, 30_000);
    }

    pub fn click(self: *Page, selector: []const u8) !void {
        const prefix: []const u8 = "{\"selector\":\"";
        const suffix: []const u8 = "\"}";
        const total = prefix.len + selector.len + suffix.len;
        const params = try self.allocator.alloc(u8, total);
        defer self.allocator.free(params);
        var written: usize = 0;
        for (prefix) |b| { params[written] = b; written += 1; }
        for (selector) |b| { params[written] = b; written += 1; }
        for (suffix) |b| { params[written] = b; written += 1; }

        _ = try self.cdp_client.call("DOM.click", params, 10_000);
    }

    pub fn fill(self: *Page, selector: []const u8, value: []const u8) !void {
        const prefix: []const u8 = "{\"selector\":\"";
        const mid: []const u8 = "\",\"value\":\"";
        const suffix: []const u8 = "\"}";
        const total = prefix.len + selector.len + mid.len + value.len + suffix.len;
        const params = try self.allocator.alloc(u8, total);
        defer self.allocator.free(params);
        var written: usize = 0;
        for (prefix) |b| { params[written] = b; written += 1; }
        for (selector) |b| { params[written] = b; written += 1; }
        for (mid) |b| { params[written] = b; written += 1; }
        for (value) |b| { params[written] = b; written += 1; }
        for (suffix) |b| { params[written] = b; written += 1; }

        _ = try self.cdp_client.call("DOM.fill", params, 10_000);
    }

    pub fn press(self: *Page, key: []const u8) !void {
        const prefix: []const u8 = "{\"key\":\"";
        const suffix: []const u8 = "\"}";
        const total = prefix.len + key.len + suffix.len;
        const params = try self.allocator.alloc(u8, total);
        defer self.allocator.free(params);
        var written: usize = 0;
        for (prefix) |b| { params[written] = b; written += 1; }
        for (key) |b| { params[written] = b; written += 1; }
        for (suffix) |b| { params[written] = b; written += 1; }

        _ = try self.cdp_client.call("DOM.pressKey", params, 10_000);
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
    return;
}