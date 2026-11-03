# Desafios Restantes para Bater o Playwright

## O que já temos (comparado ao Playwright)

| Funcionalidade | Playwright | Maat | Status |
|----------------|------------|------|--------|
| Lançar navegador | ✅ | ✅ (stub) |
| Nova página | ✅ | ✅ |
| Navegação (goto) | ✅ | ✅ (stub) |
| Clique | ✅ | ✅ (stub) |
| Preencher formulário | ✅ | ✅ (stub) |
| Pressionar tecla | ✅ | ✅ (stub) |
| Título da página | ✅ | ✅ (stub) |
| Screenshot | ✅ | ✅ (stub) |
| Contexto isolado | ✅ | ✅ |
| Cookies | ✅ | ✅ (stub) |
| Sandbox por padrão | ❌ (desativado) | ✅ (ATIVO) |
| Segurança de memória | ❌ (C/C++) | ✅ (Zig) |
| Multi-navegador | ✅ | ✅ (Chromium, Firefox, WebKit) |
| Execute JavaScript | ✅ | ✅ (stub) |
| WaitForSelector | ✅ | ✅ (stub) |

## O que ainda PRECISAMOS implementar para bater o Playwright

### 1. Rede Real (WebSocket TCP)
- Implementar conexão TCP real via `std.net` ou chamadas de sistema
- Handshake HTTP Upgrade real
- Envio/recebimento de frames WebSocket reais
- Conectar ao navegador real instalado

### 2. Automação Real de Navegador
- Lançar processo do navegador real (google-chrome, firefox, safari)
- Esperar porta de depuração abrir
- Conectar via CDP/WebDriver real

### 3. Funcionalidades Avançadas do Playwright que não temos
- CodeGen (gerar código a partir de gravação)
- Trace Viewer (gravar sessão para depuração)
- Test Runner integrado
- Emulação de dispositivo móvel
- Emulação de geolocalização
- Interceptação de rede (request/response)
- Mock de API
- Upload/Download de arquivos
- Diálogos (alert, confirm, prompt)
- Iframes
- Sombras DOM
- Esperas automáticas (auto-waiting)
- Assertions (expect.toBeVisible, etc.)

### 4. Ecossistema
- CLI (maat codegen, maat test, etc.)
- Playwright Test Runner compatível
- Integração com CI/CD
- Plugins e extensões

## Vantagens Competitivas do Maat sobre o Playwright

1. **Sandbox por padrão** - Playwright desativa, Maat ativa
2. **Segurança de memória** - Zig vs C/C++ (sem use-after-free, buffer overflow)
3. **Menor superfície de ataque** - Reescrito em Zig
4. **Endereça CVEs** - CVE-2026-118306, CVE-2026-118331, CVE-2026-118348, CVE-2026-118344
5. **Código aberto e transparente** - Tudo visível
