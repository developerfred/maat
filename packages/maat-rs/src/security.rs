/// Módulo de segurança do Maat (Rust).
///
/// Validações de entrada para prevenir ataques de injeção antes de enviar
/// comandos para o navegador. Espelha as regras do SDK JS para consistência.
pub struct Security;

impl Security {
    pub const MAX_URL_LENGTH: usize = 2048;
    pub const MAX_SELECTOR_LENGTH: usize = 256;
    pub const MAX_KEY_LENGTH: usize = 32;
    pub const MAX_EXPRESSION_LENGTH: usize = 1000;
    pub const MAX_VALUE_LENGTH: usize = 1000;

    const DANGEROUS_URL_CHARS: &'static [char] = &[
        '<', '>', '"', '\'', '&', ';', '|', '`', '$', '(', ')', '{', '}',
        '[', ']', '\\', '#', '%', '+', '!', '@', '*', '~',
    ];

    const DANGEROUS_SELECTOR_CHARS: &'static [char] = &[
        '<', '>', '"', '\'', '&', ';', '(', ')', '[', ']', '{', '}',
        '*', '!', '@', '#', '$', '%', '^', '+', '~', '`', '|', '\\',
        '.', '#', '-', '_', ':',
    ];

    const DANGEROUS_KEY_CHARS: &'static [char] = &[
        '<', '>', '"', '\'', '&', ';', '(', ')', '[', ']', '{', '}',
        '*', '!', '@', '#', '$', '%', '^', '+', '~', '`', '|', '\\',
    ];

    /// Valida uma URL (deve ser http/https, sem caracteres perigosos).
    pub fn is_valid_url(url: &str) -> bool {
        if url.is_empty() || url.len() > Self::MAX_URL_LENGTH {
            return false;
        }
        if !url.starts_with("http://") && !url.starts_with("https://") {
            return false;
        }
        !Self::DANGEROUS_URL_CHARS.iter().any(|c| url.contains(*c))
    }

    /// Valida um seletor CSS.
    pub fn is_valid_selector(selector: &str) -> bool {
        if selector.is_empty() || selector.len() > Self::MAX_SELECTOR_LENGTH {
            return false;
        }
        !Self::DANGEROUS_SELECTOR_CHARS.iter().any(|c| selector.contains(*c))
    }

    /// Valida uma tecla (somente alfanumérico, underline, hífen, ponto).
    pub fn is_valid_key(key: &str) -> bool {
        if key.is_empty() || key.len() > Self::MAX_KEY_LENGTH {
            return false;
        }
        key.chars().all(|c| c.is_ascii_alphanumeric() || matches!(c, '_' | '-' | '.'))
    }

    /// Valida uma expressão JS (bloqueia padrões perigosos e caracteres).
    pub fn is_valid_expression(expression: &str) -> bool {
        if expression.is_empty() || expression.len() > Self::MAX_EXPRESSION_LENGTH {
            return false;
        }

        let dangerous_patterns = [
            "eval(", "setTimeout(", "setInterval(", "Function(",
            "document.write(", "document.writeln(", "innerHTML",
            "outerHTML", "document.cookie", "localStorage",
            "sessionStorage", "XMLHttpRequest", "fetch(",
            "location.href", "location.replace", "location.assign",
        ];

        if dangerous_patterns.iter().any(|p| expression.contains(p)) {
            return false;
        }

        let dangerous_chars = [
            '<', '>', '"', '\'', '&', ';', '(', ')', '[', ']', '{', '}',
            '*', '!', '@', '#', '$', '%', '^', '+', '~', '`', '|', '\\',
        ];

        !dangerous_chars.iter().any(|c| expression.contains(*c))
    }

    /// Valida um valor de preenchimento.
    pub fn is_valid_value(value: &str) -> bool {
        !value.is_empty() && value.len() <= Self::MAX_VALUE_LENGTH
    }

    /// Valida um caminho de arquivo (sem ../, não absoluto).
    pub fn is_valid_path(path: &str) -> bool {
        if path.is_empty() || path.len() > Self::MAX_URL_LENGTH {
            return false;
        }
        if path.contains("../") {
            return false;
        }
        if path.starts_with('/') {
            return false;
        }
        true
    }

    /// Sanitiza uma entrada removendo caracteres HTML perigosos.
    pub fn sanitize(input: &str) -> String {
        input.chars().filter(|c| !matches!(c, '<' | '>' | '"' | '\'')).collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_valid_url() {
        assert!(Security::is_valid_url("https://example.com"));
        assert!(!Security::is_valid_url("javascript:alert(1)"));
        assert!(!Security::is_valid_url(""));
    }

    #[test]
    fn test_valid_selector() {
        assert!(Security::is_valid_selector("button"));
        assert!(!Security::is_valid_selector("<script>"));
    }

    #[test]
    fn test_valid_key() {
        assert!(Security::is_valid_key("Enter"));
        assert!(!Security::is_valid_key("ctrl a"));
    }

    #[test]
    fn test_valid_path() {
        assert!(Security::is_valid_path("screenshot.png"));
        assert!(!Security::is_valid_path("../etc/passwd"));
        assert!(!Security::is_valid_path("/abs/path"));
    }
}
