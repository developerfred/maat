const std = @import("std");

/// Protocolo Chrome DevTools (CDP) sobre WebSocket.
///
/// Implementação mínima para automatizar Chromium/Chrome:
/// handshake HTTP Upgrade, framing de texto (mascarado cliente->servidor),
/// envio de comandos e leitura de respostas por request id.
pub const CdpClient = struct {
    ws: WebSocket,
    next_id: u64 = 1,
    allocator: std.mem.Allocator,

    pub fn connect(
        allocator: std.mem.Allocator,
        host: []const u8,
        port: u16,
        path: []const u8,
    ) !CdpClient {
        const ws = try WebSocket.connect(allocator, host, port, path);
        return .{
            .ws = ws,
            .next_id = 1,
            .allocator = allocator,
        };
    }

    /// Envia um comando CDP e retorna o request id.
    pub fn send(self: *CdpClient, method: []const u8, params: ?[]const u8) !u64 {
        const id = self.next_id;
        self.next_id += 1;

        const id_str = try std.fmt.allocPrint(u8, self.allocator, "{d}", .{id});
        defer self.allocator.free(id_str);

        const json: []const u8 = if (params) |p| p else "{}";

        const msg = try std.fmt.allocPrint(
            u8,
            self.allocator,
            "{\"id\":{s},\"method\":\"{s}\",\"params\":{s}}",
            .{ id_str, method, json },
        );
        defer self.allocator.free(msg);

        try self.ws.sendText(msg);
        return id;
    }

    /// Envia um comando e aguarda a resposta com o mesmo `id` (ou timeout).
    pub fn call(
        self: *CdpClient,
        method: []const u8,
        params: ?[]const u8,
        timeout_ms: u64,
    ) ![]u8 {
        const id = try self.send(method, params);
        const id_str = try std.fmt.allocPrint(u8, self.allocator, "\"id\":{d}", .{id});
        defer self.allocator.free(id_str);

        const start = std.time.milliTime();
        while (true) {
            if (std.time.milliTime() - start >= timeout_ms) {
                return error.Timeout;
            }

            const msg = try self.ws.recvFrame(500);
            if (std.mem.indexOf(u8, msg, id_str) != null) {
                return try self.allocator.dupe(u8, msg);
            }
            self.allocator.free(msg);
        }
    }

    pub fn close(self: *CdpClient) void {
        self.ws.close();
    }
};

