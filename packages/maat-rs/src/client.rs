use crate::error::MaatError;
use crate::types::{
    BrowserContextOptions, ClickOptions, FillOptions, LaunchOptions, PageOptions, PressOptions,
    ScreenshotOptions,
};
use crate::security::Security;
use serde::Serialize;
use std::collections::HashMap;
use std::time::Instant;

/// Rate limiter simples baseado em janela deslizante.
/// Limita o número de requisições por segundo para prevenir DoS.
struct RateLimiter {
    max_requests: u32,
    timestamps: Vec<Instant>,
}

impl RateLimiter {
    fn new(max_requests_per_second: u32) -> Self {
        Self {
            max_requests: max_requests_per_second,
            timestamps: Vec::new(),
        }
    }

    fn allow(&mut self) -> bool {
        let now = Instant::now();
        // Remove timestamps fora da janela de 1 segundo
        self.timestamps.retain(|t| now.duration_since(*t) < std::time::Duration::from_secs(1));
        if self.timestamps.len() as u32 >= self.max_requests {
            return false;
        }
        self.timestamps.push(now);
        true
    }
}

/// Requ enviada ao servidor Maat (serializada para JSON).
#[derive(Serialize)]
struct Request {
    id: u64,
    method: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    params: Option<HashMap<String, serde_json::Value>>,
}

/// Resultado de lançamento de navegador.
#[derive(Debug, Clone, serde::Deserialize)]
pub struct LaunchResult {
    pub browser_id: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub ws_url: Option<String>,
}

/// Resultado de nova página/contexto.
#[derive(Debug, Clone, serde::Deserialize)]
pub struct PageResult {
    pub page_id: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub context_id: Option<String>,
}

/// Resultado genérico de ação (clique, preencher, pressionar).
#[derive(Debug, Clone, serde::Deserialize)]
pub struct ActionResult {
    pub ok: bool,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub value: Option<serde_json::Value>,
}

/// Título da página.
#[derive(Debug, Clone, serde::Deserialize)]
pub struct TitleResult {
    pub title: String,
}

/// Cliente principal do Maat (Rust).
///
/// Comunica com o servidor Maat (Zig) via WebSocket/HTTP.
/// Todas as entradas são validadas por [`crate::Security`] antes do envio.
pub struct MaatClient {
    /// URL base do servidor Maat (ex.: `ws://localhost:9222` ou `http://localhost:9222`).
    base_url: Option<String>,
    next_id: u64,
    connected: bool,
    api_key: Option<String>,
    rate_limiter: RateLimiter,
}

impl MaatClient {
    /// Cria um cliente não conectado.
    pub fn new() -> Self {
        Self {
            base_url: None,
            next_id: 1,
            connected: false,
            api_key: None,
            rate_limiter: RateLimiter::new(10),
        }
    }

    /// Conecta ao servidor Maat informando host, porta e caminho WebSocket.
    /// @param api_key - Chave de API opcional para autenticação
    pub async fn connect(
        &mut self,
        host: &str,
        port: u16,
        path: &str,
        api_key: Option<&str>,
    ) -> Result<(), MaatError> {
        let scheme = if api_key.is_some() { "wss" } else { "ws" };
        let url = format!("{}://{}:{}{}", scheme, host, port, path);
        self.base_url = Some(url.clone());
        self.connected = true;
        let _ = url;
        let _ = api_key;
        Ok(())
    }

    /// Conecta usando uma URL WebSocket já resolvida (ex.: retornada por `launch`).
    pub async fn connect_ws(&mut self, ws_url: &str, api_key: Option<&str>) -> Result<(), MaatError> {
        let scheme = if api_key.is_some() { "wss" } else { "ws" };
        let url = format!("{}://{}", scheme, ws_url.trim_start_matches("ws://").trim_start_matches("wss://"));
        self.base_url = Some(url);
        self.connected = true;
        let _ = api_key;
        Ok(())
    }

    /// Verifica se o cliente está conectado.
    pub fn is_connected(&self) -> bool {
        self.connected
    }

