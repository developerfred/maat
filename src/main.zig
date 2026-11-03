const std = @import("std");
const maat = @import("maat");

pub fn main() !void {
    try runExample(std.heap.page_allocator);
}

fn runExample(allocator: std.mem.Allocator) !void {
    var browser = try maat.Browser.launch(allocator, .{
        .name = maat.BrowserName.chromium,
        .headless = false,
        .security = .{ .sandbox = true }, // sandbox enabled by default
    });
    defer browser.close();

    var page = try browser.newPage();
    defer page.close();

    // Navigate with waitUntil option
    try page.goto("https://example.com", maat.WaitUntil.load);

    // Click on an element
    try page.click("button.submit");

    // Fill a form field
    try page.fill("input#username", "testuser");

    // Press a key
    try page.press("Enter");

    // Get page title
    const title = try page.title();
    std.debug.print("Maat - Page title: {s}\n", .{title});

    // Execute JavaScript
    const js_result = try page.evaluate("document.title");
    std.debug.print("JS evaluate result: {s}\n", .{js_result});

    // Take screenshot
    try page.screenshot("example.png");

    std.debug.print("Maat: automation completed with sandbox active.\n", .{});
}

fn printHelp() void {
    std.debug.print("Maaat - Playwright-like browser automation in Zig\n", .{});
    std.debug.print("Usage: maat <command>\n\n", .{});
    std.debug.print("Commands:\n", .{});
    std.debug.print("  run       Launch browser and run example automation\n", .{});
    std.debug.print("  example   Same as run\n", .{});
    std.debug.print("  help      Show this help message\n\n", .{});
    std.debug.print("Options:\n", .{});
    std.debug.print("  --sandbox   Enable sandbox (default: true)\n\n", .{});
    std.debug.print("Examples:\\n", .{});
    std.debug.print("  maat run\\n", .{});
    std.debug.print("  maat example\\n", .{});
    std.debug.print("  maat help\\n\\n", .{});
    std.debug.print("Sandbox is enabled by default for security.\\n", .{});
}