const std = @import("std");
const testing = std.testing;
const maat = @import("maat");

test "ContextStore publish and subscribe" {
    const allocator = std.heap.page_allocator;

    var store = try maat.ContextStore.init(allocator);
    defer store.deinit();

    const version = try store.publish(allocator, "test-topic", "hello");
    try testing.expectEqual(1, version);

    var snap = try store.subscribe(allocator, "test-topic");
    defer snap.deinit(allocator);
    try testing.expectEqual(true, std.mem.eql(u8, "hello", snap.data));
    try testing.expectEqual(1, snap.version);
}

test "ContextStore isStale detection" {
    const allocator = std.heap.page_allocator;

    var store = try maat.ContextStore.init(allocator);
    defer store.deinit();

    const version = try store.publish(allocator, "topic", "data");
    try testing.expectEqual(1, version);

    // Not stale at same version
    try testing.expectEqual(false, store.isStale("topic", version));

    // Publish again
    _ = try store.publish(allocator, "topic", "new data");

    // Now stale
    try testing.expectEqual(true, store.isStale("topic", version));
}

test "ContextStore subscribe nonexistent topic" {
    const allocator = std.heap.page_allocator;

    var store = try maat.ContextStore.init(allocator);
    defer store.deinit();

    const result = store.subscribe(allocator, "nonexistent");
    try testing.expectError(maat.GraphError.TopicNotFound, result);
}

test "ContextStore publish updates version" {
    const allocator = std.heap.page_allocator;

    var store = try maat.ContextStore.init(allocator);
    defer store.deinit();

    const v1 = try store.publish(allocator, "topic", "v1");
    const v2 = try store.publish(allocator, "topic", "v2");
    const v3 = try store.publish(allocator, "topic", "v3");

    try testing.expectEqual(1, v1);
    try testing.expectEqual(2, v2);
    try testing.expectEqual(3, v3);

    // Latest subscribe should return v3 data
    var snap = try store.subscribe(allocator, "topic");
    defer snap.deinit(allocator);
    try testing.expectEqual(true, std.mem.eql(u8, "v3", snap.data));
    try testing.expectEqual(3, snap.version);
}