const std = @import("std");

/// Cliente WebSocket para Chrome DevTools Protocol.
/// Implementação stub - a implementação real de rede requer Zig 0.18+ com API de rede estável.
pub const WebSocketClient = struct {
    connected: bool = false,

    pub fn connect(
        allocator: std.mem.Allocator,
        host: []const u8,
        port: u16,
        path: []const u8,
    ) !WebSocketClient {
        _ = allocator;
        _ = host;
        _ = port;
        _ = path;
        return .{
            .connected = true,
        };
    }

    pub fn sendText(self: *WebSocketClient, payload: []const u8) !void {
        _ = self;
        _ = payload;
    }

    pub fn recvFrame(self: *WebSocketClient) ![]u8 {
        return error.NotTextFrame;
    }

    pub fn close(self: *WebSocketClient) void {
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

pub const WebSocketError = error{
    NotConnected,
    Timeout,
    HeaderTooLarge,
    BadStatus,
    NotTextFrame,
    UnexpectedEof,
};