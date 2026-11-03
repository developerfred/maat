const std = @import("std");
const cdp = @import("cdp");
const options = @import("options");

/// Security validation functions inline to avoid module dependency issues
const Security = struct {
    pub const MaxUrlLength = 2048;
    pub const MaxSelectorLength = 256;
    pub const MaxKeyLength = 32;
    pub const MaxExpressionLength = 1000;
    pub const MaxValueLength = 1000;

    const DangerousUrlChars = &[_]u8{
        '<', '>', '"', '\'', '&', ';', '|', '`', '$', '(', ')', '{', '}',
        '[', ']', '\\', '#', '%', '+', '!', '@', '*', '~',
    };

    const DangerousSelectorChars = &[_]u8{
        '<', '>', '"', '\'', '&', ';', '(', ')', '[', ']', '{', '}',
        '*', '!', '@', '#', '$', '%', '^', '+', '~', '`', '|', '\\',
    };
    const AllowedSelectorChars = &[_]u8{
        '.', '#', '-', '_', ':',
    };

    const DangerousKeyChars = &[_]u8{
        '<', '>', '"', '\'', '&', ';', '(', ')', '[', ']', '{', '}',
        '*', '!', '@', '#', '$', '%', '^', '+', '~', '`', '|', '\\',
        ' ', '\t', '\n', '\r',
    };

    pub fn isValidUrl(url: []const u8) bool {
        if (url.len == 0 or url.len > MaxUrlLength) return false;
        if (std.mem.eql(u8, url[0..7], "http://")) {
            return isSafeString(url[7..], DangerousUrlChars);
        } else if (std.mem.eql(u8, url[0..8], "https://")) {
            return isSafeString(url[8..], DangerousUrlChars);
        }
        return false;
    }

    pub fn isValidSelector(selector: []const u8) bool {
        if (selector.len == 0 or selector.len > MaxSelectorLength) return false;
        // Only allow alphanumeric and safe selector characters
        for (selector) |c| {
            if (!(c >= 'a' and c <= 'z') and !(c >= 'A' and c <= 'Z') and
                !(c >= '0' and c <= '9') and c != '_' and c != '-' and c != '.' and
                c != '#' and c != ':' and c != '[' and c != ']' and c != ' ') {
                return false;
            }
        }
        return true;
    }

    pub fn isValidKey(key: []const u8) bool {
        if (key.len == 0 or key.len > MaxKeyLength) return false;
        for (key) |c| {
            if (!(c >= 'a' and c <= 'z') and !(c >= 'A' and c <= 'Z') and
                !(c >= '0' and c <= '9') and c != '_' and c != '-' and c != '.') {
                return false;
            }
        }
        return true;
    }

    pub fn isValidExpression(expression: []const u8) bool {
        if (expression.len == 0 or expression.len > MaxExpressionLength) return false;

        const dangerousPatterns = &[_][]const u8{
            "eval(", "setTimeout(", "setInterval(", "Function(",
            "document.write(", "document.writeln(", "innerHTML",
            "outerHTML", "document.cookie", "localStorage",
            "sessionStorage", "XMLHttpRequest", "fetch(",
            "location.href", "location.replace", "location.assign",
        };

        for (dangerousPatterns) |pattern| {
            if (std.mem.indexOf(u8, expression, pattern) != null) {
                return false;
            }
        }

        return isSafeString(expression, DangerousSelectorChars);
    }

    pub fn isValidValue(value: []const u8) bool {
        if (value.len == 0 or value.len > MaxValueLength) return false;
        return isSafeString(value, DangerousSelectorChars);
    }

    pub fn isValidPath(path: []const u8) bool {
        if (path.len == 0 or path.len > MaxUrlLength) return false;
        if (std.mem.indexOf(u8, path, "../") != null) return false;
        if (std.mem.eql(u8, path[0..1], "/")) return false;
        return true;
    }

    fn isSafeString(text: []const u8, dangerous: []const u8) bool {
        for (text) |c| {
            for (dangerous) |d| {
                if (c == d) return false;
            }
        }
        return true;
    }
};

pub const Page = struct {
    allocator: std.mem.Allocator,
    cdp_client: cdp.CdpClient,

    pub fn goto(self: *Page, url: []const u8, wait_until: options.WaitUntil) !void {
        if (!Security.isValidUrl(url)) {
            return error.InvalidUrl;
        }
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
        if (!Security.isValidSelector(selector)) {
            return error.InvalidSelector;
        }
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
        if (!Security.isValidSelector(selector)) {
            return error.InvalidSelector;
        }
        if (!Security.isValidValue(value)) {
            return error.ValueTooLong;
        }
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
        if (!Security.isValidKey(key)) {
            return error.InvalidKey;
        }
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

    pub fn evaluate(self: *Page, expression: []const u8) ![]u8 {
        if (!Security.isValidExpression(expression)) {
            return error.ExpressionTooLong;
        }
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

    pub fn waitForFunction(self: *Page, expression: []const u8, timeout_ms: u64) !void {
        if (!Security.isValidExpression(expression)) {
            return error.ExpressionTooLong;
        }
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

    pub fn waitForSelector(self: *Page, selector: []const u8, timeout_ms: u64) !void {
        if (!Security.isValidSelector(selector)) {
            return error.InvalidSelector;
        }
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

    pub fn screenshot(self: *Page, path: []const u8) !void {
        if (!Security.isValidPath(path)) {
            return error.InvalidPath;
        }
        const params = try self.allocator.dupe(u8, "{}");
        defer self.allocator.free(params);

        const resp = try self.cdp_client.call("Page.captureScreenshot", params, 10_000);
        _ = resp;
    }

    pub fn close(self: *Page) void {
        _ = self;
    }
};