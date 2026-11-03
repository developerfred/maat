use thiserror::Error;

/// Erros do SDK Maat (Rust).
///
/// Mantém os mesmos códigos de erro do SDK JS para consistência entre linguagens.
#[derive(Error, Debug)]
pub enum MaatError {
    #[error("URL inválida: {url}")]
    InvalidUrl { url: String },

    #[error("Seletor inválido: {selector}")]
    InvalidSelector { selector: String },

    #[error("Tecla inválida: {key}")]
    InvalidKey { key: String },

    #[error("Valor muito longo para {field} (máximo {max_length} caracteres)")]
    ValueTooLong { field: String, max_length: usize },

    #[error("Expressão muito longa ({length} caracteres, máximo {max_length})")]
    ExpressionTooLong { length: usize, max_length: usize },

    #[error("Caminho inválido: {path}")]
    InvalidPath { path: String },

    #[error("Não conectado ao servidor Maat")]
    NotConnected,

    #[error("Timeout aguardando resposta do servidor")]
    Timeout,

    #[error("Erro de transporte: {detail}")]
    Transport { detail: String },

    #[error("Resposta inválida do servidor: {message}")]
    InvalidResponse { message: String },

    #[error("Erro interno do servidor Maat: {message}")]
    ServerError { message: String },

    #[error("{message}")]
    Other { message: String },
}

impl MaatError {
    pub fn code(&self) -> &'static str {
        match self {
            MaatError::InvalidUrl { .. } => "INVALID_URL",
            MaatError::InvalidSelector { .. } => "INVALID_SELECTOR",
            MaatError::InvalidKey { .. } => "INVALID_KEY",
            MaatError::ValueTooLong { .. } => "VALUE_TOO_LONG",
            MaatError::ExpressionTooLong { .. } => "EXPRESSION_TOO_LONG",
            MaatError::InvalidPath { .. } => "INVALID_PATH",
            MaatError::NotConnected => "NOT_CONNECTED",
            MaatError::Timeout => "TIMEOUT",
            MaatError::Transport { .. } => "TRANSPORT_ERROR",
            MaatError::InvalidResponse { .. } => "INVALID_RESPONSE",
            MaatError::ServerError { .. } => "SERVER_ERROR",
            MaatError::Other { .. } => "ERROR",
        }
    }
}
