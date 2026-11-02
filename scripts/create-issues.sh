#!/usr/bin/env bash
#
# Script para criar todas as issues planejadas do Maat no GitHub.
# Requer: gh (GitHub CLI) autenticado: gh auth login
#
# Uso:
#   ./scripts/create-issues.sh
#
# As issues serão criadas no repositório corrente.
# Sem datas, apenas labels e título + corpo.
set -euo pipefail

REPO_OWNER=$(gh repo view --json owner -q '.owner.login' 2>/dev/null || echo "")
REPO_NAME=$(gh repo view --json name -q '.name' 2>/dev/null || echo "")

if [[ -z "$REPO_OWNER" || -z "$REPO_NAME" ]]; then
    echo "Erro: não foi possível detectar o repositório GitHub."
    echo "Certifique-se de estar dentro de um repositório com remote configurado."
    echo "E que o gh esteja autenticado: gh auth login"
    exit 1
fi

echo "Criando issues no repositório: $REPO_OWNER/$REPO_NAME"

# Função auxiliar para criar issue
create_issue() {
    local title="$1"
    local body="$2"
    local labels="$3"

    echo "Criando issue: $title"
    gh issue create \
        --title "$title" \
        --body "$body" \
        --label "$labels" \
        2>&1 || echo "  AVISO: falha ao criar issue: $title"
}

# ============================================================
# Fase 1 — Estrutura base e build
# ============================================================

create_issue \
    "Estrutura base do projeto Zig" \
    "Criar a estrutura de pastas, build.zig, build.zig.zon e src/maat.zig (módulo raiz). Deve compilar com zig build e zig build test sem erros.

Critério de aceitação:
- zig build compila biblioteca e executável de exemplo
- zig build test passa
- Estrutura de pastas padronizada" \
    "infra, build-system, milestone:fase-1"

create_issue \
    "API unificada estilo Playwright (Browser, Context, Page)" \
    "Definir as estruturas e assinaturas públicas em Zig:
- maat.Browser (launch, newContext, close)
- maat.BrowserContext (newPage, close, cookies)
- maat.Page (goto, click, fill, screenshot, title, close)
- Enum maat.BrowserName (chromium, firefox, webkit)

Critério de aceitação:
- API compilável (mesmo com stubs)
- Documentação nos comentários de cada função pública" \
    "api, core, design, milestone:fase-1"

create_issue \
    "Cliente WebSocket bruto em Zig" \
    "Implementar cliente WebSocket mínimo em Zig: handshake HTTP Upgrade, framing de texto (máscara cliente→servidor), envio e recepção de frames.

Critério de aceitação:
- Conecta em um servidor WebSocket local
- Envia e recebe mensagens de texto
- Trata timeout e fechamento de conexão" \
    "network, websocket, core, milestone:fase-1"

# ============================================================
# Fase 2 — Suporte a navegadores (multi)
# ============================================================

create_issue \
    "Suporte a Chromium via Chrome DevTools Protocol (CDP)" \
    "Implementar lançador de Chromium/Chrome com porta de depuração remota (--remote-debugging-port) e cliente CDP sobre WebSocket. Comandos mínimos: Target.createTarget, Page.navigate, Runtime.evaluate, Input.dispatchMouseEvent, Page.captureScreenshot.

Critério de aceitação:
- Lança Chromium com sandbox ativo
- Conecta via CDP WebSocket
- Navega para uma URL e executa JS na página" \
    "browser:chromium, cdp, protocol, milestone:fase-2"

create_issue \
    "Suporte a Firefox via WebDriver BiDi / Marionette" \
    "Implementar lançador do Firefox com porta de depuração remota e suporte ao protocolo de automação (WebDriver BiDi preferencialmente; Marionette como fallback).

Critério de aceitação:
- Lança Firefox com sandbox ativo
- Conecta ao protocolo de automação
- Navega para uma URL" \
    "browser:firefox, webdriver, protocol, milestone:fase-2"

create_issue \
    "Suporte a WebKit / Safari via WebDriver / Remote Debugging" \
    "Implementar lançamento e automação do WebKit/Safari através de seu protocolo de depuração remota ou WebDriver.

Critério de aceitação:
- Lança WebKit com sandbox ativo
- Conecta ao protocolo de automação
- Navega para uma URL" \
    "browser:webkit, safari, webdriver, protocol, milestone:fase-2"

create_issue \
    "Abstração de lançador de navegador (factory)" \
    "Criar maat.Browser.launch que escolha a implementação correta com base em BrowserName, centralizando argumentos comuns (headless, sandbox, argumentos extras, usuário, diretório de dados).

Critério de aceitação:
- Uma única função de launch para todos os navegadores
- Fácil de adicionar novos navegadores depois" \
    "refactor, api, core, milestone:fase-2"

# ============================================================
# Fase 3 — Segurança e sandbox
# ============================================================

create_issue \
    "Sandbox ativo por padrão em todos os navegadores" \
    "Garantir que nenhum navegador seja lançado com flags que desativem o sandbox (--no-sandbox, etc.) por padrão. O sandbox só pode ser desativado explicitamente pelo usuário.

Critério de aceitação:
- Testes verificam que flags de sandbox não desativado não estão presentes por padrão
- Documentação explica o risco de desativar" \
    "security, sandbox, milestone:fase-3"

create_issue \
    "Flag explícita para desativar sandbox (ambientes confiáveis apenas)" \
    "Adicionar campo .sandbox = false na configuração de launch, com aviso claro na documentação e no código (comentário de segurança).

