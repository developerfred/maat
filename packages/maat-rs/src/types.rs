use serde::{Deserialize, Serialize};

/// Nome do navegador suportado.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum BrowserName {
    Chromium,
    Firefox,
    Webkit,
}

impl std::fmt::Display for BrowserName {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            BrowserName::Chromium => write!(f, "chromium"),
            BrowserName::Firefox => write!(f, "firefox"),
            BrowserName::Webkit => write!(f, "webkit"),
        }
    }
}

/// Protocolo de automação usado para controlar o navegador.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum AutomationProtocol {
    Cdp,
    WebDriver,
}

impl std::fmt::Display for AutomationProtocol {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            AutomationProtocol::Cdp => write!(f, "cdp"),
            AutomationProtocol::WebDriver => write!(f, "webdriver"),
        }
    }
}

/// Configuração de segurança do contexto/navegador.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub struct SecurityConfig {
    pub sandbox: bool,
}

impl Default for SecurityConfig {
    fn default() -> Self {
        Self { sandbox: true }
    }
}

/// Opções de lançamento do navegador.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LaunchOptions {
    pub name: BrowserName,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub protocol: Option<AutomationProtocol>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub headless: Option<bool>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub security: Option<SecurityConfig>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub args: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub executable_path: Option<String>,
}

/// Condição de espera ao navegar para uma página.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum WaitUntil {
    Load,
    Domcontentloaded,
    Networkidle,
}

impl std::fmt::Display for WaitUntil {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            WaitUntil::Load => write!(f, "load"),
            WaitUntil::Domcontentloaded => write!(f, "domcontentloaded"),
            WaitUntil::Networkidle => write!(f, "networkidle"),
        }
    }
}

/// Opções de abertura de página.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PageOptions {
    pub url: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub wait_until: Option<WaitUntil>,
}

/// Opções de clique.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ClickOptions {
    pub selector: String,
}

/// Opções de preenchimento de campo.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FillOptions {
    pub selector: String,
    pub value: String,
}

/// Opções de pressionar tecla.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PressOptions {
    pub key: String,
}

/// Opções de screenshot.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ScreenshotOptions {
    pub path: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub full_page: Option<bool>,
}

/// Opções de contexto de navegação.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BrowserContextOptions {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub sandbox: Option<bool>,
}

impl Default for LaunchOptions {
    fn default() -> Self {
        Self {
            name: BrowserName::Chromium,
            protocol: None,
            headless: None,
            security: Some(SecurityConfig::default()),
            args: None,
            executable_path: None,
        }
    }
}
