const std = @import("std");
const maat = @import("maat");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    std.debug.print("=== Maat Full Example ===\n", .{});

    // Launch browser with sandbox enabled by default
    var browser = try maat.Browser.launch(allocator, .{
        .name = maat.BrowserName.chromium,
        .headless = false,
        .security = .{ .sandbox = true }, // sandbox ON by default
    });
    defer browser.close();

    std.debug.print("Browser launched: {s}\n", .{switch (browser.name) {
        .chromium => "Chromium",
        .firefox => "Firefox",
        .webkit => "WebKit",
    }});

    // Create a new page
    var page = try browser.newPage();
    defer page.close();

    // Navigate to a URL
    try page.goto("https://example.com", maat.WaitUntil.load);
    std.debug.print("Navigated to https://example.com\n", .{});

    // Get page title
    const title = try page.title();
    std.debug.print("Page title: {s}\n", .{title});

    // Wait for an element to appear
    try page.waitForSelector("button.submit", 5000);
    std.debug.print("Waited for button.submit\n", .{});

    // Click on an element
    try page.click("button.submit");
    std.debug.print("Clicked button.submit\n", .{});

    // Fill a form field
    try page.fill("input#username", "testuser");
    std.debug.print("Filled input#username with 'testuser'\n", .{});

    // Press Enter
    try page.press("Enter");
    std.debug.print("Pressed Enter\n", .{});

    // Execute JavaScript
    const js_result = try page.evaluate("document.title");
    std.debug.print("JS evaluate result: {s}\n", .{js_result});

    // Take screenshot
    try page.screenshot("example.png");
    std.debug.print("Screenshot saved to example.png\n", .{});

    std.debug.print("=== Example completed successfully ===\n", .{});
}