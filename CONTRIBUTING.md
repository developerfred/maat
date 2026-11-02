# Contribuindo com o Maat

O Maat é um projeto público. Toda contribuição segue o mesmo fluxo:

## 1. Issue primeiro

Nada é implementado sem uma issue aberta no GitHub.
- Crie a issue descrevendo o que será feito.
- Não adicione datas. Use apenas labels.
- As issues planejadas estão em [`ISSUES_PLANEJADAS.md`](ISSUES_PLANEJADAS.md).

## 2. Worktree por issue

Cada issue é desenvolvida em um **git worktree** isolado, em sua própria branch. Isso evita conflitos entre contribuições paralelas.

```bash
# No repositório principal
git worktree add ../maat-<numero>-<slug> -b issue-<numero>-<slug>
cd ../maat-<numero>-<slug>
```

Exemplo:
```bash
git worktree add ../maat-4-cdp-chromium -b issue-4-cdp-chromium
```

## 3. Implementar e commitar

No worktree, implemente a funcionalidade, rode os testes e commite:

```bash
zig build test
git add .
git commit -m "feat(issue-4): implementa cliente CDP básico para Chromium"
```

## 4. Abrir Pull Request

Push a branch e abra um PR para `main`:

```bash
git push origin issue-4-cdp-chromium
```

No GitHub, abra o PR vinculando à issue (ex: `Closes #4`).

## 5. Code review e merge

O PR deve ser revisado e aprovado antes do merge. Após o merge na branch `main`:

```bash
# De volta ao repositório principal
git worktree remove ../maat-4-cdp-chromium
```

## Regras de código

- Zig 0.17.0+
- Formato: `zig fmt`
- Sem uso de `--no-sandbox` por padrão
- Todo código novo deve ter teste correspondente quando aplicável
- Documentação em comentários (`///`) para funções públicas

## Segurança

Relate vulnerabilidades de segurança através de issues privadas ou diretamente ao mantenedor. Não publique detalhes de exploração públicas.