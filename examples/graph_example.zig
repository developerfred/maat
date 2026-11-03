const std = @import("std");
const maat = @import("maat");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // Create the shared context store (graph)
    var store = try maat.ContextStore.init(allocator);
    defer store.deinit();

    // Agent A publishes its status
    const version_a = try store.publish(allocator, "agent-a/status", "idle");
    std.debug.print("Agent A published status, version: {d}\n", .{version_a});

    // Agent B publishes its status
    const version_b = try store.publish(allocator, "agent-b/status", "working");
    std.debug.print("Agent B published status, version: {d}\n", .{version_b});

    // Agent A subscribes to Agent B's topic
    var snap_b = try store.subscribe(allocator, "agent-b/status");
    std.debug.print("Agent A read agent-b: {s} (version {d})\n", .{snap_b.data, snap_b.version});
    snap_b.deinit(allocator);

    // Check if topic is stale
    const stale = store.isStale("agent-a/status", version_a);
    std.debug.print("Agent-a/status is stale: {}\n", .{stale});

    std.debug.print("Graph example completed.\n", .{});
}