# Maat

**Maat** is a Playwright-like browser automation framework written in **Zig**, focused on **memory safety** and **sandbox enabled by default**.

## Why Maat?

In Egyptian mythology, Maat is the goddess of truth, order, and justice. For browser automation, this means:

- **Order**: a unified and predictable API for any browser.
- **Truth**: deterministic and reliable tests.
- **Justice/Protection**: **sandbox enabled by default**, unlike Playwright which often runs with `--no-sandbox` in CI.

## Scope

Maat **does not reimplement browser engines**. It orchestrates real browsers already installed on the system (Chromium, Firefox, WebKit/Safari) through their native automation protocols (CDP, WebDriver BiDi, etc.), while the control, network, and protocol layer is written in **Zig**, leveraging the language's memory safety.

## Supported Browsers (planned)

| Browser | Protocol | Status |
|-----------|-----------|--------|
| Chromium / Chrome | Chrome DevTools Protocol (CDP) | In development |
| Firefox | WebDriver BiDi / Marionette | Planned |
| WebKit / Safari | WebDriver / Remote Debugging | Planned |

## Requirements

- Zig 0.17.0+
- A browser installed on the system

## Build and Run

```sh
zig build            # compiles library and example
zig build run        # runs the example
zig build test       # runs tests
zig build graph-example  # runs agent communication graph example
zig build full-example   # runs complete Browser + Page example
```

## Usage Example

```zig
const std = @import("std");
const maat = @import("maat");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // Sandbox enabled by default
    var browser = try maat.Browser.launch(allocator, .{
        .name = maat.BrowserName.chromium,
        .headless = false,
        .security = .{ .sandbox = true },
    });
    defer browser.close();

    var page = try browser.newPage();
    defer page.close();

    try page.goto("https://example.com", maat.WaitUntil.load);
    try page.screenshot("example.png");

    std.debug.print("Title: {s}\n", .{try page.title()});
}
```

## Security and Sandbox

**Sandbox is enabled by default**. If you need to disable it (only in isolated, trusted environments), pass `.security = .{ .sandbox = false }`. This recreates exactly the insecure Playwright default behavior and is **not recommended for production**.

The cited CVEs (CVE-2026-118306, CVE-2026-118331, CVE-2026-118348, CVE-2026-118344) affect the Playwright/browser ecosystem. Reimplementing the orchestration layer in Zig reduces the attack surface written in unsafe languages, but **does not remove vulnerabilities intrinsic to the browser engine**. Keep your browsers updated.

## Issues and Planning

All functionality is tracked as **GitHub issues** (no dates) and developed in **separate worktrees** with **pull requests**. See [`ISSUES_PLANEJADAS.md`](ISSUES_PLANEJADAS.md) for the complete list.

## Workflow

Each issue is developed as follows:

1. Create a **issue** on GitHub (no date).
2. Create a **worktree** in a dedicated branch: `git worktree add ../maat-<issue> -b issue-<number>-<slug>`
3. Implement, test, and commit in the worktree.
4. Open a **pull request** to `main`.
5. After merge, remove the worktree.

## Agent Skills

See `AGENT_SKILL_ISSUES.md`, `AGENT_SKILL_ZIG_BUILD.md`, and `AGENT_SKILL_WORKFLOW.md` for AI agent guidance on working with this project.

## Zig Compatibility

See `ZIG_COMPAT_SKILL.md` for compatibility information across Zig versions (0.11 → master).

## API Reference

See `API_REFERENCE.md` for complete API documentation.

## License

MIT