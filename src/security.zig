const std = @import("std");

/// Security module for Maat - provides input validation and security utilities.
pub const Security = struct {
    /// Maximum URL length
    pub const MaxUrlLength = 2048;

    /// Maximum selector length
    pub const MaxSelectorLength = 256;

    /// Maximum key length
    pub const MaxKeyLength = 32;

    /// Maximum expression length
    pub const MaxExpressionLength = 1000;

    /// Maximum value length for fill()
    pub const MaxValueLength = 1000;

    /// Dangerous characters that should not appear in URLs
    const DangerousUrlChars = &[_]u8{
        '<', '>', '"', '\'', '&', ';', '|', '`', '$', '(', ')', '{', '}',
        '[', ']', '\\', '#', '%', '+', '!', '@', '*', '~',
    };

    /// Dangerous characters that should not appear in selectors
    const DangerousSelectorChars = &[_]u8{
        '<', '>', '"', '\'', '&', ';', '(', ')', '[', ']', '{', '}',
        '*', '!', '@', '#', '$', '%', '^', '+', '~', '`', '|', '\\',
    };

    /// Dangerous characters for keyboard keys
    const DangerousKeyChars = &[_]u8{
        '<', '>', '"', '\'', '&', ';', '(', ')', '[', ']', '{', '}',
        '*', '!', '@', '#', '$', '%', '^', '+', '~', '`', '|', '\\',
        ' ', '\t', '\n', '\r',
    };

    /// Validate URL - only http:// and https:// schemes allowed
    pub fn isValidUrl(url: []const u8) bool {
        if (url.len == 0 or url.len > MaxUrlLength) return false;

        if (std.mem.eql(u8, url[0..7], "http://")) {
            return isSafeString(url[7..], DangerousUrlChars);
        } else if (std.mem.eql(u8, url[0..8], "https://")) {
            return isSafeString(url[8..], DangerousUrlChars);
        }
        return false;
    }

    /// Validate CSS selector - no dangerous characters
    pub fn isValidSelector(selector: []const u8) bool {
        if (selector.len == 0 or selector.len > MaxSelectorLength) return false;
        return isSafeString(selector, DangerousSelectorChars);
    }

    /// Validate keyboard key - alphanumeric only
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

    /// Validate JavaScript expression - no dangerous patterns
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

    /// Validate value for fill() - no script injection
    pub fn isValidValue(value: []const u8) bool {
        if (value.len == 0 or value.len > MaxValueLength) return false;
        return isSafeString(value, DangerousSelectorChars);
    }

    /// Check if string contains dangerous characters
    fn isSafeString(text: []const u8, dangerous: []const u8) bool {
        for (text) |c| {
            for (dangerous) |d| {
                if (c == d) return false;
            }
        }
        return true;
    }

    /// Sanitize a string for safe display (remove dangerous characters)
    pub fn sanitize(input: []const u8, allocator: std.mem.Allocator) ![]u8 {
        const result = try allocator.alloc(u8, input.len);
        var written: usize = 0;
        for (input) |b| {
            if (b == '<' or b == '>' or b == '"' or b == '\'') {
                continue;
            }
            result[written] = b;
            written += 1;
        }
        return result[0..written];
    }

    /// Validate file path - no path traversal
    pub fn isValidPath(path: []const u8) bool {
        if (path.len == 0 or path.len > MaxUrlLength) return false;
        // Prevent path traversal
        if (std.mem.indexOf(u8, path, "../") != null) return false;
        if (std.mem.eql(u8, path[0..1], "/")) return false;
        return true;
    }
};