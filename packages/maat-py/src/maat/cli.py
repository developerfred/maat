"""CLI simples do Maat (Python)."""

from __future__ import annotations

import asyncio
import sys
from typing import Optional

import typer

from .client import MaatClient
from .errors import MaatError
from .types import BrowserName, WaitUntil

app = typer.Typer(help="Maat - browser automation CLI (sandbox enabled by default)")


@app.command()
def launch(
    browser: str = typer.Option("chromium", help="Navegador: chromium, firefox, webkit"),
    headless: bool = typer.Option(False, help="Executar sem interface gráfica"),
    sandbox: bool = typer.Option(True, help="Habilitar sandbox"),
    host: str = typer.Option("localhost", help="Host do servidor Maat"),
    port: int = typer.Option(9222, help="Porta do servidor Maat"),
) -> None:
    """Lança um navegador."""

    async def _run() -> None:
        client = MaatClient()
        await client.connect(host, port)
        try:
            from .types import LaunchOptions, SecurityConfig

            options = LaunchOptions(
                name=BrowserName(browser),
                headless=headless,
                security=SecurityConfig(sandbox=sandbox),
            )
            result = await client.launch(options)
            print(f"Navegador lançado: id={result.browser_id}")
        except MaatError as exc:
            print(f"Erro: {exc}", file=sys.stderr)
            sys.exit(1)
        finally:
            client.disconnect()

    asyncio.run(_run())


@app.command()
def goto(
    page_id: str = typer.Argument(..., help="ID da página"),
    url: str = typer.Argument(..., help="URL para navegar"),
    host: str = typer.Option("localhost", help="Host do servidor Maat"),
    port: int = typer.Option(9222, help="Porta do servidor Maat"),
) -> None:
    """Navega para uma URL."""

    async def _run() -> None:
        client = MaatClient()
        await client.connect(host, port)
        try:
            result = await client.goto(page_id, url)
            print(f"Navegação para {url}: ok={result.ok}")
        except MaatError as exc:
            print(f"Erro: {exc}", file=sys.stderr)
            sys.exit(1)
        finally:
            client.disconnect()

    asyncio.run(_run())


@app.command()
def click(
    page_id: str = typer.Argument(..., help="ID da página"),
    selector: str = typer.Argument(..., help="Seletor CSS"),
    host: str = typer.Option("localhost", help="Host do servidor Maat"),
    port: int = typer.Option(9222, help="Porta do servidor Maat"),
) -> None:
    """Clica em um seletor."""

    async def _run() -> None:
        client = MaatClient()
        await client.connect(host, port)
        try:
            from .types import ClickOptions

            result = await client.click(page_id, ClickOptions(selector=selector))
            print(f"Clique em {selector}: ok={result.ok}")
        except MaatError as exc:
            print(f"Erro: {exc}", file=sys.stderr)
            sys.exit(1)
        finally:
            client.disconnect()

    asyncio.run(_run())


@app.command()
def title(
    page_id: str = typer.Argument(..., help="ID da página"),
    host: str = typer.Option("localhost", help="Host do servidor Maat"),
    port: int = typer.Option(9222, help="Porta do servidor Maat"),
) -> None:
    """Obtém o título da página."""

    async def _run() -> None:
        client = MaatClient()
        await client.connect(host, port)
        try:
            result = await client.title(page_id)
            print(f"Título: {result.title}")
        except MaatError as exc:
            print(f"Erro: {exc}", file=sys.stderr)
            sys.exit(1)
        finally:
            client.disconnect()

    asyncio.run(_run())


def main() -> None:
    app()


if __name__ == "__main__":
    main()