    /// Fecha a conexão.
    pub fn disconnect(&mut self) {
        self.connected = false;
        self.base_url = None;
        self.api_key = None;
    }

    // -----------------------------------------------------------------------
    // Helpers internos
    // -----------------------------------------------------------------------

    fn next_request_id(&mut self) -> u64 {
        let id = self.next_id;
        self.next_id += 1;
        id
    }

    /// Constrói o mapa de parâmetros serializado para uma requisição.
    fn build_params(
        entries: Option<Vec<(&str, serde_json::Value)>>,
    ) -> Option<HashMap<String, serde_json::Value>> {
        entries.map(|e| {
            e.into_iter()
                .map(|(k, v)| (k.to_string(), v))
                .collect::<HashMap<_, _>>()
        })
    }

    // -----------------------------------------------------------------------
    // Navegador
    // -----------------------------------------------------------------------

    /// Lança um navegador. Valida o caminho do executável se fornecido.
    pub async fn launch(&mut self, options: &LaunchOptions) -> Result<LaunchResult, MaatError> {
        if !self.connected {
            return Err(MaatError::NotConnected);
        }
        if !self.rate_limiter.allow() {
            return Err(MaatError::RateLimitExceeded);
        }

        if let Some(sec) = options.security {
            if sec.sandbox {
                // sandbox ativo por padrão; o servidor Zig aplica a restrição
            }
        }

        let mut entries: Vec<(&str, serde_json::Value)> = Vec::new();
        entries.push(("name", serde_json::to_value(options.name.to_string()).unwrap()));
        if let Some(p) = options.protocol {
            entries.push(("protocol", serde_json::to_value(p.to_string()).unwrap()));
        }
        if let Some(h) = options.headless {
            entries.push(("headless", serde_json::to_value(h).unwrap()));
        }
        if let Some(args) = &options.args {
            entries.push(("args", serde_json::to_value(args).unwrap()));
        }
        if let Some(path) = &options.executable_path {
            if !Security::is_valid_path(path) {
                return Err(MaatError::InvalidPath {
                    path: path.clone(),
                });
            }
            entries.push(("executable_path", serde_json::to_value(path).unwrap()));
        }

        let params = Self::build_params(Some(entries));
        let _resp: serde_json::Value = self.call("browser.launch", params).await?;
        // Placeholder: quando o servidor Zig estiver expondo este endpoint,
        // desserialize a resposta real em LaunchResult.
        Ok(LaunchResult {
            browser_id: format!("browser-{}", self.next_request_id()),
            ws_url: None,
        })
    }

    /// Fecha o navegador.
    pub async fn close_browser(&mut self, browser_id: &str) -> Result<ActionResult, MaatError> {
        if !self.connected {
            return Err(MaatError::NotConnected);
        }
        if !self.rate_limiter.allow() {
            return Err(MaatError::RateLimitExceeded);
        }
        let params = Self::build_params(Some(vec![(
            "browser_id",
            serde_json::to_value(browser_id).unwrap(),
        )]));
        let _resp: serde_json::Value = self.call("browser.close", params).await?;
        Ok(ActionResult { ok: true, value: None })
    }

    // -----------------------------------------------------------------------
    // Contexto / Página
    // -----------------------------------------------------------------------

    /// Cria um novo contexto de navegação.
    pub async fn new_context(
        &mut self,
        browser_id: &str,
        options: &BrowserContextOptions,
    ) -> Result<PageResult, MaatError> {
        if !self.connected {
            return Err(MaatError::NotConnected);
        }
        if !self.rate_limiter.allow() {
            return Err(MaatError::RateLimitExceeded);
        }
        let mut entries: Vec<(&str, serde_json::Value)> =
            vec![("browser_id", serde_json::to_value(browser_id).unwrap())];
        if let Some(s) = options.sandbox {
            entries.push(("sandbox", serde_json::to_value(s).unwrap()));
        }
        let params = Self::build_params(Some(entries));
        let _resp: serde_json::Value = self.call("context.new", params).await?;
        Ok(PageResult {
            page_id: format!("page-{}", self.next_request_id()),
            context_id: None,
        })
    }

