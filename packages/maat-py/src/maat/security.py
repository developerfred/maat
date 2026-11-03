"""Módulo de segurança do Maat (Python SDK).

Validações de entrada para prevenir ataques de injeção antes de enviar
comandos para o navegador. Espelha as regras do SDK JS para consistência.
"""

from __future__ import annotations


class Security:
    MAX_URL_LENGTH = 2048
    MAX_SELECTOR_LENGTH = 256
    MAX_KEY_LENGTH = 32
    MAX_EXPRESSION_LENGTH = 1000
    MAX_VALUE_LENGTH = 1000

    DANGEROUS_URL_CHARS = frozenset(
        "<>\"'&;|`$(){}[]\\#%+!@*~"
    )
    DANGEROUS_SELECTOR_CHARS = frozenset(
        "<>\"'&;(){}[]*!@#$%^+~`|\\ \t\n\r"
    )
    DANGEROUS_KEY_CHARS = frozenset(
        "<>\"'&;(){}[]*!@#$%^+~`|\\ \t\n\r"
    )

    @classmethod
    def is_valid_url(cls, url: str) -> bool:
        if not url or len(url) > cls.MAX_URL_LENGTH:
            return False

        # Decodifica percent-encoding antes de validar (previne bypass por encoding)
        try:
            from urllib.parse import unquote
            decoded = unquote(url)
        except Exception:
            return False  # URL malformada

        if not (decoded.startswith("http://") or decoded.startswith("https://")):
            return False
        return not any(c in decoded for c in cls.DANGEROUS_URL_CHARS)

    @classmethod
    def is_valid_selector(cls, selector: str) -> bool:
        if not selector or len(selector) > cls.MAX_SELECTOR_LENGTH:
            return False
        return not any(c in selector for c in cls.DANGEROUS_SELECTOR_CHARS)

    @classmethod
    def is_valid_key(cls, key: str) -> bool:
        if not key or len(key) > cls.MAX_KEY_LENGTH:
            return False
        return all(c.isalnum() or c in "_-." for c in key)

    @classmethod
    def is_valid_expression(cls, expression: str) -> bool:
        if not expression or len(expression) > cls.MAX_EXPRESSION_LENGTH:
            return False

        dangerous_patterns = [
            "eval(", "setTimeout(", "setInterval(", "Function(",
            "document.write(", "document.writeln(", "innerHTML",
            "outerHTML", "document.cookie", "localStorage",
            "sessionStorage", "XMLHttpRequest", "fetch(",
            "location.href", "location.replace", "location.assign",
        ]
        if any(p in expression for p in dangerous_patterns):
            return False

        dangerous_chars = frozenset(
            "<>\"'&;(){}[]*!@#$%^+~`|\\"
        )
        return not any(c in expression for c in dangerous_chars)

    @classmethod
    def is_valid_value(cls, value: str) -> bool:
        return bool(value) and len(value) <= cls.MAX_VALUE_LENGTH

    @classmethod
    def is_valid_path(cls, path: str) -> bool:
        if not path or len(path) > cls.MAX_URL_LENGTH:
            return False
        if "../" in path:
            return False
        if path.startswith("/"):
            return False
        return True

    @classmethod
    def sanitize(cls, input: str) -> str:
        return "".join(c for c in input if c not in "<>\"")


__all__ = ["Security"]
