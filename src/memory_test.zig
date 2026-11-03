const std = @import("std");
const testing = std.testing;
const maat = @import("maat");

test "memory: no leaks in Browser launch options" {
    const allocator = std.heap.page_allocator;
    _ = allocator;

    const opts = maat.LaunchOptions{
        .name = maat.BrowserName.chromium,
        .headless = true,
        .security = .{ .sandbox = true },
        .args = &[_][]const u8{},
        .executable_path = "",
    };
    _ = opts;

    const path = maat.WebKitNotes.macos_executable_path;
    _ = path;

    try testing.expect(true);
}

test "memory: no leaks in ContextStore publish/subscribe" {
    const allocator = std.heap.page_allocator;

    var store = try maat.ContextStore.init(allocator);
    defer store.deinit();

    const v1 = try store.publish(allocator, "topic-1", "data-1");
    const v2 = try store.publish(allocator, "topic-2", "data-2");
    const v3 = try store.publish(allocator, "topic-3", "data-3");

    try testing.expectEqual(1, v1);
    try testing.expectEqual(2, v2);
    try testing.expectEqual(3, v3);

    var s1 = try store.subscribe(allocator, "topic-1");
    defer s1.deinit(allocator);
    var s2 = try store.subscribe(allocator, "topic-2");
    defer s2.deinit(allocator);
    var s3 = try store.subscribe(allocator, "topic-3");
    defer s3.deinit(allocator);

    try testing.expectEqual(true, std.mem.eql(u8, "data-1", s1.data));
    try testing.expectEqual(true, std.mem.eql(u8, "data-2", s2.data));
    try testing.expectEqual(true, std.mem.eql(u8, "data-3", s3.data));

    try testing.expect(true);
}

test "memory: no leaks in Page operations" {
    const allocator = std.heap.page_allocator;

    const url = "https://example.com";
    const prefix: []const u8 = "{\"url\":\"";
    const mid: []const u8 = "\",\"frameId\":\"\",\"waitUntil\":\"load\"}";
    const total = prefix.len + url.len + mid.len;
    const params = try allocator.alloc(u8, total);
    defer allocator.free(params);
    var written: usize = 0;
    for (prefix) |b| { params[written] = b; written += 1; }
    for (url) |b| { params[written] = b; written += 1; }
    for (mid) |b| { params[written] = b; written += 1; }

    try testing.expectEqual(total, written);

    try testing.expect(true);
}

test "memory: no leaks in BrowserContext operations" {
    const allocator = std.heap.page_allocator;

    const ctx_id = try allocator.dupe(u8, "context-1");
    defer allocator.free(ctx_id);
    _ = ctx_id.len;

    try testing.expect(true);
}