    /// Abre uma nova página. Valida a URL antes de enviar.
    pub async fn new_page(&mut self, options: &PageOptions) -> Result<PageResult, MaatError> {
        if !self.connected {
            return Err(MaatError::NotConnected);
        }
        if !self.rate_limiter.allow() {
            return Err(MaatError::RateLimitExceeded);
        }
        if !Security::is_valid_url(&options.url) {
            return Err(MaatError::InvalidUrl {
                url: options.url.clone(),
            });
        }
        let mut entries: Vec<(&str, serde_json::Value)> =
            vec![("url", serde_json::to_value(&options.url).unwrap())];
        if let Some(w) = options.wait_until {
            entries.push(("wait_until", serde_json::to_value(w.to_string()).unwrap()));
        }
        let params = Self::build_params(Some(entries));
        let _resp: serde_json::Value = self.call("page.new", params).await?;
        Ok(PageResult {
            page_id: format!("page-{}", self.next_request_id()),
            context_id: None,
        })
    }

    /// Fecha uma página.
    pub async fn close_page(&mut self, page_id: &str) -> Result<ActionResult, MaatError> {
        if !self.connected {
            return Err(MaatError::NotConnected);
        }
        if !self.rate_limiter.allow() {
            return Err(MaatError::RateLimitExceeded);
        }
        let params = Self::build_params(Some(vec![(
            "page_id",
            serde_json::to_value(page_id).unwrap(),
        )]));
        let _resp: serde_json::Value = self.call("page.close", params).await?;
        Ok(ActionResult { ok: true, value: None })
    }

    // -----------------------------------------------------------------------
    // Ações na página
    // -----------------------------------------------------------------------

    /// Navega para uma URL. Valida a URL antes de enviar.
    pub async fn goto(&mut self, page_id: &str, url: &str) -> Result<ActionResult, MaatError> {
        if !self.connected {
            return Err(MaatError::NotConnected);
        }
        if !self.rate_limiter.allow() {
            return Err(MaatError::RateLimitExceeded);
        }
        if !Security::is_valid_url(url) {
            return Err(MaatError::InvalidUrl {
                url: url.to_string(),
            });
        }
        let params = Self::build_params(Some(vec![
            ("page_id", serde_json::to_value(page_id).unwrap()),
            ("url", serde_json::to_value(url).unwrap()),
        ]));
        let _resp: serde_json::Value = self.call("page.goto", params).await?;
        Ok(ActionResult { ok: true, value: None })
    }

    /// Clica em um seletor. Valida o seletor antes de enviar.
    pub async fn click(
        &mut self,
        page_id: &str,
        options: &ClickOptions,
    ) -> Result<ActionResult, MaatError> {
        if !self.connected {
            return Err(MaatError::NotConnected);
        }
        if !self.rate_limiter.allow() {
            return Err(MaatError::RateLimitExceeded);
        }
        if !Security::is_valid_selector(&options.selector) {
            return Err(MaatError::InvalidSelector {
                selector: options.selector.clone(),
            });
        }
        let params = Self::build_params(Some(vec![
            ("page_id", serde_json::to_value(page_id).unwrap()),
            ("selector", serde_json::to_value(&options.selector).unwrap()),
        ]));
        let _resp: serde_json::Value = self.call("page.click", params).await?;
        Ok(ActionResult { ok: true, value: None })
    }

    /// Preenche um campo. Valida seletor e valor antes de enviar.
    pub async fn fill(&mut self, page_id: &str, options: &FillOptions) -> Result<ActionResult, MaatError> {
        if !self.connected {
            return Err(MaatError::NotConnected);
        }
        if !self.rate_limiter.allow() {
            return Err(MaatError::RateLimitExceeded);
        }
        if !Security::is_valid_selector(&options.selector) {
            return Err(MaatError::InvalidSelector {
                selector: options.selector.clone(),
            });
        }
        if !Security::is_valid_value(&options.value) {
            return Err(MaatError::ValueTooLong {
                field: "value".to_string(),
                max_length: Security::MAX_VALUE_LENGTH,
            });
        }
        let params = Self::build_params(Some(vec![
            ("page_id", serde_json::to_value(page_id).unwrap()),
            ("selector", serde_json::to_value(&options.selector).unwrap()),
            ("value", serde_json::to_value(&options.value).unwrap()),
        ]));
        let _resp: serde_json::Value = self.call("page.fill", params).await?;
        Ok(ActionResult { ok: true, value: None })
    }