Critério de aceitação:
- Quando .sandbox = false, flags de desativação são aplicadas
- Aviso de segurança visível no código e README" \
    "security, opt-in, milestone:fase-3"

create_issue \
    "Auditoria de alocação de memória (Zig allocator)" \
    "Revisar todo o uso de alocadores em Zig para evitar vazamentos, uso após liberação e estouro de inteiros. Usar std.heap.GeneralPurposeAllocator em testes para detecção de vazamentos.

Critério de aceitação:
- zig build test roda com GPA e não vaza memória
- Nenhum uso de allocator.free ausente em caminhos de erro" \
    "security, memory, audit, milestone:fase-3"

# ============================================================
# Fase 4 — Operações de página
# ============================================================

create_issue \
    "page.goto (navegação)" \
    "Implementar navegação para uma URL em qualquer navegador suportado, aguardando carregamento (load / domcontentloaded / networkidle).

Critério de aceitação:
- Navega para URL válida
- Aguarda evento de carregamento
- Retorna erro em URL inválida ou timeout" \
    "feature:page, navigation, milestone:fase-4"

create_issue \
    "Interações de input (click, type, press)" \
    "Implementar clique, digitação e pressionamento de teclas em elementos da página.

Critério de aceitação:
- Clique em coordenada ou seletor
- Digitação em campo de texto
- Teclas especiais (Enter, Tab, Escape)" \
    "feature:page, input, interaction, milestone:fase-4"

create_issue \
    "Preenchimento de formulários (fill)" \
    "Método de alto nível para preencher inputs (foco, limpar, digitar).

Critério de aceitação:
- page.fill(selector, value) funciona em inputs de texto" \
    "feature:page, form, milestone:fase-4"

create_issue \
    "page.screenshot" \
    "Capturar screenshot da página (full page ou viewport) e salvar em arquivo.

Critério de aceitação:
- Salva PNG em disco
- Opção full page" \
    "feature:page, screenshot, milestone:fase-4"

create_issue \
    "page.title e extração de texto" \
    "Obter título da página e texto de elementos.

Critério de aceitação:
- page.title() retorna o título
- page.textContent(selector) retorna texto visível" \
    "feature:page, extraction, milestone:fase-4"

# ============================================================
# Fase 5 — Contexto e isolamento
# ============================================================

create_issue \
    "Contexto de navegação isolado (cookies, storage)" \
    "Cada contexto deve ter cookies, localStorage e sessionStorage isolados dos outros contextos do mesmo navegador.

Critério de aceitação:
- Dois contextos não compartilham cookies
- localStorage isolado por contexto" \
    "feature:context, isolation, milestone:fase-5"

create_issue \
    "Gerenciamento de múltiplas páginas/abas" \
    "Abrir, fechar e alternar entre páginas dentro de um mesmo contexto.

Critério de aceitação:
- context.newPage() cria nova página
- Fechar página não fecha o contexto" \
    "feature:context, multi-tab, milestone:fase-5"

# ============================================================
# Fase 6 — Exemplos, documentação e CI
# ============================================================

create_issue \
    "Exemplo de uso funcionando (main.zig)" \
    "Criar src/main.zig com exemplo completo: launch, página, navegação, screenshot, título. Deve rodar com zig build run.

Critério de aceitação:
- zig build run executa e abre o navegador
- Código comentado explicando cada passo" \
    "example, docs, milestone:fase-6"

create_issue \
    "README com instruções de build e uso" \
    "README completo: instalação do Zig, build, exemplo, navegadores suportados, sandbox, segurança.

Critério de aceitação:
- Novo usuário consegue buildar e rodar o exemplo sem dúvidas" \
    "docs, readme, milestone:fase-6"

create_issue \
    "Contributing guide: worktree + pull request" \
    "Documentar o fluxo obrigatório: issue → worktree → implementação → PR → merge → remover worktree.

Critério de aceitação:
- Guia claro para contribuidores externos" \
    "docs, contributing, workflow, milestone:fase-6"

create_issue \
    "GitHub Actions: build em múltiplas plataformas" \
    "Workflow de CI que testa o build em Linux, macOS e Windows.

Critério de aceitação:
- CI passa em pelo menos 2 sistemas operacionais" \
    "ci, github-actions, milestone:fase-6"

create_issue \
    "Release automática (GitHub Releases)" \
    "Criar release com binários compilados para cada tag.

Critério de aceitação:
- Tag v0.1.0 gera release com binários" \
    "release, ci, milestone:fase-6"

# ============================================================
# Fase 6 (extra) — Compatibilidade de API do Zig
# ============================================================

create_issue \
    "Camada de compatibilidade automática de API do Zig" \
    "Criar src/build_compat.zig que detecta a versão do Zig e abstrai diferenças de API do build.zig entre versões (0.11 → master). O build.zig deve usar apenas essa camada.

Adicionar GitHub Actions que testa o build em múltiplas versões do Zig (0.11.0 até 0.18.0 e master).

Critério de aceitação:
- zig build funciona em Zig 0.11.0+
- CI passa em todas as versões testadas
- Quando uma nova versão do Zig quebrar a API, apenas build_compat.zig precisa ser atualizado" \
    "infra, zig-compat, ci, milestone:fase-6"

echo ""
echo "=== Todas as issues foram processadas ==="
echo "Verifique no GitHub: https://github.com/$REPO_OWNER/$REPO_NAME/issues"