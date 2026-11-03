const std = @import("std");

/// Wrapper para chamadas de socket do sistema operacional.
/// Usa @cImport para acessar funções de socket diretamente,
/// evitando as limitações da API std.Io.net do Zig 0.17.
pub const Socket = @cImport({
    @cInclude("sys/socket.h");
    @cInclude("netinet/in.h");
    @cInclude("arpa/inet.h");
    @cInclude("unistd.h");
});

/// Endereço IPv4 para conexão TCP.
pub const SockAddrIn = struct {
    sin_family: c_short,
    sin_port: c_ushort,
    sin_addr: [4]c_uchar,
    sin_zero: [8]c_uchar,
};

/// Cria um endereço sockaddr_in para IPv4.
pub fn makeAddr(ip: [4]c_uchar, port: u16) SockAddrIn {
    return .{
        .sin_family = 2, // AF_INET
        .sin_port = htons(port),
        .sin_addr = ip,
        .sin_zero = .{0, 0, 0, 0, 0, 0, 0, 0},
    };
}

/// Converte porta para network byte order.
pub fn htons(port: u16) c_ushort {
    return @bitSwap(u16, port);
}

/// Converte string IP para array de 4 bytes.
pub fn parseIp4(str: []const u8) ![]const u8 {
    // Formato esperado: "127.0.0.1"
    if (str.len < 7 or str.len > 15) return error.InvalidAddress;
    var octets: [4]u8 = undefined;
    var octet_idx: usize = 0;
    var num: u8 = 0;
    for (str) |c| {
        if (c >= '0' and c <= '9') {
            num = num * 10 + (c - '0');
        } else if (c == '.') {
            if (octet_idx >= 4) return error.InvalidAddress;
            octets[octet_idx] = num;
            octet_idx += 1;
            num = 0;
        } else {
            return error.InvalidAddress;
        }
    }
    if (octet_idx != 3) return error.InvalidAddress;
    octets[3] = num;
    return &octets;
}

/// Cria um socket TCP.
pub fn socket() !c_int {
    const fd = Socket.socket(2, 1, 0); // AF_INET, SOCK_STREAM, 0
    if (fd < 0) return error.SocketCreationFailed;
    return fd;
}

/// Conecta um socket a um endereço remoto.
pub fn connect(fd: c_int, addr: *SockAddrIn) !void {
    const ret = Socket.connect(fd, addr, @sizeOf(SockAddrIn));
    if (ret < 0) return error.ConnectionFailed;
}

/// Envia dados através de um socket.
pub fn send(fd: c_int, data: []const u8) !void {
    var sent: usize = 0;
    while (sent < data.len) {
        const n = Socket.send(fd, data[sent..], 0);
        if (n < 0) return error.SendFailed;
        sent += n;
    }
}

/// Recebe dados de um socket (até n bytes ou conexão fechada).
pub fn recv(fd: c_int, buf: []u8) !usize {
    const n = Socket.recv(fd, buf, 0);
    if (n < 0) return error.RecvFailed;
    return n;
}

/// Fecha um socket.
pub fn close(fd: c_int) void {
    Socket.close(fd);
}

pub const SocketError = error{
    SocketCreationFailed,
    ConnectionFailed,
    SendFailed,
    RecvFailed,
    InvalidAddress,
};