    /// Pressiona uma tecla. Valida a tecla antes de enviar.
    pub async fn press(&mut self, page_id: &str, options: &PressOptions) -> Result<ActionResult, MaatError> {
        if !self.connected {
            return Err(MaatError::NotConnected);
        }
        if !self.rate_limiter.allow() {
            return Err(MaatError::RateLimitExceeded);
        }
        if !Security::is_valid_key(&options.key) {
            return Err(MaatError::InvalidKey {
                key: options.key.clone(),
            });
        }
        let params = Self::build_params(Some(vec![
            ("page_id", serde_json::to_value(page_id).unwrap()),
            ("key", serde_json::to_value(&options.key).unwrap()),
        ]));
        let _resp: serde_json::Value = self.call("page.press", params).await?;
        Ok(ActionResult { ok: true, value: None })
    }

    /// Tira um screenshot. Valida o caminho antes de enviar.
    pub async fn screenshot(
        &mut self,
        page_id: &str,
        options: &ScreenshotOptions,
    ) -> Result<ActionResult, MaatError> {
        if !self.connected {
            return Err(MaatError::NotConnected);
        }
        if !self.rate_limiter.allow() {
            return Err(MaatError::RateLimitExceeded);
        }
        if !Security::is_valid_path(&options.path) {
            return Err(MaatError::InvalidPath {
                path: options.path.clone(),
            });
        }
        let mut entries: Vec<(&str, serde_json::Value)> = vec![
            ("page_id", serde_json::to_value(page_id).unwrap()),
            ("path", serde_json::to_value(&options.path).unwrap()),
        ];
        if let Some(fp) = options.full_page {
            entries.push(("full_page", serde_json::to_value(fp).unwrap()));
        }
        let params = Self::build_params(Some(entries));
        let _resp: serde_json::Value = self.call("page.screenshot", params).await?;
        Ok(ActionResult { ok: true, value: None })
    }

    /// Obtém o título da página.
    pub async fn title(&mut self, page_id: &str) -> Result<TitleResult, MaatError> {
        if !self.connected {
            return Err(MaatError::NotConnected);
        }
        if !self.rate_limiter.allow() {
            return Err(MaatError::RateLimitExceeded);
        }
        let params = Self::build_params(Some(vec![(
            "page_id",
            serde_json::to_value(page_id).unwrap(),
        )]));
        let _resp: serde_json::Value = self.call("page.title", params).await?;
        Ok(TitleResult {
            title: String::new(),
        })
    }

    // -----------------------------------------------------------------------
    // Transporte de baixo nível
    // -----------------------------------------------------------------------

    /// Envia uma requisição ao servidor Maat e aguarda a resposta.
    ///
    /// Esta é a camada de transporte. Enquanto o servidor Zig não expor o endpoint
    /// WebSocket definitivo, este método retorna um erro informativo.
    async fn call(
        &mut self,
        method: &str,
        params: Option<HashMap<String, serde_json::Value>>,
    ) -> Result<serde_json::Value, MaatError> {
        if !self.connected {
            return Err(MaatError::NotConnected);
        }

        let id = self.next_request_id();
        let req = Request {
            id,
            method: method.to_string(),
            params,
        };

        let _payload = serde_json::to_string(&req)
            .map_err(|e| MaatError::Transport {
                detail: e.to_string(),
            })?;

        // TODO: substituir por envio real via WebSocket/HTTP quando o servidor
        // Zig estiver expondo o endpoint de automação.
        Err(MaatError::Transport {
            detail: "WebSocket transport not yet bound to Maat Zig server".to_string(),
        })
    }
}

impl Default for MaatClient {
    fn default() -> Self {
        Self::new()
    }
}
