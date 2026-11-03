const std = @import("std");
const options = @import("options");
const browser = @import("browser");
const page = @import("page");
const cdp = @import("cdp");
const graph = @import("graph");
const helpers = @import("helpers");

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

// Error union for the public API.
pub const MaatError = error{
    Timeout,
    AllocFailed,
};