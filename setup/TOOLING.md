# Tooling inventory

Snapshot 2026-09-26. **No secrets here** — keys live in local config only.

## Claude Code (`~/.claude/settings.json`)
- Model `fable`, effort `medium`, permissions `defaultMode: auto`, fullscreen TUI, push notifications on.
- Hooks: Superset `notify.sh` on UserPromptSubmit / Stop (session status to Superset).
- Status line: caveman plugin.
- Plugins: caveman, vercel, mosaic-video-editor, claude-ads, scroll-world. Extra marketplaces:
  impeccable, caveman, mosaic-skills, agricidaniel-claude-ads.
- User skills (`~/.claude/skills`): gstack suite (review, qa, ship, design-*, investigate, cso…),
  plus personal ones kept in [`skills/`](../skills).
- `.claude/launch.json` per project for dev-server previews in the desktop app.
- Memory: per-project `memory/` dirs; feedback memories hold owner rules (see
  [WORKING-RULES](../playbooks/WORKING-RULES.md)).

## Devin (`~/.config/devin`)
- CLI at `/opt/homebrew/bin/devin`; default agent model `gpt-5-5-medium`.
- Used as the external-reviewer bench — see [MoE QA loop](../moe/MOE-QA-LOOP.md).
- Same Superset notify hooks (SessionStart / SessionEnd). MCP: vercel.
- Skills: Loops `api`, `cli`, `email-sending-best-practices`. Project skills can live in
  `<repo>/.devin/skills/` (Agora mirrors `transitions-dev`, `transitions-polish` there).

## Keeping skills in sync across Claude + Devin
Same SKILL.md format works in both: `<repo>/.claude/skills/X` and `<repo>/.devin/skills/X`.
