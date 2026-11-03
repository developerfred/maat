"""Maat - Python SDK para automação de navegador (Playwright-like)

API pública com sandbox ativo por padrão. Segurança em primeiro lugar.
Comunica com o servidor Maat (escrito em Zig) via WebSocket/HTTP.
"""

from __future__ import annotations

from .client import MaatClient
from .errors import (
    MaatError,
    InvalidUrlError,
    InvalidSelectorError,
    InvalidKeyError,
    ValueTooLongError,
    ExpressionTooLongError,
    InvalidPathError,
)
from .security import Security
from .types import (
    AutomationProtocol,
    BrowserContextOptions,
    BrowserName,
    ClickOptions,
    FillOptions,
    LaunchOptions,
    PageOptions,
    PressOptions,
    ScreenshotOptions,
    SecurityConfig,
    WaitUntil,
)

__all__ = [
    "MaatClient",
    "MaatError",
    "InvalidUrlError",
    "InvalidSelectorError",
    "InvalidKeyError",
    "ValueTooLongError",
    "ExpressionTooLongError",
    "InvalidPathError",
    "Security",
    "BrowserName",
    "AutomationProtocol",
    "SecurityConfig",
    "LaunchOptions",
    "WaitUntil",
    "PageOptions",
    "ClickOptions",
    "FillOptions",
    "PressOptions",
    "ScreenshotOptions",
    "BrowserContextOptions",
]

__version__ = "0.1.0"
