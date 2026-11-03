const std = @import("std");
const maat = @import("maat");
const testing = std.testing;

test "BrowserName enum has chromium, firefox, webkit" {
    try testing.expectEqual(maat.BrowserName.chromium, .chromium);
    try testing.expectEqual(maat.BrowserName.firefox, .firefox);
    try testing.expectEqual(maat.BrowserName.webkit, .webkit);
}

test "LaunchOptions defaults have sandbox enabled" {
    const opts = maat.LaunchOptions{};
    try testing.expectEqual(true, opts.security.sandbox);
}

test "isSandboxEnabled returns true when sandbox is true" {
    const opts = maat.LaunchOptions{
        .security = .{ .sandbox = true },
    };
    try testing.expectEqual(true, maat.isSandboxEnabled(opts));
}

test "isSandboxEnabled returns false when sandbox is false" {
    const opts = maat.LaunchOptions{
        .security = .{ .sandbox = false },
    };
    try testing.expectEqual(false, maat.isSandboxEnabled(opts));
}

test "defaultProtocolFor chromium returns cdp" {
    try testing.expectEqual(maat.AutomationProtocol.cdp, maat.defaultProtocolFor(.chromium));
}

test "defaultProtocolFor firefox returns webdriver" {
    try testing.expectEqual(maat.AutomationProtocol.webdriver, maat.defaultProtocolFor(.firefox));
}

test "defaultProtocolFor webkit returns webdriver" {
    try testing.expectEqual(maat.AutomationProtocol.webdriver, maat.defaultProtocolFor(.webkit));
}