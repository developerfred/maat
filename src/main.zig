const std = @import("std");
const maat = @import("maat");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

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
    std.debug.print("Maat - Título da página: {s}\n", .{title});

    // Take screenshot
    try page.screenshot("exemplo.png");

    std.debug.print("Maat: automação concluída com sandbox ativo.\n", .{});
}