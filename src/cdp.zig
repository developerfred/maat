const std = @import("std");

/// Protocolo Chrome DevTools (CDP) sobre WebSocket.
///
/// Fase 1: stub funcional que compila e roda.
/// A implementação real de WebSocket + rede TCP vem na Fase 2 (Issue 4: CDP Chromium).
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
        // Fase 1: simula conexão bem-sucedida
        // Fase 2: implementar TCP connect + handshake HTTP Upgrade
        return .{
            .allocator = allocator,
            .next_id = 1,
            .connected = true,
        };
    }

    pub fn send(self: *CdpClient, method: []const u8, params: ?[]const u8) !u64 {
        if (!self.connected) {
            return error.NotConnected;
        }
        const id = self.next_id;
        self.next_id += 1;
        _ = method;
        _ = params;
        return id;
    }

    pub fn call(
        self: *CdpClient,
        method: []const u8,
        params: ?[]const u8,
        timeout_ms: u64,
    ) ![]const u8 {
        _ = timeout_ms;
        if (!self.connected) {
            return error.NotConnected;
        }
        const id = try self.send(method, params);
        _ = id;
        // Resposta JSON estática (não alocada, não precisa liberar)
        return "{\"id\":0,\"result\":{}}";
    }

    pub fn close(self: *CdpClient) void {
        self.connected = false;
    }
};

pub const CdpError = error{
    NotConnected,
    Timeout,
    UnexpectedEof,
};