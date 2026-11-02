# Issues Planejadas — Maat

Este arquivo lista todas as issues que vamos percorrer para construir o Maat.
**Sem datas**. Cada issue vira uma issue real no GitHub e é desenvolvida em um **worktree separado** com **pull request**.

---

## Fase 1 — Estrutura base e build

### Issue 1 — Estrutura base do projeto Zig
**Labels:** `infra`, `build-system`, `milestone:fase-1`

Criar a estrutura de pastas, `build.zig`, `build.zig.zon` e `src/maat.zig` (módulo raiz). Deve compilar com `zig build` e `zig build test` sem erros.

**Critério de aceitação:**
- `zig build` compila biblioteca e executável de exemplo
- `zig build test` passa
- Estrutura de pastas padronizada

---

### Issue 2 — API unificada estilo Playwright (Browser, Context, Page)
**Labels:** `api`, `core`, `design`, `milestone:fase-1`

Definir as estruturas e assinaturas públicas em Zig:
- `maat.Browser` (launch, newContext, close)
- `maat.BrowserContext` (newPage, close, cookies)
- `maat.Page` (goto, click, fill, screenshot, title, close)
- Enum `maat.BrowserName` (chromium, firefox, webkit)

**Critério de aceitação:**
- API compilável (mesmo com stubs)
- Documentação nos comentários de cada função pública

---

### Issue 3 — Cliente WebSocket bruto em Zig
**Labels:** `network`, `websocket`, `core`, `milestone:fase-1`

Implementar cliente WebSocket mínimo em Zig: handshake HTTP Upgrade, framing de texto (máscara cliente→servidor), envio e recepção de frames.

**Critério de aceitação:**
- Conecta em um servidor WebSocket local
- Envia e recebe mensagens de texto
- Trata timeout e fechamento de conexão

---

## Fase 2 — Suporte a navegadores (multi)

### Issue 4 — Suporte a Chromium via Chrome DevTools Protocol (CDP)
**Labels:** `browser:chromium`, `cdp`, `protocol`, `milestone:fase-2`

Implementar lançador de Chromium/Chrome com porta de depuração remota (`--remote-debugging-port`) e cliente CDP sobre WebSocket. Comandos mínimos: `Target.createTarget`, `Page.navigate`, `Runtime.evaluate`, `Input.dispatchMouseEvent`, `Page.captureScreenshot`.

**Critério de aceitação:**
- Lança Chromium com sandbox ativo
- Conecta via CDP WebSocket
- Navega para uma URL e executa JS na página

---

### Issue 5 — Suporte a Firefox via WebDriver BiDi / Marionette
**Labels:** `browser:firefox`, `webdriver`, `protocol`, `milestone:fase-2`

Implementar lançador do Firefox com porta de depuração remota e suporte ao protocolo de automação (WebDriver BiDi preferencialmente; Marionette como fallback).

**Critério de aceitação:**
- Lança Firefox com sandbox ativo
- Conecta ao protocolo de automação
- Navega para uma URL

---

### Issue 6 — Suporte a WebKit / Safari via WebDriver / Remote Debugging
**Labels:** `browser:webkit`, `safari`, `webdriver`, `protocol`, `milestone:fase-2`

Implementar lançamento e automação do WebKit/Safari através de seu protocolo de depuração remota ou WebDriver.

**Critério de aceitação:**
- Lança WebKit com sandbox ativo
- Conecta ao protocolo de automação
- Navega para uma URL

---

### Issue 7 — Abstração de lançador de navegador (factory)
**Labels:** `refactor`, `api`, `core`, `milestone:fase-2`

Criar `maat.Browser.launch` que escolhe a implementação correta com base em `BrowserName`, centralizando argumentos comuns (headless, sandbox, argumentos extras, usuário, diretório de dados).

**Critério de aceitação:**
- Uma única função de launch para todos os navegadores
- Fácil de adicionar novos navegadores depois

---

## Fase 3 — Segurança e sandbox

### Issue 8 — Sandbox ativo por padrão em todos os navegadores
**Labels:** `security`, `sandbox`, `milestone:fase-3`

Garantir que nenhum navegador seja lançado com flags que desativem o sandbox (`--no-sandbox`, etc.) por padrão. O sandbox só pode ser desativado explicitamente pelo usuário.

**Critério de aceitação:**
- Testes verificam que flags de sandbox não desativado não estão presentes por padrão
- Documentação explica o risco de desativar

---

### Issue 9 — Flag explícita para desativar sandbox (ambientes confiáveis apenas)
**Labels:** `security`, `opt-in`, `milestone:fase-3`

Adicionar campo `.sandbox = false` na configuração de launch, com aviso claro na documentação e no código (comentário de segurança).

**Critério de aceitação:**
- Quando `.sandbox = false`, flags de desativação são aplicadas
- Aviso de segurança visível no código e README

---

### Issue 10 — Auditoria de alocação de memória (Zig allocator)
**Labels:** `security`, `memory`, `audit`, `milestone:fase-3`

