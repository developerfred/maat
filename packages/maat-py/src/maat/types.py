"""Tipos compartilhados para automação de navegador (Maat Python SDK)."""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from typing import Optional


class BrowserName(str, Enum):
    CHROMIUM = "chromium"
    FIREFOX = "firefox"
    WEBKIT = "webkit"


class AutomationProtocol(str, Enum):
    CDP = "cdp"
    WEBDRIVER = "webdriver"


class WaitUntil(str, Enum):
    LOAD = "load"
    DOMCONTENTLOADED = "domcontentloaded"
    NETWORKIDLE = "networkidle"


@dataclass
class SecurityConfig:
    sandbox: bool = True


@dataclass
class LaunchOptions:
    name: BrowserName
    protocol: Optional[AutomationProtocol] = None
    headless: Optional[bool] = None
    security: Optional[SecurityConfig] = None
    args: Optional[list[str]] = None
    executable_path: Optional[str] = None


@dataclass
class PageOptions:
    url: str
    wait_until: Optional[WaitUntil] = None


@dataclass
class ClickOptions:
    selector: str


@dataclass
class FillOptions:
    selector: str
    value: str


@dataclass
class PressOptions:
    key: str


@dataclass
class ScreenshotOptions:
    path: str
    full_page: Optional[bool] = None


@dataclass
class BrowserContextOptions:
    sandbox: Optional[bool] = None


@dataclass
class LaunchResult:
    browser_id: str
    ws_url: Optional[str] = None


@dataclass
class PageResult:
    page_id: str
    context_id: Optional[str] = None


@dataclass
class ActionResult:
    ok: bool
    value: Optional[dict] = None


@dataclass
class TitleResult:
    title: str
