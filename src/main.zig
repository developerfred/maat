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

    try page.goto("https://example.com");
    try page.screenshot("exemplo.png");

    const title = try page.title();
    std.debug.print("Maat - Título da página: {s}\n", .{title});

    std.debug.print("Maat: automação concluída com sandbox ativo.\n", .{});
}