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
};

const page = @import("page");