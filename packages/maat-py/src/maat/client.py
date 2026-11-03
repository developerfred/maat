"""Cliente principal do Maat (Python).

Comunica com o servidor Maat (Zig) via WebSocket/HTTP.
Todas as entradas são validadas pelo módulo Security antes do envio.
"""

from __future__ import annotations

import json
import time
from typing import Any, Dict, Optional

import httpx

from .errors import (
    InvalidPathError,
    InvalidSelectorError,
    InvalidUrlError,
    MaatError,
    NotConnectedError,
    RateLimitError,
    TransportError,
    ValueTooLongError,
)
from .security import Security
from .types import (
    BrowserContextOptions,
    BrowserName,
    ClickOptions,
    FillOptions,
    LaunchOptions,
    PageOptions,
    PressOptions,
    ScreenshotOptions,
    WaitUntil,
)
from .types import ActionResult, LaunchResult, PageResult, TitleResult


class RateLimiter:
    """Rate limiter simples baseado em janela deslizante.

    Limita o número de requisições por segundo para prevenir DoS.
    """

    def __init__(self, max_requests_per_second: int = 10) -> None:
        self.max_requests_per_second = max_requests_per_second
        self._timestamps: list[float] = []

    def allow(self) -> bool:
        """Retorna True se a requisição pode prosseguir, False se excedeu o limite."""
        now = time.monotonic()
        # Remove timestamps fora da janela de 1 segundo
        self._timestamps = [t for t in self._timestamps if now - t < 1.0]
        if len(self._timestamps) >= self.max_requests_per_second:
            return False
        self._timestamps.append(now)
        return True


class MaatClient:
    """Cliente principal do Maat."""

    def __init__(
        self,
        base_url: Optional[str] = None,
        api_key: Optional[str] = None,
        max_requests_per_second: int = 10,
    ) -> None:
        self.base_url = base_url
        self._api_key = api_key
        self._next_id: int = 1
        self.connected: bool = False
        self._rate_limiter = RateLimiter(max_requests_per_second)

    async def connect(self, host: str, port: int, path: str = "/", api_key: Optional[str] = None) -> None:
        """Conecta ao servidor Maat informando host, porta e caminho WebSocket."""
        scheme = "wss" if api_key else "ws"
        self.base_url = f"{scheme}://{host}:{port}{path}"
        self._api_key = api_key
        self.connected = True

    async def connect_ws(self, ws_url: str) -> None:
        """Conecta usando uma URL WebSocket já resolvida."""
        self.base_url = ws_url
        self.connected = True

    def is_connected(self) -> bool:
        return self.connected

    def disconnect(self) -> None:
        self.connected = False
        self.base_url = None

    def _next_request_id(self) -> int:
        rid = self._next_id
        self._next_id += 1
        return rid

    @staticmethod
    def _build_params(entries: Optional[Dict[str, Any]]) -> Optional[Dict[str, Any]]:
        return entries

    # ------------------------------------------------------------------
    # Navegador
    # ------------------------------------------------------------------

    async def launch(self, options: LaunchOptions) -> LaunchResult:
        if not self.connected:
            raise NotConnectedError()
        if not self._rate_limiter.allow():
            raise RateLimitError()
        if options.security and options.security.sandbox:
            pass  # sandbox ativo por padrão; o servidor Zig aplica

        params: Dict[str, Any] = {"name": options.name.value}
        if options.protocol:
            params["protocol"] = options.protocol.value
        if options.headless is not None:
            params["headless"] = options.headless
        if options.args:
            params["args"] = options.args
        if options.executable_path:
            if not Security.is_valid_path(options.executable_path):
                raise InvalidPathError(options.executable_path)
            params["executable_path"] = options.executable_path

        # TODO: substituir por chamada WebSocket real quando o servidor Zig
        # expor o endpoint de automação.
        raise TransportError("WebSocket transport not yet bound to Maat Zig server")

    async def close_browser(self, browser_id: str) -> ActionResult:
        if not self.connected:
            raise NotConnectedError()
        if not self._rate_limiter.allow():
            raise RateLimitError()
        raise TransportError("WebSocket transport not yet bound to Maat Zig server")

    # ------------------------------------------------------------------
    # Contexto / Página
    # ------------------------------------------------------------------

    async def new_context(
        self, browser_id: str, options: BrowserContextOptions
    ) -> PageResult:
        if not self.connected:
            raise NotConnectedError()
        if not self._rate_limiter.allow():
            raise RateLimitError()
        raise TransportError("WebSocket transport not yet bound to Maat Zig server")

    async def new_page(self, options: PageOptions) -> PageResult:
        if not self.connected:
            raise NotConnectedError()
        if not self._rate_limiter.allow():
            raise RateLimitError()
        if not Security.is_valid_url(options.url):
            raise InvalidUrlError(options.url)
        raise TransportError("WebSocket transport not yet bound to Maat Zig server")

    async def close_page(self, page_id: str) -> ActionResult:
        if not self.connected:
            raise NotConnectedError()
        if not self._rate_limiter.allow():
            raise RateLimitError()
        raise TransportError("WebSocket transport not yet bound to Maat Zig server")

    # ------------------------------------------------------------------
    # Ações na página
    # ------------------------------------------------------------------

    async def goto(self, page_id: str, url: str) -> ActionResult:
        if not self.connected:
            raise NotConnectedError()
        if not self._rate_limiter.allow():
            raise RateLimitError()
        if not Security.is_valid_url(url):
            raise InvalidUrlError(url)
        raise TransportError("WebSocket transport not yet bound to Maat Zig server")

    async def click(self, page_id: str, options: ClickOptions) -> ActionResult:
        if not self.connected:
            raise NotConnectedError()
        if not self._rate_limiter.allow():
            raise RateLimitError()
        if not Security.is_valid_selector(options.selector):
            raise InvalidSelectorError(options.selector)
        raise TransportError("WebSocket transport not yet bound to Maat Zig server")

    async def fill(self, page_id: str, options: FillOptions) -> ActionResult:
        if not self.connected:
            raise NotConnectedError()
        if not self._rate_limiter.allow():
            raise RateLimitError()
        if not Security.is_valid_selector(options.selector):
            raise InvalidSelectorError(options.selector)
        if not Security.is_valid_value(options.value):
            raise ValueTooLongError("value", Security.MAX_VALUE_LENGTH)
        raise TransportError("WebSocket transport not yet bound to Maat Zig server")

    async def press(self, page_id: str, options: PressOptions) -> ActionResult:
        if not self.connected:
            raise NotConnectedError()
        if not self._rate_limiter.allow():
            raise RateLimitError()
        if not Security.is_valid_key(options.key):
            raise InvalidKeyError(options.key)
        raise TransportError("WebSocket transport not yet bound to Maat Zig server")

    async def screenshot(
        self, page_id: str, options: ScreenshotOptions
    ) -> ActionResult:
        if not self.connected:
            raise NotConnectedError()
        if not self._rate_limiter.allow():
            raise RateLimitError()
        if not Security.is_valid_path(options.path):
            raise InvalidPathError(options.path)
        raise TransportError("WebSocket transport not yet bound to Maat Zig server")

    async def title(self, page_id: str) -> TitleResult:
        if not self.connected:
            raise NotConnectedError()
        if not self._rate_limiter.allow():
            raise RateLimitError()
        raise TransportError("WebSocket transport not yet bound to Maat Zig server")


__all__ = ["MaatClient"]
