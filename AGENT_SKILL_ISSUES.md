# Agent Skill: GitHub Issues & PRs for Maat

This skill enables AI agents to autonomously manage GitHub issues and pull requests for the Maat project.

## Prerequisites

- `gh` CLI installed and authenticated: `gh auth login`
- Repository: `developerfred/maat`
- Working directory: `/Volumes/MASS/playwright-in-zig`

## Commands

### 1. Create a new issue

```bash
gh issue create \
  --repo developerfred/maat \
  --title "feat: <description>" \
  --body "<description>\n\nCritério de aceitação:\n- item 1\n- item 2" \
  --label "label1,label2" \
  --milestone 1
```

### 2. Create a worktree for an issue

```bash
# From main branch
git worktree add ../maat-<issue>-<slug> -b issue-<issue>-<slug>
cd ../maat-<issue>-<slug>

# Implement changes
zig build
zig build test

# Commit
git add -A
git commit -m "feat(issue-<issue>): <description>"
git push origin issue-<issue>-<slug>
```

### 3. Create a PR and merge

```bash
# From the issue worktree
gh pr create \
  --repo developerfred/maat \
  --title "feat(issue-<issue>): <description>" \
  --body "Closes #<issue>" \
  --base main \
  --head issue-<issue>-<slug>

gh pr merge <PR_NUMBER> --repo developerfred/maat --squash --delete-branch

# Close issue if not auto-closed
gh issue close <issue> --repo developerfred/maat --comment "Resolved via PR #<PR_NUMBER>"

# Remove worktree
cd /Volumes/MASS/playwright-in-zig
git worktree remove ../maat-<issue>-<slug> --force
git pull origin main
```

### 4. Run the orchestrator (auto-merge ready PRs)

```bash
./scripts/orchestrator.sh
```

## Label Reference

| Label | Description |
|-------|-------------|
| infra | Infrastructure & build system |
| api | Public API & design |
| core | Core functionality |
| network | Network & protocols |
| websocket | WebSocket |
| cdp | Chrome DevTools Protocol |
| webdriver | WebDriver / BiDi |
| security | Security & sandbox |
| sandbox | Browser sandbox |
| feature:page | Page operations |
| feature:context | Browser context |
| example | Examples |
| docs | Documentation |
| ci | CI/CD |
| release | Releases |
| zig-compat | Zig API compatibility |

## Milestone Reference

| Milestone | Description |
|-----------|-------------|
| 1 | Fase 1 - Estrutura base e build |
| 2 | Fase 2 - Suporte a navegadores (multi) |
| 3 | Fase 3 - Segurança e sandbox |
| 4 | Fase 4 - Operações de página |
| 5 | Fase 5 - Contexto e isolamento |
| 6 | Fase 6 - Exemplos, documentação e CI |

## Rule: Close Issues Only When 100% Done

Issues should only be closed when:
1. Code is implemented and compiled
2. Tests pass (`zig build test`)
3. Code runs (`zig build run`)
4. PR is merged to main

PRs can be merged before issues are closed (stubs are acceptable for incremental delivery).