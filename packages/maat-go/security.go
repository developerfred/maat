package maat

import (
	"fmt"
	"strings"
)

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
	' ', '\t', '\n', '\r',
}

var dangerousKeyChars = []rune{
	'<', '>', '"', '\'', '&', ';', '(', ')', '[', ']', '{', '}',
	'*', '!', '@', '#', '$', '%', '^', '+', '~', '`', '|', '\\',
}

// Padrões de path traversal perigosos (após decodificação).
var pathTraversalPatterns = []string{
	"../", "..\\", "..%2f", "..%5c", "..%252f", "..%255c",
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

func containsAnyPattern(s string, patterns []string) bool {
	lower := strings.ToLower(s)
	for _, p := range patterns {
		if strings.Contains(lower, p) {
			return true
		}
	}
	return false
}

// decodePercentEncoding decodifica percent-encoding, incluindo duplo encoding.
func decodePercentEncoding(input string) string {
	result, err := urlPercentDecode(input)
	if err != nil {
		return input
	}
	// Se ainda houver % após decodificação, tenta novamente (duplo encoding)
	if strings.Contains(result, "%") {
		result2, err2 := urlPercentDecode(result)
		if err2 == nil {
			result = result2
		}
	}
	return result
}

// IsValidURL valida uma URL (deve ser http/https, sem caracteres perigosos).
func (s *Security) IsValidURL(url string) bool {
	if url == "" || len(url) > MaxURLLength {
		return false
	}

	// Decodifica percent-encoding antes de validar (previne bypass por encoding)
	decoded := decodePercentEncoding(url)

	if !strings.HasPrefix(decoded, "http://") && !strings.HasPrefix(decoded, "https://") {
		return false
	}
	return !containsAny(decoded, dangerousURLChars)
}

// urlPercentDecode decodifica percent-encoding (URL-encoding) de uma string.
func urlPercentDecode(input string) (string, error) {
	var result strings.Builder
	for i := 0; i < len(input); i++ {
		if input[i] == '%' && i+2 < len(input) {
			hex := input[i+1 : i+3]
			var val byte
			for _, c := range hex {
				val <<= 4
				ci := byte(c)
				if ci >= '0' && ci <= '9' {
					val += ci - '0'
				} else if ci >= 'a' && ci <= 'f' {
					val += ci - 'a' + 10
				} else if ci >= 'A' && ci <= 'F' {
					val += ci - 'A' + 10
				} else {
					return "", fmt.Errorf("caractere hex inválido: %c", c)
				}
			}
			result.WriteByte(val)
			i += 2
		} else {
			result.WriteByte(input[i])
		}
	}
	return result.String(), nil
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

// IsValidPath valida um caminho de arquivo (sem path traversal, não absoluto).
func (s *Security) IsValidPath(path string) bool {
	if path == "" || len(path) > MaxURLLength {
		return false
	}

	// Decodifica percent-encoding para detectar path traversal ofuscado
	decoded := decodePercentEncoding(path)

	// Bloqueia path traversal (simples e ofuscado por encoding)
	if containsAnyPattern(decoded, pathTraversalPatterns) {
		return false
	}

	// Bloqueia caminhos absolutos
	if strings.HasPrefix(decoded, "/") || strings.HasPrefix(decoded, "\\") {
		return false
	}

	// Bloqueia links simbólicos e caminhos de unidade Windows (C:)
	if strings.HasPrefix(decoded, "~") ||
		(len(decoded) >= 2 && decoded[1] == ':') {
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
