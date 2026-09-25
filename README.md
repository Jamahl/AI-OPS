# AI-OPS

Personal, project-agnostic setup for working with AI coding agents (Claude Code).

| Path | What |
|---|---|
| [`claude/CLAUDE.md`](claude/CLAUDE.md) | Global agent instructions — lives at `~/.claude/CLAUDE.md` |
| [`doc-system/PLAYBOOK.md`](doc-system/PLAYBOOK.md) | How project overview docs are orchestrated (spine + satellites) |
| [`doc-system/templates/`](doc-system/templates) | Drop-in files: overview/CLAUDE.md skeletons, doc-ref checker |
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
