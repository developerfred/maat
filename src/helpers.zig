const std = @import("std");
const options = @import("options");

/// Finds a free port for browser debug connection.
/// Stub: returns fixed port 9222. Real implementation queries the OS.
pub fn findFreePort() !u16 {
    return 9222;
}

/// Resolves the executable path for a given browser.
pub fn resolveExecutable(opts: options.LaunchOptions) ![]const u8 {
    if (opts.executable_path.len > 0) return opts.executable_path;
    switch (opts.name) {
        .chromium => return "google-chrome",
        .firefox => return "firefox",
        .webkit => return "Safari",
    }
}

/// Waits for the browser debug port to open.
/// Stub: returns immediately. Real implementation polls the port.
pub fn waitForDebugPort(port: u16, timeout_ms: u64) !void {
    _ = port;
    _ = timeout_ms;
    // Real port polling needs std.Io instance (Zig 0.17 complexity).
    return;
}