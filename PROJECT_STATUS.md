# Maat Project Status

## Current Version: v0.2.0

## Completed Features

### Core Architecture
- [x] Modular code structure (options.zig, helpers.zig, browser.zig, page.zig, graph.zig, cdp.zig, maat.zig)
- [x] BrowserName enum (chromium, firefox, webkit)
- [x] AutomationProtocol enum (cdp, webdriver)
- [x] SecurityConfig with sandbox enabled by default
- [x] LaunchOptions with all configuration fields
- [x] WaitUntil enum (load, domcontentloaded, networkidle)
- [x] WebKitNotes with macOS Safari path

### Browser Operations
- [x] Browser.launch() with sandbox by default
- [x] Browser.newPage()
- [x] Browser.close()
- [x] Page.goto() with WaitUntil option
- [x] Page.click()
- [x] Page.fill()
- [x] Page.press()
- [x] Page.title()
- [x] Page.screenshot()
- [x] Page.close()

### Agent Communication Graph
- [x] ContextStore with publish/subscribe
- [x] Version-based change detection (isStale)
- [x] ContextSnapshot with data and version
- [x] GraphError (TopicNotFound, AllocFailed)
- [x] Agent communication examples

### CDP Client
- [x] CdpClient structure (stub)
- [x] connect/send/call/close methods
- [x] Static JSON response stub
- [x] WebSocket framing structure (for future implementation)

### Build System
- [x] build.zig with module dependencies
- [x] build.zig.zon package manifest
- [x] Zig 0.17.0 compatible
- [x] Multiple executables: maat, graph-example, full-example
- [x] Test modules: main tests, graph tests

### CI/CD
- [x] GitHub Actions CI (Ubuntu, macOS, Windows)
- [x] Multi-version Zig build matrix (0.11.0 to 0.18.0)
- [x] GitHub Pages deployment
- [x] Release workflow (GitHub Releases)

### Documentation
- [x] README.md (English)
- [x] API_REFERENCE.md
- [x] ZIG_COMPAT_SKILL.md (for AI agents)
- [x] AGENT_SKILL_ISSUES.md
- [x] AGENT_SKILL_ZIG_BUILD.md
- [x] AGENT_SKILL_WORKFLOW.md
- [x] AGENT_GRAPH_EXAMPLE.md
- [x] ISSUES_PLANEJADAS.md (23 issues)
- [x] CONTRIBUTING.md
- [x] DESAFIOS.md
- [x] PROJECT_STATUS.md

### Landing Page
- [x] Brutalist Swiss design
- [x] English + Portuguese sections
- [x] SEO meta tags
- [x] CVE badges
- [x] Code examples
- [x] GitHub Pages (gh-pages branch)

## In Progress

### WebSocket Real Implementation
- [ ] std.Io instance creation (Zig 0.17 complexity)
- [ ] TCP connection
- [ ] HTTP Upgrade handshake
- [ ] WebSocket framing (mask, opcode, length)
- [ ] Real CDP communication

### Process Management
- [ ] Real browser process spawn
- [ ] Process kill/wait
- [ ] Debug port polling

## Planned (v0.3.0+)

- [ ] Real WebSocket implementation
- [ ] Real process spawn
- [ ] Page.evaluate() for JavaScript execution
- [ ] Page.waitForSelector()
- [ ] BrowserContext (isolated contexts)
- [ ] Multiple pages per browser
- [ ] Download/upload file support
- [ ] Keyboard/mouse automation
- [ ] Frame handling

## Issues

23 issues planned across 6 phases. See `ISSUES_PLANEJADAS.md` for complete list.

### Phase 1: Structure & Build (Issues 1-3) - COMPLETED
### Phase 2: Multi-browser Support (Issues 4-7) - COMPLETED (stubs)
### Phase 3: Security & Sandbox (Issues 8-10) - COMPLETED
### Phase 4: Page Operations (Issues 11-17) - COMPLETED (stubs)
### Phase 5: Context & Isolation (Issues 16-17) - PARTIAL
### Phase 6: Examples, Docs & CI (Issues 18-23) - COMPLETED

## Security

- [x] Sandbox enabled by default
- [x] No `--no-sandbox` unless explicitly opted out
- [x] Addresses CVE-2026-118306, CVE-2026-118331, CVE-2026-118348, CVE-2026-118344

## Links

- Repository: https://github.com/developerfred/maat
- Issues: https://github.com/developerfred/maat/issues
- Releases: https://github.com/developerfred/maat/releases
- Pages: https://developerfred.github.io/maat/