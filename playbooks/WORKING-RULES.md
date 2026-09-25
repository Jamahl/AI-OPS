# Agent working rules (cross-project)

Rules learned the hard way on Orla/Agora and other projects. Copy the relevant ones into a project's
CLAUDE.md "How to work here".

## Autonomy
- **Do infra yourself** when the MCP/CLI is connected (env vars, deploys, migrations, logs, prod read
  queries). Don't hand the owner a todo list for things the agent can do.
- **Ask first** only for: irreversible acts, spend (external model runs, paid APIs), credentials, or
  clicks only the owner can make (OAuth consent, DNS, vendor dashboards).
- **Never touch live customer data.** No writes/sends against real tenants' rows, even if the broader
  task seems to include it. Use a demo tenant with owner-controlled addresses. Reads for diagnosis OK.
- **Secrets never transit chat.** Hand the owner a no-echo shell one-liner to set them.

## Building
- Spec first for anything non-trivial: `dev-team/NNN-<feature>.md`, numbered. Reviews and fold docs
  sit next to it (`NNN-review-rN-<model>.md`) and ship with the PR.
- Bug fix = failing test first, then fix, then green.
- `tsc --noEmit` is not a gate for Next.js — pair typecheck with `build`.
- Pure logic in a services layer so it's unit-testable without a DB; side effects at the edges.

## Deploy safety
- CI gates deploy: tests pass on main → deploy fires (`workflow_run`, not `on: push`). Keep a manual
  `workflow_dispatch` escape hatch.
- Build the DB from empty in CI (`migrate up head`) — proves the migration chain works.
- Migrations run while the old version still serves: non-additive changes are expand → contract across
  two deploys.
- Ship API before web when both change, to avoid version skew.
- Test suite: block real network egress, per-test timeouts, refuse a DB whose name lacks `test`.

## Parallel agents & sessions
- Concurrent sessions/agents share the working tree. Run experiments in a worktree or scratchpad;
  don't run tests while a verify workflow is mutating files.
- Before `git add`: check for conflict markers and changes you didn't make.
- Never `build` while a dev server on the same app is running (corrupts its output dir).
- Kill processes by specific pid, never by pattern — siblings match.

## Git
- Commit messages per [`skills/git-commit-messages`](../skills/git-commit-messages/SKILL.md)
  (50/72, imperative, body = what + why). Repo convention (e.g. Conventional Commits) wins.
