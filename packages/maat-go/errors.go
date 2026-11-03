package maat

import "fmt"

// MaatError é um erro tipificado do SDK Maat (Go).
type MaatError struct {
	Code    string
	Message string
}

func (e *MaatError) Error() string {
	return e.Message
}

func (e *MaatError) Unwrap() error {
	return nil
}

// Códigos de erro (mesmos do SDK JS para consistência).
const (
	CodeInvalidURL        = "INVALID_URL"
	CodeInvalidSelector   = "INVALID_SELECTOR"
	CodeInvalidKey        = "INVALID_KEY"
	CodeValueTooLong      = "VALUE_TOO_LONG"
	CodeExpressionTooLong = "EXPRESSION_TOO_LONG"
	CodeInvalidPath       = "INVALID_PATH"
	CodeNotConnected      = "NOT_CONNECTED"
	CodeTimeout           = "TIMEOUT"
	CodeTransportError    = "TRANSPORT_ERROR"
	CodeInvalidResponse   = "INVALID_RESPONSE"
	CodeServerError       = "SERVER_ERROR"
	CodeOther             = "ERROR"
)

func newError(code, message string) *MaatError {
	return &MaatError{Code: code, Message: message}
}

// InvalidUrlError é retornado quando uma URL é inválida.
type InvalidUrlError struct {
	MaatError
	URL string
}

func NewInvalidUrlError(url string) *InvalidUrlError {
	return &InvalidUrlError{
		MaatError: MaatError{Code: CodeInvalidURL, Message: fmt.Sprintf("URL inválida: %s", url)},
		URL:       url,
	}
}

// InvalidSelectorError é retornado quando um seletor é inválido.
type InvalidSelectorError struct {
	MaatError
	Selector string
}

func NewInvalidSelectorError(selector string) *InvalidSelectorError {
	return &InvalidSelectorError{
		MaatError: MaatError{Code: CodeInvalidSelector, Message: fmt.Sprintf("Seletor inválido: %s", selector)},
		Selector:  selector,
	}
}

// InvalidKeyError é retornado quando uma tecla é inválida.
type InvalidKeyError struct {
	MaatError
	Key string
}

func NewInvalidKeyError(key string) *InvalidKeyError {
	return &InvalidKeyError{
		MaatError: MaatError{Code: CodeInvalidKey, Message: fmt.Sprintf("Tecla inválida: %s", key)},
		Key:       key,
	}
}

// ValueTooLongError é retornado quando um valor excede o tamanho máximo.
type ValueTooLongError struct {
	MaatError
	Field     string
	MaxLength int
}

func NewValueTooLongError(field string, maxLength int) *ValueTooLongError {
	return &ValueTooLongError{
		MaatError: MaatError{
			Code:    CodeValueTooLong,
			Message: fmt.Sprintf("Valor muito longo para %s (máximo %d caracteres)", field, maxLength),
		},
		Field:     field,
		MaxLength: maxLength,
	}
}

// InvalidPathError é retornado quando um caminho é inválido.
type InvalidPathError struct {
	MaatError
	Path string
}

func NewInvalidPathError(path string) *InvalidPathError {
	return &InvalidPathError{
		MaatError: MaatError{Code: CodeInvalidPath, Message: fmt.Sprintf("Caminho inválido: %s", path)},
		Path:      path,
	}
}

// NotConnectedError é retornado quando não há conexão com o servidor.
type NotConnectedError struct {
	MaatError
}

func NewNotConnectedError() *NotConnectedError {
	return &NotConnectedError{
		MaatError: MaatError{Code: CodeNotConnected, Message: "Não conectado ao servidor Maat"},
	}
}

// TimeoutError é retornado quando ocorre timeout.
type TimeoutError struct {
	MaatError
}

func NewTimeoutError() *TimeoutError {
	return &TimeoutError{
		MaatError: MaatError{Code: CodeTimeout, Message: "Timeout aguardando resposta do servidor"},
	}
}

// TransportError é retornado quando ocorre erro de transporte.
type TransportError struct {
	MaatError
	Detail string
}

func NewTransportError(detail string) *TransportError {
	return &TransportError{
		MaatError: MaatError{Code: CodeTransportError, Message: fmt.Sprintf("Erro de transporte: %s", detail)},
		Detail:    detail,
	}
}