Revisar todo o uso de alocadores em Zig para evitar vazamentos, uso após liberação e estouro de inteiros. Usar `std.heap.GeneralPurposeAllocator` em testes para detecção de vazamentos.

**Critério de aceitação:**
- `zig build test` roda com GPA e não vaza memória
- Nenhum uso de `allocator.free` ausente em caminhos de erro

---

## Fase 4 — Operações de página

### Issue 11 — page.goto (navegação)
**Labels:** `feature:page`, `navigation`, `milestone:fase-4`

Implementar navegação para uma URL em qualquer navegador suportado, aguardando carregamento (load / domcontentloaded / networkidle).

**Critério de aceitação:**
- Navega para URL válida
- Aguarda evento de carregamento
- Retorna erro em URL inválida ou timeout

---

### Issue 12 — Interações de input (click, type, press)
**Labels:** `feature:page`, `input`, `interaction`, `milestone:fase-4`

Implementar clique, digitação e pressionamento de teclas em elementos da página.

**Critério de aceitação:**
- Clique em coordenada ou seletor
- Digitação em campo de texto
- Teclas especiais (Enter, Tab, Escape)

---

### Issue 13 — Preenchimento de formulários (fill)
**Labels:** `feature:page`, `form`, `milestone:fase-4`

Método de alto nível para preencher inputs (foco, limpar, digitar).

**Critério de aceitação:**
- `page.fill(selector, value)` funciona em inputs de texto

---

### Issue 14 — page.screenshot
**Labels:** `feature:page`, `screenshot`, `milestone:fase-4`

Capturar screenshot da página (full page ou viewport) e salvar em arquivo.

**Critério de aceitação:**
- Salva PNG em disco
- Opção full page

---

### Issue 15 — page.title e extração de texto
**Labels:** `feature:page`, `extraction`, `milestone:fase-4`

Obter título da página e texto de elementos.

**Critério de aceitação:**
- `page.title()` retorna o título
- `page.textContent(selector)` retorna texto visível

---

## Fase 5 — Contexto e isolamento

### Issue 16 — Contexto de navegação isolado (cookies, storage)
**Labels:** `feature:context`, `isolation`, `milestone:fase-5`

Cada contexto deve ter cookies, localStorage e sessionStorage isolados dos outros contextos do mesmo navegador.

**Critério de aceitação:**
- Dois contextos não compartilham cookies
- localStorage isolado por contexto

---

### Issue 17 — Gerenciamento de múltiplas páginas/abas
**Labels:** `feature:context`, `multi-tab`, `milestone:fase-5`

Abrir, fechar e alternar entre páginas dentro de um mesmo contexto.

**Critério de aceitação:**
- `context.newPage()` cria nova página
- Fechar página não fecha o contexto

---

## Fase 6 — Exemplos, documentação e CI

### Issue 18 — Exemplo de uso funcionando (main.zig)
**Labels:** `example`, `docs`, `milestone:fase-6`

Criar `src/main.zig` com exemplo completo: launch, página, navegação, screenshot, título. Deve rodar com `zig build run`.

**Critério de aceitação:**
- `zig build run` executa e abre o navegador
- Código comentado explicando cada passo

---

### Issue 19 — README com instruções de build e uso
**Labels:** `docs`, `readme`, `milestone:fase-6`

README completo: instalação do Zig, build, exemplo, navegadores suportados, sandbox, segurança.

**Critério de aceitação:**
- Novo usuário consegue buildar e rodar o exemplo sem dúvidas

---

### Issue 20 — Contributing guide: worktree + pull request
**Labels:** `docs`, `contributing`, `workflow`, `milestone:fase-6`

Documentar o fluxo obrigatório: issue → worktree → implementação → PR → merge → remover worktree.

**Critério de aceitação:**
- Guia claro para contribuidores externos

---

### Issue 21 — GitHub Actions: build em múltiplas plataformas
**Labels:** `ci`, `github-actions`, `milestone:fase-6`

Workflow de CI que testa o build em Linux, macOS e Windows.

**Critério de aceitação:**
- CI passa em pelo menos 2 sistemas operacionais

---

### Issue 22 — Release automática (GitHub Releases)
**Labels:** `release`, `ci`, `milestone:fase-6`

Criar release com binários compilados para cada tag.

**Critério de aceitação:**
- Tag `v0.1.0` gera release com binários

---

## Como usar estas issues

1. Abra cada issue acima no GitHub (cópia do título + corpo).
2. Não adicione datas. Use apenas labels e milestone.
3. Para trabalhar em uma issue:
   ```bash
   git worktree add ../maat-<numero>-<slug> -b issue-<numero>-<slug>
   cd ../maat-<numero>-<slug>
   # implementar
   git add .
   git commit -m "feat: implementa <descricao>"
   # push e abrir PR para main
   ```
4. Após o merge, remova o worktree:
   ```bash
   git worktree remove ../maat-<numero>-<slug>
   ```

---