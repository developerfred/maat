const std = @import("std");
const cdp = @import("cdp");
const options = @import("options");
const helpers = @import("helpers");

/// Firefox / Marionette / WebDriver BiDi support.
///
/// Firefox uses the Marionette protocol (legacy) or WebDriver BiDi (modern).
/// Firefox must be launched with --marionette flag for Marionette protocol.
///
/// Reference: https://firefox-source-docs.mozilla.org/testing/marionette/marionette/index.html
/// Reference: https://firefox-source-docs.mozilla.org/testing/webdriver/bidi/
pub const Firefox = struct {
    /// Path to Firefox executable on macOS.
    pub const macos_executable_path: []const u8 = "/Applications/Firefox.app/Contents/MacOS/firefox";

    /// Path to Firefox executable on Linux.
    pub const linux_executable_path: []const u8 = "/usr/bin/firefox";

    /// Path to Firefox executable on Windows.
    pub const windows_executable_path: []const u8 = "C:\\Program Files\\Mozilla Firefox\\firefox.exe";

    /// Marionette default port.
    pub const marionette_port: u16 = 2828;

    /// WebDriver BiDi default port.
    pub const webdriver_bidi_port: u16 = 4444;

    /// Check if Firefox is installed on the system (macOS).
    pub const isInstalledMacos: bool = std.fs.cwd().stat(macos_executable_path) != null;

    /// Check if Firefox is installed on the system (Linux).
    pub const isInstalledLinux: bool = std.fs.cwd().stat(linux_executable_path) != null;

    /// Launch Firefox with Marionette protocol enabled.
    ///
    /// Returns the launch options configured for Firefox with Marionette.
    pub fn launchOptionsMarionette(headless: bool) options.LaunchOptions {
        return .{
            .name = .firefox,
            .protocol = .webdriver,
            .headless = headless,
            .security = .{ .sandbox = true },
            .executable_path = macos_executable_path,
            .args = &[_][]const u8{
                "--marionette",
                "--remote-debugging-port",
            },
        };
    }

    /// Launch Firefox with WebDriver BiDi protocol enabled.
    ///
    /// Returns the launch options configured for Firefox with WebDriver BiDi.
    pub fn launchOptionsWebDriverBiDi(headless: bool) options.LaunchOptions {
        return .{
            .name = .firefox,
            .protocol = .webdriver,
            .headless = headless,
            .security = .{ .sandbox = true },
            .executable_path = macos_executable_path,
            .args = &[_][]const u8{
                "--remote-debugging-port",
            },
        };
    }

    /// Get the Marionette endpoint URL.
    ///
    /// Marionette typically runs on port 2828.
    pub const marionetteEndpoint: []const u8 = "ws://localhost:2828";

    /// Connect to Firefox via Marionette.
    ///
    /// This is a stub - real Marionette implementation requires WebSocket client.
    pub fn connectViaMarionette(allocator: std.mem.Allocator, port: u16) ![]const u8 {
        _ = allocator;
        _ = port;
        return "{\"sessionId\":\"firefox-marionette\",\"value\":{}}";
    }

    /// Connect to Firefox via WebDriver BiDi.
    ///
    /// This is a stub - real WebDriver BiDi implementation requires HTTP client.
    pub fn connectViaWebDriverBiDi(allocator: std.mem.Allocator, port: u16) ![]const u8 {
        _ = allocator;
        _ = port;
        return "{\"sessionId\":\"firefox-bidi\",\"value\":{}}";
    }
};

/// Helper to check if Firefox automation is available on this system.
pub fn isFirefoxAvailable() bool {
    return Firefox.isInstalledMacos or Firefox.isInstalledLinux;
}