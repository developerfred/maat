# Maat API Reference

Maat is a Playwright-like browser automation framework written in Zig with sandbox enabled by default.

## Installation

```bash
git clone https://github.com/developerfred/maat.git
cd maat
zig build
```

## Basic Usage

```zig
const std = @import("std");
const maat = @import("maat");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // Launch browser with sandbox enabled by default
    var browser = try maat.Browser.launch(allocator, .{
        .name = maat.BrowserName.chromium,
        .headless = false,
        .security = .{ .sandbox = true },
    });
    defer browser.close();

    // Create a new page
    var page = try browser.newPage();
    defer page.close();

    // Navigate to a URL
    try page.goto("https://example.com", maat.WaitUntil.load);

    // Interact with the page
    try page.click("button.submit");
    try page.fill("input#username", "testuser");
    try page.press("Enter");

    // Get information
    const title = try page.title();
    std.debug.print("Title: {s}\n", .{title});

    // Take screenshot
    try page.screenshot("example.png");
}
```

## API Reference

### BrowserName

```zig
pub const BrowserName = enum {
    chromium,
    firefox,
    webkit,
};
```

### AutomationProtocol

```zig
pub const AutomationProtocol = enum {
    cdp,       // Chrome DevTools Protocol (Chromium)
    webdriver, // WebDriver / BiDi (Firefox, WebKit)
};
```

### SecurityConfig

```zig
pub const SecurityConfig = struct {
    sandbox: bool = true, // enabled by default
};
```

### LaunchOptions

```zig
pub const LaunchOptions = struct {
    name: BrowserName = .chromium,
    protocol: AutomationProtocol = .cdp,
    headless: bool = true,
    security: SecurityConfig = .{ .sandbox = true },
    args: [][]const u8 = &[_][]const u8{},
    executable_path: []const u8 = "",
};
```

### WaitUntil

```zig
pub const WaitUntil = enum {
    load,
    domcontentloaded,
    networkidle,
};
```

### Browser

```zig
pub const Browser = struct {
    /// Launch a browser instance
    pub fn launch(allocator: std.mem.Allocator, opts: LaunchOptions) !Browser

    /// Create a new page/tab
    pub fn newPage(self: *Browser) !Page

    /// Close the browser
    pub fn close(self: *Browser) void
};
```

### Page

```zig
pub const Page = struct {
    /// Navigate to a URL
    pub fn goto(self: *Page, url: []const u8, wait_until: WaitUntil) !void

    /// Click on an element
    pub fn click(self: *Page, selector: []const u8) !void

    /// Fill a form field
    pub fn fill(self: *Page, selector: []const u8, value: []const u8) !void

    /// Press a keyboard key
    pub fn press(self: *Page, key: []const u8) !void

    /// Get page title
    pub fn title(self: *Page) ![]u8

    /// Take a screenshot
    pub fn screenshot(self: *Page, path: []const u8) !void

    /// Close the page
    pub fn close(self: *Page) void
};
```

### CdpClient

```zig
pub const CdpClient = struct {
    /// Connect to a browser's CDP WebSocket endpoint
    pub fn connect(allocator, host, port, path) !CdpClient

    /// Send a CDP command
    pub fn send(method, params) !u64

    /// Send a CDP command and wait for response
    pub fn call(method, params, timeout_ms) ![]const u8

    /// Close the connection
    pub fn close(self: *CdpClient) void
};
```

### ContextStore (Agent Communication Graph)

```zig
pub const ContextStore = struct {
    /// Create a new context store
    pub fn init(allocator) !ContextStore

    /// Publish an update to a topic
    pub fn publish(allocator, topic, data) !u64

    /// Subscribe to a topic
    pub fn subscribe(allocator, topic) !ContextSnapshot

    /// Check if a topic is stale
    pub fn isStale(topic, since_version) bool

    /// Deinitialize the store
    pub fn deinit(self: *ContextStore) void
};

pub const ContextSnapshot = struct {
    topic: []const u8,
    data: []const u8,
    version: u64,
    global_version: u64,
};
```

### Helper Functions

```zig
/// Find a free port for browser debug connection
pub fn findFreePort() !u16

/// Resolve executable path for a browser
pub fn resolveExecutable(opts: LaunchOptions) ![]const u8

/// Wait for debug port to open
pub fn waitForDebugPort(port: u16, timeout_ms: u64) !void

/// Get default protocol for a browser name
pub fn defaultProtocolFor(name: BrowserName) AutomationProtocol

/// Check if sandbox is enabled
pub fn isSandboxEnabled(opts: LaunchOptions) bool
```

## Security

Maat runs browsers with **sandbox enabled by default**. This differs from Playwright which often runs with `--no-sandbox` in CI environments.

To disable sandbox (trusted environments only):

```zig
var browser = try maat.Browser.launch(allocator, .{
    .security = .{ .sandbox = false },
});
```

## Error Handling

```zig
pub const MaatError = error{
    Timeout,
    AllocFailed,
};

pub const CdpError = error{
    NotConnected,
    Timeout,
    HeaderTooLarge,
    BadStatus,
    NotTextFrame,
    UnexpectedEof,
};

pub const GraphError = error{
    TopicNotFound,
    AllocFailed,
};
```

## Examples

- `src/main.zig` - Basic example
- `examples/full_example.zig` - Complete Browser + Page usage
- `examples/graph_example.zig` - Agent communication graph

## Building

```bash
# Build library and executable
zig build

# Run the example (requires Chromium)
zig build run

# Run graph example
zig build graph-example

# Run full example
zig build full-example

# Run tests
zig build test

# Check formatting
zig fmt --check src/ examples/
```

## Compatibility

Maat is developed and tested with Zig 0.17.0. See `ZIG_COMPAT_SKILL.md` for compatibility information across Zig versions.

## License

MIT