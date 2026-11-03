const std = @import("std");

/// Rate limiter to prevent DoS attacks.
/// Limits the number of operations per time window.
pub const RateLimiter = struct {
    requests: []u64,
    count: usize,
    maxRequests: usize,
    windowMs: u64,
    startTime: u64,

    pub fn init(allocator: std.mem.Allocator, maxRequests: usize, windowMs: u64) !RateLimiter {
        const requests = try allocator.alloc(u64, maxRequests);
        return .{
            .requests = requests,
            .count = 0,
            .maxRequests = maxRequests,
            .windowMs = windowMs,
            .startTime = std.time.milliTime(),
        };
    }

    pub fn deinit(self: *RateLimiter, allocator: std.mem.Allocator) void {
        allocator.free(self.requests);
    }

    /// Check if request is allowed based on rate limit.
    /// Returns true if request is allowed, false if rate limited.
    pub fn check(self: *RateLimiter) bool {
        const now = std.time.milliTime();

        // Reset window if time has passed
        if (now - self.startTime >= self.windowMs) {
            self.startTime = now;
            self.count = 0;
        }

        // Check if we've exceeded the limit
        if (self.count >= self.maxRequests) return false;

        // Allow request and increment counter
        self.requests[self.count] = now;
        self.count += 1;
        return true;
    }

    /// Get remaining requests in current window
    pub fn remaining(self: *RateLimiter) u64 {
        if (self.count >= self.maxRequests) return 0;
        return self.maxRequests - self.count;
    }

    /// Get time until window resets in milliseconds
    pub fn resetTime(self: *RateLimiter) u64 {
        const now = std.time.milliTime();
        if (now < self.startTime + self.windowMs) {
            return self.startTime + self.windowMs - now;
        }
        return 0;
    }
};