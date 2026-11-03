const std = @import("std");
const cdp = @import("cdp");
const options = @import("options");
const helpers = @import("helpers");

/// WebKit / Safari specific automation support.
///
/// Safari on macOS uses the WebDriver protocol (not CDP).
/// Safari must have the "Remote Automation" option enabled in the Develop menu.
///
/// Reference: https://webkit.org/blog/6904/webdriver-support-in-safari-10/
pub const WebKit = struct {
    /// Path to Safari executable on macOS.
    pub const macos_executable_path: []const u8 = "/Applications/Safari.app/Contents/MacOS/Safari";

    /// Path to safaridriver on macOS.
    pub const macos_safaridriver_path: []const u8 = "/usr/bin/safaridriver";

    /// Check if Safari is installed on the system.
    pub fn isInstalled() bool {
        return std.fs.cwd().stat(macos_executable_path) != null;
    }

    /// Check if safaridriver is available.
    pub const safaridriverIsInstalled: bool = std.fs.cwd().stat(macos_safaridriver_path) != null;

    /// Launch Safari with remote automation enabled.
    ///
    /// Returns the launch options configured for Safari.
    pub fn launchOptions(headless: bool) options.LaunchOptions {
        return .{
            .name = .webkit,
            .protocol = .webdriver,
            .headless = headless,
            .security = .{ .sandbox = true },
            .executable_path = macos_executable_path,
            .args = &[_][]const u8{},
        };
    }

    /// Get the WebDriver endpoint URL for Safari.
    ///
    /// Safari's WebDriver typically runs on port 4444 or a dynamically assigned port.
    pub const webdriverEndpoint: []const u8 = "http://localhost:4444";

    /// Connect to Safari via WebDriver.
    ///
    /// This is a stub - real WebDriver implementation requires HTTP client.
    pub fn connectViaWebDriver(allocator: std.mem.Allocator, url: []const u8) ![]const u8 {
        _ = allocator;
        _ = url;
        return "{\"sessionId\":\"safari-session\",\"value\":{}}";
    }
};

/// Helper to check if WebKit/Safari automation is available on this system.
pub fn isWebKitAvailable() bool {
    return WebKit.isInstalled() and WebKit.safaridriverIsInstalled;
}