pub const WebSocket = struct {
    stream: std.net.Stream,
    allocator: std.mem.Allocator,

    pub fn connect(
        allocator: std.mem.Allocator,
        host: []const u8,
        port: u16,
        path: []const u8,
    ) !WebSocket {
        var resolver = std.net.Resolver(.{});
        var addr: std.net.Address = undefined;
        const addr_res = resolver.getAddress(host, &addr, .{ .family = .Ipv4, .passive = false });
        if (addr_res) |ok| {
            addr = ok;
        } else {
            const addr_res_v6 = resolver.getAddress(host, &addr, .{ .family = .Ipv6, .passive = false });
            if (addr_res_v6) |ok| {
                addr = ok;
            } else {
                return addr_res_v6.err;
            }
        }

        const stream = try std.net.Stream.connect(addr, .{});

        const key = try generateWebSocketKey(allocator);
        defer allocator.free(key);

        const request = try std.fmt.allocPrint(
            allocator,
            "GET {s} HTTP/1.1\r\nHost: {s}:{d}\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: {s}\r\nSec-WebSocket-Version: 13\r\n\r\n",
            .{ path, host, port, key },
        );
        defer allocator.free(request);

        try stream.writeAll(request);

        var reader = std.io.bufferedReader(stream.reader());
        var header_buf: [8192]u8 = undefined;
        var header_len: usize = 0;
        while (true) {
            const line = try reader.readUntilDelimiterOrEof(&header_buf[header_len..], '\n');
            if (line.len == 0) break;
            header_len += line.len;
            if (header_len >= 4 and std.mem.eql(u8, &header_buf[header_len - 4..], "\r\n\r\n")) {
                break;
            }
            if (header_len >= header_buf.len) {
                return error.HeaderTooLarge;
            }
        }

        const status_start = header_buf[0..7];
        if (!std.mem.eql(u8, status_start, "HTTP/1.1")) {
            return error.BadStatus;
        }
        if (!std.mem.eql(u8, header_buf[9..12], "101")) {
            return error.BadStatus;
        }

        return .{
            .stream = stream,
            .allocator = allocator,
        };
    }

    /// Envia um frame de texto (mascarado, conforme requerido pelo cliente).
    pub fn sendText(self: *WebSocket, payload: []const u8) !void {
        const masked = try self.allocator.dupe(u8, payload);
        defer self.allocator.free(masked);

        const mask_key: [4]u8 = .{ 0x12, 0x34, 0x56, 0x78 };
        for (masked, 0..) |*b, i| {
            b.* = b.* ^ mask_key[i % 4];
        }

        var header: [10]u8 = undefined;
        var header_len: usize = 0;

        header[0] = 0x80; // FIN + opcode text
        header_len = 1;

        if (payload.len <= 125) {
            header[1] = 0x80 | @as(u8, @intCast(payload.len));
            header_len = 2;
        } else if (payload.len <= 65535) {
            header[1] = 0x80 | 126;
            header[2] = @as(u8, (payload.len >> 8) & 0xff);
            header[3] = @as(u8, payload.len & 0xff);
            header_len = 4;
        } else {
            header[1] = 0x80 | 127;
            header[2] = 0;
            header[3] = 0;
            header[4] = 0;
            header[5] = 0;
            header[6] = @as(u8, (payload.len >> 24) & 0xff);
            header[7] = @as(u8, (payload.len >> 16) & 0xff);
            header[8] = @as(u8, (payload.len >> 8) & 0xff);
            header[9] = @as(u8, payload.len & 0xff);
            header_len = 10;
        }

        try self.stream.writeAll(&header[0..header_len]);
        try self.stream.writeAll(masked);
    }

    /// Recebe o próximo frame de texto. Retorna o payload alocado (chamador libera).
    pub fn recvFrame(self: *WebSocket, timeout_ms: u64) ![]u8 {
        const hdr = try self.readN(2);
        const b0 = hdr[0];
        const b1 = hdr[1];

        const fin = (b0 & 0x80) != 0;
        const opcode = @as(FrameOpcode, @intCast(b0 & 0x0f));
        const masked = (b1 & 0x80) != 0;
        var len = @as(u64, b1 & 0x7f);

        if (!fin or opcode != .text) {
            var skip: u64 = len;
            if (len == 126) {
                const ext = try self.readN(2);
                len = @as(u64, @as(u8, ext[0]) << 8 | @as(u8, ext[1]));
                skip = len;
            } else if (len == 127) {
                const ext = try self.readN(8);
                len = @as(u64, @as(u8, ext[4]) << 24 | @as(u8, ext[5]) << 16 | @as(u8, ext[6]) << 8 | @as(u8, ext[7]));
                skip = len;
            }
            if (masked) {
                _ = try self.readN(4);
            }
            var skipped: u64 = 0;
            while (skipped < skip) {
                const chunk = try self.readN(min(skip - skipped, 4096));
                skipped += chunk.len;
            }
            return error.NotTextFrame;
        }

        if (len == 126) {
            const ext = try self.readN(2);
            len = @as(u64, @intCast(ext[0]) << 8 | @intCast(ext[1]));
        } else if (len == 127) {
            const ext = try self.readN(8);
            len = @as(u64, @intCast(ext[4]) << 24 | @intCast(ext[5]) << 16 | @intCast(ext[6]) << 8 | @intCast(ext[7]));
        }

        var mask_key: [4]u8 = undefined;
        if (masked) {
            const mk = try self.readN(4);
            mask_key[0] = mk[0];
            mask_key[1] = mk[1];
            mask_key[2] = mk[2];
            mask_key[3] = mk[3];
        }

        const payload = try self.allocator.alloc(u8, @intCast(len));
        const got = try self.stream.readAll(payload);
        if (got.len != @intCast(len)) {
            self.allocator.free(payload);
            return error.UnexpectedEof;
        }

        if (masked) {
            for (payload, 0..) |*b, i| {
                b.* = b.* ^ mask_key[i % 4];
            }
        }

        return payload;
    }

    pub fn close(self: *WebSocket) void {
        _ = self.stream.close();
    }

    fn readN(self: *WebSocket, n: usize) ![]const u8 {
        var out: [4096]u8 = undefined;
        var total_read: usize = 0;

        while (total_read < n) {
            const want = if (n - total_read <= out.len) n - total_read else out.len;
            const read = try self.stream.read(&out[0..want]);
            if (read.len == 0) break;
            total_read += read.len;
        }

        const result = try self.allocator.dupe(u8, &out[0..total_read]);
        return result;
    }

    fn min(a: usize, b: usize) usize {
        if (a < b) a else b;
    }
};

pub const FrameOpcode = enum(u8) {
    continuation = 0x0,
    text = 0x1,
    binary = 0x2,
    close = 0x8,
    ping = 0x9,
    pong = 0xa,
};

fn generateWebSocketKey(allocator: std.mem.Allocator) ![]u8 {
    var rand = std.rand.DefaultPrng;
    var bytes: [16]u8 = undefined;
    for (&bytes) |*b| {
        b.* = @intCast(rand.int(u8));
    }

    const encoded = try std.base64.encode(allocator, std.base64.StdEnc, &bytes);
    return encoded;
}

pub const CdpError = error{
    Timeout,
    HeaderTooLarge,
    BadStatus,
    NotTextFrame,
    UnexpectedEof,
};