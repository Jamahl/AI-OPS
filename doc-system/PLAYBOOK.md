# Project doc system — playbook

Pattern proven on Orla/Agora (restructure shipped 2026-08-18). Goal: agents and humans find any fact
in one hop, and docs don't rot.

## Shape: progressive disclosure

```
CLAUDE.md            ~90-line agent ROUTER (only file agents auto-load)
PROJECT_OVERVIEW.md  ~150-line MAP / spine
docs/                SATELLITES — all depth lives here
  GOTCHAS.md         numbered traps, frozen numbering, append-only
  CHANGELOG.md       dated entries, newest first, append-only
  ARCHITECTURE.md    binding decisions + rejected alternative + why
  DATA_MODEL · ROUTES · STATE_MACHINES · LIFECYCLES · TENANCY · AUTH · EMAIL
  DEPLOY · ENV · OBSERVABILITY · TESTING · LOCAL_DEV · REPO_MAP · EXTENDING · ROADMAP
```

Pick only the satellites the project needs.

## Rules

1. **One authoritative home per fact.** Everything else links to it.
2. **Spine and router never regrow sections.** New depth → a satellite. Overview holds: what it is,
   one-screen architecture, the top ~5 invariants, a "where to look" routing table.
3. **CLAUDE.md = router**: project summary, commands, how-to-work rules, the five invariants (each
   linking to depth), conventions, environment. Stale index here degrades every future session.
4. **Correct, don't append.** Current-state docs describe *now* — rewrite the falsified sentence.
   Only CHANGELOG and GOTCHAS are append-only.
5. **Gotchas are numbered and frozen.** Code, CLAUDE.md and memory cite `#N`. Never renumber or
   delete; supersede with a dated correction inside the entry.
6. **Mirror less, point more.** State the invariant, point at `file:line`. Hand-copied column lists
   and route signatures were the #1 source of rot.
7. **Docs ship in the same PR as the code.** Follow-up doc commits don't happen.
8. **Absolute dates, no PII**, dense bold-led bullets.
9. Routine bugfixes/refactors get **no** doc changes — resist padding.

## Orchestration

- **`docs-update` skill** (`.claude/skills/docs-update/SKILL.md`) carries the routing table
  change → file. Agents invoke it at the end of any change touching architecture, schema, endpoints,
  statuses, lifecycles, env vars, or prod state.
- **`scripts/check_doc_refs.sh`** guards the contract: anchors resolve, referenced `docs/*.md` exist,
  gotcha numbering contiguous. Wire into `check_all.sh` / CI. Add project-specific checks (e.g.
  documented migration head == real head).
- **Building/restructuring docs**: fan out subagents, one per satellite, each verifying claims
  against code (Agora: ~250 claims verified by 10 audit agents; caught several wrong "facts").
  Then one pass writes the spine + router from the verified satellites.
- Old long-form docs → archive dir; full text recoverable from git history.

## Bootstrap a new repo

```bash
mkdir -p docs .claude/skills/docs-update scripts
cp templates/PROJECT_OVERVIEW.md templates/CLAUDE.md .
cp templates/skills/docs-update/SKILL.md .claude/skills/docs-update/
cp templates/scripts/check_doc_refs.sh scripts/
```

Then edit the routing table in the skill to match the satellites you created.
