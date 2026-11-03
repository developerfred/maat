package maat

import "strings"

// Security fornece validações de entrada para prevenir injeções.
// Espelha as regras do SDK JS para consistência entre linguagens.
type Security struct{}

const (
	MaxURLLength        = 2048
	MaxSelectorLength   = 256
	MaxKeyLength        = 32
	MaxExpressionLength = 1000
	MaxValueLength      = 1000
)

var dangerousURLChars = []rune{
	'<', '>', '"', '\'', '&', ';', '|', '`', '$', '(', ')', '{', '}',
	'[', ']', '\\', '#', '%', '+', '!', '@', '*', '~',
}

var dangerousSelectorChars = []rune{
	'<', '>', '"', '\'', '&', ';', '(', ')', '[', ']', '{', '}',
	'*', '!', '@', '#', '$', '%', '^', '+', '~', '`', '|', '\\',
	'.', '#', '-', '_', ':',
}

var dangerousKeyChars = []rune{
	'<', '>', '"', '\'', '&', ';', '(', ')', '[', ']', '{', '}',
	'*', '!', '@', '#', '$', '%', '^', '+', '~', '`', '|', '\\',
}

func containsAny(s string, chars []rune) bool {
	for _, c := range s {
		for _, d := range chars {
			if c == d {
				return true
			}
		}
	}
	return false
}

// IsValidURL valida uma URL (deve ser http/https, sem caracteres perigosos).
func (s *Security) IsValidURL(url string) bool {
	if url == "" || len(url) > MaxURLLength {
		return false
	}
	if !strings.HasPrefix(url, "http://") && !strings.HasPrefix(url, "https://") {
		return false
	}
	return !containsAny(url, dangerousURLChars)
}

// IsValidSelector valida um seletor CSS.
func (s *Security) IsValidSelector(selector string) bool {
	if selector == "" || len(selector) > MaxSelectorLength {
		return false
	}
	return !containsAny(selector, dangerousSelectorChars)
}

// IsValidKey valida uma tecla (somente alfanumérico, underline, hífen, ponto).
func (s *Security) IsValidKey(key string) bool {
	if key == "" || len(key) > MaxKeyLength {
		return false
	}
	for _, c := range key {
		if !isAlnumOr(c, "_-.") {
			return false
		}
	}
	return true
}

// IsValidExpression valida uma expressão JS.
func (s *Security) IsValidExpression(expression string) bool {
	if expression == "" || len(expression) > MaxExpressionLength {
		return false
	}

	dangerousPatterns := []string{
		"eval(", "setTimeout(", "setInterval(", "Function(",
		"document.write(", "document.writeln(", "innerHTML",
		"outerHTML", "document.cookie", "localStorage",
		"sessionStorage", "XMLHttpRequest", "fetch(",
		"location.href", "location.replace", "location.assign",
	}
	for _, p := range dangerousPatterns {
		if strings.Contains(expression, p) {
			return false
		}
	}

	dangerousChars := []rune{
		'<', '>', '"', '\'', '&', ';', '(', ')', '[', ']', '{', '}',
		'*', '!', '@', '#', '$', '%', '^', '+', '~', '`', '|', '\\',
	}
	return !containsAny(expression, dangerousChars)
}

// IsValidValue valida um valor de preenchimento.
func (s *Security) IsValidValue(value string) bool {
	return value != "" && len(value) <= MaxValueLength
}

// IsValidPath valida um caminho de arquivo (sem ../, não absoluto).
func (s *Security) IsValidPath(path string) bool {
	if path == "" || len(path) > MaxURLLength {
		return false
	}
	if strings.Contains(path, "../") {
		return false
	}
	if strings.HasPrefix(path, "/") {
		return false
	}
	return true
}

// Sanitize remove caracteres HTML perigosos.
func (s *Security) Sanitize(input string) string {
	var b strings.Builder
	for _, c := range input {
		if c != '<' && c != '>' && c != '"' && c != '\'' {
			b.WriteRune(c)
		}
	}
	return b.String()
}

func isAlnumOr(c rune, extra string) bool {
	if (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') {
		return true
	}
	for _, e := range extra {
		if c == e {
			return true
		}
	}
	return false
}
