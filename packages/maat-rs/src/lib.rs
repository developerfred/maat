/**
 * Maat - SDK Rust para automação de navegador (Playwright-like)
 *
 * API pública com sandbox ativo por padrão. Segurança em primeiro lugar.
 *
 * Comunica com o servidor Maat (escrito em Zig) via WebSocket/HTTP.
 */

pub mod client;
pub mod error;
pub mod security;
pub mod types;

pub use client::{MaatClient, ActionResult, LaunchResult, PageResult, TitleResult};
pub use error::MaatError;
pub use security::Security;
pub use types::{
    AutomationProtocol, BrowserContextOptions, BrowserName, ClickOptions, FillOptions,
    LaunchOptions, PageOptions, PressOptions, ScreenshotOptions, SecurityConfig, WaitUntil,
};

pub type Result<T> = std::result::Result<T, MaatError>;
