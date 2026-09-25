# AI-OPS

Personal, project-agnostic setup for working with AI coding agents (Claude Code).

| Path | What |
|---|---|
| [`claude/CLAUDE.md`](claude/CLAUDE.md) | Global agent instructions — lives at `~/.claude/CLAUDE.md` |
| [`doc-system/PLAYBOOK.md`](doc-system/PLAYBOOK.md) | How project overview docs are orchestrated (spine + satellites) |
| [`doc-system/templates/`](doc-system/templates) | Drop-in files: overview/CLAUDE.md skeletons, doc-ref checker |
| [`playbooks/CODING-PRINCIPLES.md`](playbooks/CODING-PRINCIPLES.md) | DRY, minimal impact, root causes, code standards — merged, stack-agnostic |
| [`agents/codex/AGENTS.md`](agents/codex/AGENTS.md) | Codex global instructions (verbatim, web) |
| [`agents/windsurf/`](agents/windsurf) | Windsurf global rules (Expo) + `wrap-up` / `review` workflows (verbatim) |
| [`playbooks/WORKING-RULES.md`](playbooks/WORKING-RULES.md) | Autonomy, build, deploy-safety, parallel-agent and git rules |
| [`setup/TOOLING.md`](setup/TOOLING.md) | Claude Code + Devin config, plugins, hooks, skills inventory |
| [`skills/git-commit-messages`](skills/git-commit-messages) | 50/72 imperative commit message rules |
| [`moe/MOE-QA-LOOP.md`](moe/MOE-QA-LOOP.md) | MoE QA: Fable orchestrates Claude fleets + Devin (Sol/K3/GLM) reviewers, loop until dry |
| [`skills/qa-dry-loop`](skills/qa-dry-loop) | Adversarial fleet rounds (finders → skeptics → fold) until a clean round |
| [`skills/docs-update`](skills/docs-update) | Routes doc changes to the right spine/satellite file (per-project copy; edit routing table) |
| [`skills/jam-review-review`](skills/jam-review-review) | Pressure-tests a proposed fix: root cause, scale, tenancy, blast radius |

Install global instructions:

```bash
cp claude/CLAUDE.md ~/.claude/CLAUDE.md
```

Install a personal skill globally:

```bash
cp -R skills/jam-review-review ~/.claude/skills/
```
