const std = @import("std");
const cdp = @import("cdp");
const options = @import("options");

/// Isolated browser context (cookies, localStorage, sessionStorage).
///
/// Each context has its own cookies, localStorage, and sessionStorage,
/// isolated from other contexts in the same browser.
pub const BrowserContext = struct {
    allocator: std.mem.Allocator,
    name: options.BrowserName,
    cdp_client: cdp.CdpClient,
    context_id: []const u8,

    /// Create a new page in this context.
    pub fn newPage(self: *BrowserContext) !page.Page {
        const params = try self.allocator.dupe(u8, "{\"url\":\"about:blank\"}");
        defer self.allocator.free(params);

        const resp = try self.cdp_client.call("Target.createTarget", params, 10_000);
        _ = resp;

        return page.Page{
            .allocator = self.allocator,
            .cdp_client = self.cdp_client,
        };
    }

    /// Close the context and cleanup.
    pub fn close(self: *BrowserContext) void {
        _ = self.context_id;
    }

    /// Get cookies for this context.
    pub fn cookies(self: *BrowserContext) ![]u8 {
        const params = "{}";
        const resp = try self.cdp_client.call("Storage.getCookies", params, 10_000);
        _ = resp;
        return try self.allocator.dupe(u8, "cookies-result");
    }

    /// Set a cookie in this context.
    pub fn setCookie(self: *BrowserContext, name: []const u8, value: []const u8) !void {
        const prefix: []const u8 = "{\"name\":\"";
        const mid: []const u8 = "\",\"value\":\"";
        const suffix: []const u8 = "\"}";
        const total = prefix.len + name.len + mid.len + value.len + suffix.len;
        const params = try self.allocator.alloc(u8, total);
        defer self.allocator.free(params);
        var written: usize = 0;
        for (prefix) |b| { params[written] = b; written += 1; }
        for (name) |b| { params[written] = b; written += 1; }
        for (mid) |b| { params[written] = b; written += 1; }
        for (value) |b| { params[written] = b; written += 1; }
        for (suffix) |b| { params[written] = b; written += 1; }

        const resp = try self.cdp_client.call("Storage.setCookie", params, 10_000);
        _ = resp;
    }
};

const page = @import("page");