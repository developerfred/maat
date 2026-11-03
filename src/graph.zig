const std = @import("std");

/// A shared context store for agent communication.
///
/// Agents can publish updates to named topics and subscribe to them.
/// Each update increments a version number, allowing agents to detect
/// stale context and request refreshes without re-reading everything.
///
/// This avoids wasting context window on re-reading unchanged state.
pub const ContextStore = struct {
    topics: std.StringHashMap(Topic),
    version: u64 = 0,

    pub const Topic = struct {
        data: []u8,
        version: u64,
    };

    pub fn init(allocator: std.mem.Allocator) !ContextStore {
        return .{
            .topics = std.StringHashMap(Topic).init(allocator),
            .version = 0,
        };
    }

    pub fn deinit(self: *ContextStore) void {
        self.topics.deinit();
    }

    /// Publish an update to a topic. Returns the new global version.
    pub fn publish(
        self: *ContextStore,
        allocator: std.mem.Allocator,
        topic: []const u8,
        data: []const u8,
    ) !u64 {
        const new_data = try allocator.dupe(u8, data);
        self.version += 1;

        const topic_key = try allocator.dupe(u8, topic);
        const existing = self.topics.getPtr(topic_key);
        if (existing) |*t| {
            const topic_ptr = t.*;
            allocator.free(topic_ptr.data);
            topic_ptr.data = new_data;
            topic_ptr.version = self.version;
        } else {
            try self.topics.put(
                topic_key,
                Topic{ .data = new_data, .version = self.version },
            );
        }

        return self.version;
    }

    /// Subscribe to a topic. Returns a copy of current data and version.
    /// If the topic doesn't exist, returns error.TopicNotFound.
    pub fn subscribe(
        self: *ContextStore,
        allocator: std.mem.Allocator,
        topic: []const u8,
    ) !ContextSnapshot {
        const entry = self.topics.get(topic);
        if (entry) |e| {
            return ContextSnapshot{
                .topic = try allocator.dupe(u8, topic),
                .data = try allocator.dupe(u8, e.data),
                .version = e.version,
                .global_version = self.version,
            };
        } else {
            return error.TopicNotFound;
        }
    }

    /// Check if a topic has been updated since a given version.
    pub fn isStale(self: *ContextStore, topic: []const u8, since_version: u64) bool {
        const entry = self.topics.get(topic);
        if (entry) |e| {
            return e.version > since_version or self.version > since_version;
        } else {
            return true;
        }
    }

};

pub const ContextSnapshot = struct {
    topic: []const u8,
    data: []const u8,
    version: u64,
    global_version: u64,

    pub fn deinit(self: *ContextSnapshot, allocator: std.mem.Allocator) void {
        allocator.free(self.topic);
        allocator.free(self.data);
    }
};

pub const GraphError = error{
    TopicNotFound,
    AllocFailed,
};