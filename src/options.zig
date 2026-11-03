const std = @import("std");

/// Supported browser names.
pub const BrowserName = enum {
    chromium,
    firefox,
    webkit,
};

/// Automation protocol for each browser.
pub const AutomationProtocol = enum {
    cdp,       // Chrome DevTools Protocol (Chromium)
    webdriver, // WebDriver / BiDi (Firefox, WebKit)
};

/// Security configuration for browser launch.
pub const SecurityConfig = struct {
    /// Sandbox enabled by default. Set to false only in trusted isolated environments.
    sandbox: bool = true,
};

/// Launch options for Browser.launch.
pub const LaunchOptions = struct {
    name: BrowserName = .chromium,
    protocol: AutomationProtocol = .cdp,
    headless: bool = true,
    security: SecurityConfig = .{ .sandbox = true },
    args: [][]const u8 = &[_][]const u8{},
    executable_path: []const u8 = "",
};

/// Wait until options for page navigation.
pub const WaitUntil = enum {
    load,
    domcontentloaded,
    networkidle,
};

/// Returns the default protocol for a given browser name.
pub fn defaultProtocolFor(name: BrowserName) AutomationProtocol {
    switch (name) {
        .chromium => return .cdp,
        .firefox => return .webdriver,
        .webkit => return .webdriver,
    }
}

/// Returns true if sandbox is enabled in launch options.
pub fn isSandboxEnabled(opts: LaunchOptions) bool {
    return opts.security.sandbox;
}

/// WebKit/Safari specific notes.
pub const WebKitNotes = struct {
    /// On macOS, Safari executable is at this path.
    pub const macos_executable_path: []const u8 = "/Applications/Safari.app/Contents/MacOS/Safari";
};