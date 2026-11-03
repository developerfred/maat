"""Erros tipificados do SDK Maat (Python).

Mantém os mesmos códigos de erro do SDK JS para consistência entre linguagens.
"""

from __future__ import annotations


class MaatError(Exception):
    """Erro base do Maat com código de erro."""

    code: str = "ERROR"

    def __init__(self, message: str, code: str = "ERROR"):
        super().__init__(message)
        self.message = message
        self.code = code

    def __str__(self) -> str:
        return self.message


class InvalidUrlError(MaatError):
    code = "INVALID_URL"

    def __init__(self, url: str):
        super().__init__(f"URL inválida: {url}", self.code)
        self.url = url


class InvalidSelectorError(MaatError):
    code = "INVALID_SELECTOR"

    def __init__(self, selector: str):
        super().__init__(f"Seletor inválido: {selector}", self.code)
        self.selector = selector


class InvalidKeyError(MaatError):
    code = "INVALID_KEY"

    def __init__(self, key: str):
        super().__init__(f"Tecla inválida: {key}", self.code)
        self.key = key


class ValueTooLongError(MaatError):
    code = "VALUE_TOO_LONG"

    def __init__(self, field: str, max_length: int):
        super().__init__(
            f"Valor muito longo para {field} (máximo {max_length} caracteres)",
            self.code,
        )
        self.field = field
        self.max_length = max_length


class ExpressionTooLongError(MaatError):
    code = "EXPRESSION_TOO_LONG"

    def __init__(self, length: int, max_length: int):
        super().__init__(
            f"Expressão muito longa ({length} caracteres, máximo {max_length})",
            self.code,
        )
        self.length = length
        self.max_length = max_length


class InvalidPathError(MaatError):
    code = "INVALID_PATH"

    def __init__(self, path: str):
        super().__init__(f"Caminho inválido: {path}", self.code)
        self.path = path


class NotConnectedError(MaatError):
    code = "NOT_CONNECTED"

    def __init__(self):
        super().__init__("Não conectado ao servidor Maat", self.code)


class TimeoutError(MaatError):
    code = "TIMEOUT"

    def __init__(self):
        super().__init__("Timeout aguardando resposta do servidor", self.code)


class TransportError(MaatError):
    code = "TRANSPORT_ERROR"

    def __init__(self, detail: str):
        super().__init__(f"Erro de transporte: {detail}", self.code)
        self.detail = detail


class InvalidResponseError(MaatError):
    code = "INVALID_RESPONSE"

    def __init__(self, message: str):
        super().__init__(f"Resposta inválida do servidor: {message}", self.code)
        self.message = message


class ServerError(MaatError):
    code = "SERVER_ERROR"

    def __init__(self, message: str):
        super().__init__(f"Erro interno do servidor Maat: {message}", self.code)
        self.message = message


__all__ = [
    "MaatError",
    "InvalidUrlError",
    "InvalidSelectorError",
    "InvalidKeyError",
    "ValueTooLongError",
    "ExpressionTooLongError",
    "InvalidPathError",
    "NotConnectedError",
    "TimeoutError",
    "TransportError",
    "InvalidResponseError",
    "ServerError",
]
