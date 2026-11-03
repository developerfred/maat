const std = @import("std");
const Io = std.Io;
const options = @import("options");
const browser = @import("browser");
const page = @import("page");
const cdp = @import("cdp");
const graph = @import("graph");
const helpers = @import("helpers");
const context = @import("context");
const webkit = @import("webkit");
const firefox = @import("firefox");

// Re-export options
pub const BrowserName = options.BrowserName;
pub const AutomationProtocol = options.AutomationProtocol;
pub const SecurityConfig = options.SecurityConfig;
pub const LaunchOptions = options.LaunchOptions;
pub const WaitUntil = options.WaitUntil;
pub const WebKitNotes = options.WebKitNotes;
pub const defaultProtocolFor = options.defaultProtocolFor;
pub const isSandboxEnabled = options.isSandboxEnabled;

// Re-export helpers
pub const findFreePort = helpers.findFreePort;
pub const resolveExecutable = helpers.resolveExecutable;
pub const waitForDebugPort = helpers.waitForDebugPort;

// Re-export graph
pub const ContextStore = graph.ContextStore;
pub const ContextSnapshot = graph.ContextSnapshot;
pub const GraphError = graph.GraphError;

// Re-export CDP
pub const CdpClient = cdp.CdpClient;
pub const CdpError = cdp.CdpError;

// Re-export browser and page
pub const Browser = browser.Browser;
pub const Page = page.Page;
pub const BrowserContext = context.BrowserContext;
pub const WebKit = webkit.WebKit;
pub const isWebKitAvailable = webkit.isWebKitAvailable;
pub const Firefox = firefox.Firefox;
pub const isFirefoxAvailable = firefox.isFirefoxAvailable;

// Re-export page validation
pub const isValidUrl = page.isValidUrl;
pub const isValidSelector = page.isValidSelector;
pub const isValidKey = page.isValidKey;

// Error union for the public API.
pub const MaatError = error{
    Timeout,
    AllocFailed,
    InvalidUrl,
    InvalidSelector,
    InvalidKey,
    ValueTooLong,
    ExpressionTooLong,
};