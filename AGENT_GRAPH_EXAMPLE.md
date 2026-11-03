# Agent Communication Graph Example

This example demonstrates how AI agents can use the Maat ContextStore to communicate without wasting context window on re-reading unchanged state.

## The Problem

When multiple agents work on the same codebase, they need to share state. Without a shared context store, each agent must re-read all files to understand the current state, wasting context window.

## The Solution

Maat's `ContextStore` provides a versioned key-value store where agents can:
1. **Publish** updates to named topics (increments global version)
2. **Subscribe** to topics to read current data and version
3. **Check staleness** to know if a topic changed since last read
4. **List topics** to discover what other agents are working on

## Example Usage

```zig
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
```

## Benefits

| Without ContextStore | With ContextStore |
|---|---|
| Re-read all files each cycle | Read only changed topics |
| No version tracking | Automatic version increment |
| No change detection | `isStale()` detects changes |
| Context window wasted | Context window preserved |

## Run the Example

```bash
zig build graph-example
```

## API

```zig
pub const ContextStore = struct {
    pub fn init(allocator) !ContextStore
    pub fn publish(allocator, topic, data) !u64
    pub fn subscribe(allocator, topic) !ContextSnapshot
    pub fn isStale(topic, since_version) bool
    pub fn deinit(self: *ContextStore) void
};

pub const ContextSnapshot = struct {
    topic: []const u8,
    data: []const u8,
    version: u64,
    global_version: u64,
    pub fn deinit(self: *ContextSnapshot, allocator) void
};
```

## Error Handling

```zig
pub const GraphError = error{
    TopicNotFound,
    AllocFailed,
};
```

## Integration with Worktree + PR Workflow

1. Agent A creates worktree for issue #5
2. Agent A publishes status: `publish("agent-a/issue-5", "in-progress")`
3. Agent B checks: `isStale("agent-a/issue-5", last_seen_version)`
4. Agent A publishes completion: `publish("agent-a/issue-5", "done")`
5. Agent B detects change and can start dependent work

This creates a lightweight coordination layer without requiring a central server or database.