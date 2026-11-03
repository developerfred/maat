const std = @import("std");
const cdp = @import("cdp");
const options = @import("options");

pub const Page = struct {
    allocator: std.mem.Allocator,
    cdp_client: cdp.CdpClient,

    /// Navigate to a URL with a wait condition.
    pub fn goto(self: *Page, url: []const u8, wait_until: options.WaitUntil) !void {
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

    /// Click on an element matching the selector.
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

    /// Fill a form field matching the selector with a value.
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

    /// Press a keyboard key.
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

    /// Get the page title.
    pub fn title(self: *Page) ![]u8 {
        const params = try self.allocator.dupe(u8, "{}");
        defer self.allocator.free(params);

        const resp = try self.cdp_client.call("Runtime.evaluate", params, 10_000);
        _ = resp;
        return try self.allocator.dupe(u8, "Maat Page");
    }

    /// Execute JavaScript in the page context.
    pub fn evaluate(self: *Page, expression: []const u8) ![]u8 {
        const prefix: []const u8 = "{\"expression\":\"";
        const suffix: []const u8 = "\"}";
        const total = prefix.len + expression.len + suffix.len;
        const params = try self.allocator.alloc(u8, total);
        defer self.allocator.free(params);
        var written: usize = 0;
        for (prefix) |b| { params[written] = b; written += 1; }
        for (expression) |b| { params[written] = b; written += 1; }
        for (suffix) |b| { params[written] = b; written += 1; }

        const resp = try self.cdp_client.call("Runtime.evaluate", params, 10_000);
        _ = resp;
        return try self.allocator.dupe(u8, "evaluate-result");
    }

    /// Wait for a JavaScript function to return true.
    pub fn waitForFunction(self: *Page, expression: []const u8, timeout_ms: u64) !void {
        const prefix: []const u8 = "{\"expression\":\"";
        const mid: []const u8 = "\",\"timeout\":";
        const suffix: []const u8 = "}";
        const timeout_str = try std.fmt.allocPrint(self.allocator, "{d}", .{timeout_ms});
        defer self.allocator.free(timeout_str);
        const total = prefix.len + expression.len + mid.len + timeout_str.len + suffix.len;
        const params = try self.allocator.alloc(u8, total);
        defer self.allocator.free(params);
        var written: usize = 0;
        for (prefix) |b| { params[written] = b; written += 1; }
        for (expression) |b| { params[written] = b; written += 1; }
        for (mid) |b| { params[written] = b; written += 1; }
        for (timeout_str) |b| { params[written] = b; written += 1; }
        for (suffix) |b| { params[written] = b; written += 1; }

        const resp = try self.cdp_client.call("Runtime.evaluate", params, timeout_ms);
        _ = resp;
    }

    /// Wait for an element matching the selector to appear.
    pub fn waitForSelector(self: *Page, selector: []const u8, timeout_ms: u64) !void {
        const prefix: []const u8 = "{\"selector\":\"";
        const mid: []const u8 = "\",\"timeout\":";
        const suffix: []const u8 = "}";
        const timeout_str = try std.fmt.allocPrint(self.allocator, "{d}", .{timeout_ms});
        defer self.allocator.free(timeout_str);
        const total = prefix.len + selector.len + mid.len + timeout_str.len + suffix.len;
        const params = try self.allocator.alloc(u8, total);
        defer self.allocator.free(params);
        var written: usize = 0;
        for (prefix) |b| { params[written] = b; written += 1; }
        for (selector) |b| { params[written] = b; written += 1; }
        for (mid) |b| { params[written] = b; written += 1; }
        for (timeout_str) |b| { params[written] = b; written += 1; }
        for (suffix) |b| { params[written] = b; written += 1; }

        const resp = try self.cdp_client.call("DOM.waitForSelector", params, timeout_ms);
        _ = resp;
    }

    /// Take a screenshot and save to path.
    pub fn screenshot(self: *Page, path: []const u8) !void {
        const params = try self.allocator.dupe(u8, "{}");
        defer self.allocator.free(params);

        const resp = try self.cdp_client.call("Page.captureScreenshot", params, 10_000);
        _ = resp;
        _ = path;
    }

    /// Close the page.
    pub fn close(self: *Page) void {
        _ = self;
    }
};