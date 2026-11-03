# Agent Skill: Maat Development Workflow

This skill defines the complete development workflow for the Maat project.

## Phase 1: Issue Selection

1. Browse open issues: `gh issue list --repo developerfred/maat --state open`
2. Select an issue without a PR linked
3. Create a worktree: `git worktree add ../maat-<issue>-<slug> -b issue-<issue>-<slug>`

## Phase 2: Implementation

1. Enter worktree: `cd ../maat-<issue>-<slug>`
2. Implement changes following ZIG_COMPAT_SKILL.md guidelines
3. Build: `zig build`
4. Test: `zig build test`
5. Run: `zig build run` (if Chromium available)
6. Format: `zig fmt --check src/`
7. Commit: `git commit -m "feat(issue-<issue>): <description>"`
8. Push: `git push origin issue-<issue>-<slug>`

## Phase 3: PR & Merge

1. Create PR: `gh pr create --repo developerfred/maat --title "..." --body "Closes #<issue>"`
2. Wait for CI to pass
3. Merge: `gh pr merge <PR_NUMBER> --repo developerfred/maat --squash --delete-branch`
4. Issue auto-closes if body contains "Closes #<issue>"
5. Remove worktree: `git worktree remove ../maat-<issue>-<slug> --force`
6. Pull main: `git pull origin main`

## Quality Gates

Before merging any PR:
- [ ] `zig build` succeeds
- [ ] `zig build test` succeeds
- [ ] `zig fmt --check src/` passes
- [ ] PR description references issue number
- [ ] Code comments in English
- [ ] No memory leaks (all alloc paired with free)

## Rollback

If a PR introduces regressions:
1. Revert the merge commit
2. Close the PR
3. Reopen the issue
4. Create a new worktree to fix