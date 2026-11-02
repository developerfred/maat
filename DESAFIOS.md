# Desafios do Projeto Maat

Este documento registra os desafios técnicos encontrados ao construir o Maat (Playwright-like em Zig), ideias de bibliotecas futuras e funcionalidades que não existem na std do Zig e precisam ser inventadas/implementadas.

---

## 1. Desafios já encontrados

### 1.1. Zig 0.17 — API de build quebrando (build.zig)
O Zig 0.17 mudou completamente a API de `build.zig`:
- `root_source_file` → `root_module`
- `moduleFromPath` não existe mais; usa-se `addModule`
- `setTarget` / `setBuildMode` existem em `Module`, mas não em `Step.Compile`
- `linkLibrary` não existe mais em `Step.Compile`; a ligação é implícita pelos `root_module` e `imports`
- `b.args` não existe mais para passar argumentos ao `run_cmd`

**Impacto:** tivemos que reescrever o `build.zig` várias vezes para bater com a versão instalada (0.17.0).

### 1.2. `std.ChildProcess` não existe como esperado
No Zig 0.17, `std.process.Child` existe, mas não como campo direto de `std.ChildProcess`. A criação de processos é feita via `std.process.launch` com `SpawnOptions`, e o retorno é um `std.process.Child`.

**Impacto:** a struct `Browser` precisou armazenar o processo de forma genérica ou remover o campo `process` temporariamente.

### 1.3. `std.heap.GeneralPurposeAllocator` não existe
No Zig 0.17.0 desta instalação, `std.heap.GeneralPurposeAllocator` não foi encontrado. O allocador disponível é `std.heap.page_allocator` (e outros em `std.heap.*`).

**Impacto:** `main.zig` usa `std.heap.page_allocator` por enquanto. Para detecção de vazamentos em testes, precisaríamos de um `GeneralPurposeAllocator` compatível.

### 1.4. WebSocket do zero não existe na std do Zig
Não há cliente WebSocket na biblioteca padrão. Tivemos que implementar:
- Handshake HTTP `GET ... Upgrade: websocket`
- Geração da `Sec-WebSocket-Key` (base64 de 16 bytes aleatórios)
- Framing de texto (máscara cliente→servidor, opcode 0x1, FIN, length encoding 7/16/64 bits)
- Leitura de frames e desmáscara

**Impacto:** o arquivo `src/cdp.zig` concentra toda essa implementação.

### 1.5. Não há JSON builder nativo na std do Zig
A std do Zig tem `std.json.parse`, mas não um builder/construtor de JSON simples e seguro para montar mensagens CDP (como `{"id":1,"method":"Page.navigate","params":{...}}`).

**Impacto:** usamos `std.fmt.allocPrint` para montar JSON à mão, o é frágil (escaping de aspas, caracteres especiais).

### 1.6. Parsing de JSON de resposta CDP
Quando o navegador responde via CDP, precisamos extrair campos do JSON (ex: `targetId`, `sessionId`, `result`). Sem um parser JSON robusto e fácil, isso é manual e propenso a erros.

### 1.7. Sandbox por padrão vs flags do navegador
Cada navegador desativa o sandbox de forma diferente:
- Chromium/Chrome: `--no-sandbox`
- Firefox: variável de ambiente ou flags específicas
- WebKit/Safari: flags de entitlement / sandbox do macOS

Precisamos garantir que **nenhuma** dessas flags seja adicionada por padrão, e que a desativação seja opt-in explícita.

---

## 2. Desafios que podem virar bibliotecas futuras

### 2.1. `maat-json` — JSON builder seguro para Zig
Uma biblioteca Zig para construir JSON de forma declarativa e segura, com escaping automático, suporte a `null`, arrays, objetos aninhados, e integração com `std.mem.Allocator`.

Exemplo desejado:
```zig
const json = try Json.builder(allocator) .{
    .object = .{
        .{ "id", .int(1) },
        .{ "method", .str("Page.navigate") },
        .{ "params", .object .{ .{ "url", .str("https://example.com") } } },
    },
}.build();
```

### 2.2. `maat-ws` — Cliente WebSocket reutilizável
Extrair a implementação de WebSocket de `src/cdp.zig` para uma biblioteca separada, reutilizável por qualquer projeto Zig que precise de WebSocket cliente (não apenas CDP).

### 2.3. `maat-sandbox` — Gerenciador de sandbox por navegador
Uma biblioteca que, dado o navegador e o SO, retorna as flags corretas para manter o sandbox ativo, e permite desativá-lo de forma controlada (com aviso de segurança).

### 2.4. `maat-selector` — Seletores de elementos para automação
Playwright tem seletores como `text=`, `css=`, `xpath=`, `role=`. Uma biblioteca Zig para interpretar seletores e gerar os comandos correspondentes em CDP/BiDi.

### 2.5. `maat-wait` — Estratégias de espera (waitFor)
- `waitForNavigation`
- `waitForSelector`
- `waitForFunction` (JS executado no navegador)
- `waitForTimeout`

Essas precisam de polling sobre CDP/BiDi e podem ser encapsuladas.

### 2.6. `maat-recorder` — Gerador de código a partir de ações
Gravar interações no navegador e gerar código Zig (ou outra linguagem) que reproduza essas interações (similar ao Playwright codegen).

---

## 3. Coisas que não existem no Zig e precisamos inventar

| Funcionalidade | Status no Zig | Solução necessária |
|----------------|---------------|-------------------|
| Cliente WebSocket | ❌ Não existe na std | Implementar em `src/cdp.zig` (futura lib `maat-ws`) |
| Construtor de JSON | ❌ Apenas parser | `std.fmt.allocPrint` (frágil) → futura lib `maat-json` |
| Gerenciador de processos multiplataforma | ⚠️ `std.process.launch` existe, mas API instável | Abstração própria para launch/kill/wait de navegadores |
| Pool de allocators com detecção de vazamento | ⚠️ `GeneralPurposeAllocator` ausente nesta build | Criar wrapper seguro sobre `page_allocator` ou implementar GPA compatível |
| Seletor de elementos DOM | ❌ Não existe | Implementar interpretação de seletores CSS/XPath |
| Screenshot nativo | ❌ Não existe | Depende do protocolo do navegador (CDP `Page.captureScreenshot`) |
| Gerenciamento de múltiplas abas/contextos | ❌ Não existe | Implementar sobre CDP `Target.createTarget` / `Target.closeTarget` |

---

## 4. Como usar este documento

Quando uma issue for criada para qualquer um destes desafios, vincule esta seção correspondente. Cada desafio acima pode se tornar:

1. Uma **issue própria** no GitHub (sem data).
2. Um **worktree dedicado** para implementação.
3. Um **pull request** para `main` após revisão.

Exemplo de issue derivada:
> Título: `feat(lib): criar maat-json — construtor de JSON seguro para Zig`
> Labels: `library`, `json`, `proposta`
> Descrição: veja DESAFIOS.md seção 2.1

---

## 5. Status atual (v0.1.0)

- [x] Estrutura base do projeto Zig (build.zig, build.zig.zon, src/)
- [x] Módulo raiz `maat.zig` com `Browser`, `Page`, `BrowserName`, `LaunchOptions`
- [x] Cliente WebSocket + CDP em `src/cdp.zig`
- [x] Exemplo `src/main.zig` funcionando (compila)
- [ ] Suporte real a Chromium via CDP (precisa de navegador instalado)
- [ ] Suporte a Firefox (WebDriver BiDi)
- [ ] Suporte a WebKit/Safari
- [ ] JSON builder seguro
- [ ] Testes automatizados com detecção de vazamento

---