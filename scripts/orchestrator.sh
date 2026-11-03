#!/usr/bin/env bash
#
# Orquestrador automático de PRs e Issues para o Maat.
#
# Usado por GitHub Actions para:
# 1. Verificar PRs com label "ready-to-merge"
# 2. Fazer merge do PR
# 3. Fechar a issue vinculada (referenciada como "Closes #N")
#
# Requer: gh (GitHub CLI) autenticado
set -euo pipefail

REPO="developerfred/maat"

echo "=== Orquestrador Maat: processando PRs ==="

# Listar PRs abertos com label "ready-to-merge"
prs=$(gh pr list --repo "$REPO" --state open --label "ready-to-merge" --json number,title,body --jq '.[] | .number' 2>/dev/null || echo "")

if [[ -z "$prs" ]]; then
    echo "Nenhum PR com label 'ready-to-merge' encontrado."
    exit 0
fi

for pr_number in $prs; do
    echo "Processando PR #$pr_number..."

    # Verificar se o CI passou (status checks)
    ci_status=$(gh pr checks "$pr_number" --repo "$REPO" --json state --jq '.[] | .state' 2>/dev/null || echo "PENDING")

    if [[ "$ci_status" != "SUCCESS" && "$ci_status" != "COMPLETED" ]]; then
        echo "  CI não passou para PR #$pr_number (status: $ci_status). Pulando."
        continue
    fi

    # Fazer merge do PR (squash)
    echo "  Fazendo merge do PR #$pr_number..."
    gh pr merge "$pr_number" --repo "$REPO" --squash --delete-branch 2>&1 || {
        echo "  Falha ao fazer merge do PR #$pr_number"
        continue
    }

    # Extrair número da issue vinculada (formato: "Closes #N" ou "Fixes #N")
    pr_body=$(gh pr view "$pr_number" --repo "$REPO" --json body --jq '.body' 2>/dev/null || echo "")
    issue_number=$(echo "$pr_body" | grep -oE '(Closes|Fixes|Resolves)\s+#([0-9]+)' | grep -oE '[0-9]+' | head -1 || true)

    if [[ -n "$issue_number" ]]; then
        echo "  Fechando issue #$issue_number vinculada ao PR #$pr_number..."
        gh issue close "$issue_number" --repo "$REPO" --comment "Resolvido via PR #$pr_number" 2>&1 || {
            echo "  Falha ao fechar issue #$issue_number"
        }
    else
        echo "  Nenhuma issue vinculada encontrada no PR #$pr_number"
    fi

    echo "  PR #$pr_number processado com sucesso."
done

echo "=== Orquestrador concluído ==="