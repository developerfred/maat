const std = @import("std");
const cdp = @import("cdp");
const options = @import("options");
const helpers = @import("helpers");

/// Result of browser launch.
pub const Browser = struct {
    allocator: std.mem.Allocator,
    name: options.BrowserName,
    cdp_client: cdp.CdpClient,
    debug_port: u16,
    process: ?std.process.Child,

    /// Launch a browser instance with sandbox enabled by default.
    pub fn launch(allocator: std.mem.Allocator, opts: options.LaunchOptions) !Browser {
        const debug_port = try helpers.findFreePort();
        _ = if (opts.protocol == .cdp) .cdp else options.defaultProtocolFor(opts.name);
        _ = helpers.resolveExecutable(opts) catch "google-chrome";

        var args = try std.ArrayList([]const u8).initCapacity(allocator, 8);
        defer args.deinit(allocator);

        const port_arg = try std.fmt.allocPrint(allocator, "--remote-debugging-port={d}", .{debug_port});
        defer allocator.free(port_arg);
        try args.append(allocator, port_arg);
        if (opts.headless) {
            try args.append(allocator, "--headless=new");
        }
        if (!options.isSandboxEnabled(opts)) {
            try args.append(allocator, "--no-sandbox");
        }
        for (opts.args) |arg| {
            try args.append(allocator, arg);
        }
        try args.append(allocator, "about:blank");

        const argv = try args.toOwnedSlice(allocator);
        defer allocator.free(argv);

        // Stub: browser process spawn requires std.Io instance (Zig 0.17 complexity).
        const child: ?std.process.Child = null;

        // Stub: port polling requires std.Io instance.
        _ = try helpers.waitForDebugPort(debug_port, 15_000);

        // Connect via CDP WebSocket (stub).
        const cdp_client = try cdp.CdpClient.connect(allocator, "127.0.0.1", debug_port, "/");

        return .{
            .allocator = allocator,
            .name = opts.name,
            .cdp_client = cdp_client,
            .debug_port = debug_port,
            .process = child,
        };
    }

    /// Create a new page/tab in this browser.
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

    /// Close the browser and cleanup.
    pub fn close(self: *Browser) void {
        self.cdp_client.close();
        _ = self.process;
    }
};

const page = @import("page");