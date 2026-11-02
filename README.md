# Maat

**Maat** é um framework de automação de navegadores escrito em **Zig**, inspirado no Playwright, com foco em **segurança de memória** e **sandbox ligado por padrão**.

## Por que Maat?

Na mitologia egípcia, Maat é a deusa da verdade, da ordem e da justiça. Para automação de navegadores, isso significa:

- **Ordem**: uma API unificada e previsível para qualquer navegador.
- **Verdade**: testes determinísticos e confiáveis.
- **Justiça/Proteção**: **sandbox ativo por padrão**, diferentemente do Playwright que frequentemente roda com `--no-sandbox` em CI.

## Escopo

Maat **não reimplementa motores de navegador**. Ele orquestra navegadores reais já instalados no sistema (Chromium, Firefox, WebKit/Safari) através de seus protocolos de automação nativos (CDP, WebDriver BiDi, etc.), enquanto a camada de controle, rede e protocolo fica em **Zig**, aproveitando a segurança de memória da linguagem.

## Navegadores suportados (planejado)

| Navegador | Protocolo | Status |
|-----------|-----------|--------|
| Chromium / Chrome | Chrome DevTools Protocol (CDP) | Em desenvolvimento |
| Firefox | WebDriver BiDi / Marionette | Planejado |
| WebKit / Safari | WebDriver / Remote Debugging | Planejado |

## Requisitos

- Zig 0.17.0+
- Um navegador instalado no sistema

## Build e execução

```sh
zig build            # compila a biblioteca e o exemplo
zig build run        # executa o exemplo
```

## Exemplo de uso

```zig
const maat = @import("maat");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    // Sandbox ligado por padrão
    const browser = try maat.Browser.launch(allocator, .{
        .name = maat.BrowserName.chromium,
        .headless = false,
        .sandbox = true,
    });
    defer browser.close();

    const page = try browser.newPage();
    defer page.close();

    try page.goto("https://example.com");
    try page.screenshot("exemplo.png");

    std.debug.print("Título: {s}\n", .{try page.title()});
}
```

## Segurança e sandbox

Por padrão **o sandbox está ativo**. Se você precisar desativá-lo (somente em ambientes isolados e confiáveis), passe `.sandbox = false`. Isso recria exatamente o comportamento inseguro do Playwright padrão e **não é recomendado para produção**.

As vulnerabilidades citadas (CVE-2026-118306, CVE-2026-118331, CVE-2026-118348, CVE-2026-118344) afetam o ecossistema Playwright/navegador. Reimplementar a orquestração em Zig reduz a superfície de ataque escrita em linguagens inseguras, mas **não remove vulnerabilidades intrínsecas ao motor do navegador**. Mantenha os navegadores atualizados.

## Planejamento e issues

Toda funcionalidade é rastreada como **issue no GitHub**, sem datas, e desenvolvida em **worktree separado** com **pull request**. Veja [`ISSUES_PLANEJADAS.md`](ISSUES_PLANEJADAS.md) para a lista completa.

## Fluxo de trabalho

Cada issue é desenvolvida assim:

1. Criar uma **issue** no GitHub (sem data).
2. Criar um **worktree** em branch dedicada: `git worktree add ../maat-<issue> -b issue-<numero>-<slug>`
3. Implementar, testar e commitar no worktree.
4. Abrir um **pull request** para `main`.
5. Após merge, remover o worktree.

## Licença

MIT