const std = @import("std");

/// Protocolo Chrome DevTools (CDP) sobre WebSocket.
pub const CdpClient = struct {
    allocator: std.mem.Allocator,
    next_id: u64 = 1,
    connected: bool = false,

    pub fn connect(
        allocator: std.mem.Allocator,
        host: []const u8,
        port: u16,
        path: []const u8,
    ) !CdpClient {
        _ = host;
        _ = port;
        _ = path;
        return .{
            .allocator = allocator,
            .next_id = 1,
            .connected = false,
        };
    }

    pub fn send(self: *CdpClient, method: []const u8, params: ?[]const u8) !u64 {
        if (!self.connected) {
            return error.NotConnected;
        }
        _ = method;
        _ = params;
        const id = self.next_id;
        self.next_id += 1;
        return id;
    }

    pub fn call(
        self: *CdpClient,
        method: []const u8,
        params: ?[]const u8,
        timeout_ms: u64,
    ) ![]u8 {
        if (!self.connected) {
            return error.NotConnected;
        }
        _ = method;
        _ = params;
        _ = timeout_ms;
        return error.NotConnected;
    }

    pub fn close(self: *CdpClient) void {
        self.connected = false;
    }
};

pub const WebSocketOpcode = enum(u8) {
    continuation = 0x0,
    text = 0x1,
    binary = 0x2,
    close = 0x8,
    ping = 0x9,
    pong = 0xa,
};

fn intToStr(allocator: std.mem.Allocator, val: u64) ![]u8 {
    const buf_size = 20;
    var buf: [buf_size]u8 = undefined;
    var len: usize = 0;
    var v: u64 = val;
    if (v == 0) {
        buf[0] = '0';
        len = 1;
    } else {
        while (v > 0) {
            const digit = @as(u8, @intCast(v % 10));
            buf[buf_size - 1 - len] = @as(u8, @as(u8, '0') + digit);
            v /= 10;
            len += 1;
        }
    }
    const start = buf_size - len;
    const result = try allocator.alloc(u8, len);
    for (buf[start..], 0..) |b, i| {
        result[i] = b;
    }
    return result;
}

pub const CdpError = error{
    NotConnected,
    Timeout,
    HeaderTooLarge,
    BadStatus,
    NotTextFrame,
    UnexpectedEof,
};
