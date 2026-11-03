# Maat Python SDK

Maat - Playwright-like browser automation in Python with sandbox enabled by default.

## Instalação

```bash
pip install maat-py
```

## Uso

```python
import asyncio
from maat import MaatClient, BrowserName, LaunchOptions, SecurityConfig

async def main():
    client = MaatClient()
    await client.connect("localhost", 9222)
    try:
        result = await client.launch(LaunchOptions(
            name=BrowserName.CHROMIUM,
            headless=False,
            security=SecurityConfig(sandbox=True),
        ))
        print(f"Navegador lançado: {result.browser_id}")
    finally:
        client.disconnect()

asyncio.run(main())
```

## Segurança

Todas as entradas são validadas pelo módulo `Security` antes de serem enviadas
para o navegador (URL, seletor, tecla, caminho, etc.).
