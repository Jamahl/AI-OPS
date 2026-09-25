---
name: docs-update
description: >
  Route documentation updates for a code change to the right file in this
  repo's doc system (PROJECT_OVERVIEW.md spine + docs/ satellites). Use this
  skill whenever the user asks to update docs after shipping something, says
  "update the docs", "document this change", "add a changelog entry", "add a
  gotcha", or finishes a feature/fix and asks what docs need touching — and
  proactively at the end of any change that alters architecture, schema,
  endpoints, statuses, lifecycles, env vars, or tenant prod state. Do NOT use
  it for writing user-facing product copy or marketing docs.
---

# docs-update — route doc changes to their authoritative home

Every fact has exactly one authoritative home: `PROJECT_OVERVIEW.md` is a
~150-line spine that must not regrow sections; depth lives in `docs/`
satellites. Route each change with the table below. Doc edits belong in the
**same commit/PR as the code change** — follow-up doc commits do not happen.

## Step 1 — identify what actually changed

Look at the diff you just produced (or `git diff` / the staged changes / the
last commit if invoked after the fact). Classify each change against the
routing table. A change can hit several rows. Routine bugfixes and refactors
that don't alter shape or behaviour get **no doc changes at all** — resist
padding.

## Step 2 — route

| The change… | Update | How |
|---|---|---|
| Shipped a behaviour or architecture change | `docs/CHANGELOG.md` | New dated entry at the TOP (newest first): what shipped, why, and the rollback. Append-only — never edit an old entry; supersede with a new dated one |
| …and made a current-state claim wrong | the matching `docs/` satellite | **Correct the sentence in place** — schema → `docs/DATA_MODEL.md`, endpoints → `docs/ROUTES.md`, statuses/jobs → `docs/STATE_MACHINES.md`, flows → `docs/LIFECYCLES.md`, tenancy/RLS → `docs/TENANCY.md`, auth → `docs/AUTH.md`, email → `docs/EMAIL.md`, deploy/domains → `docs/DEPLOY.md`, logging/Sentry/PostHog → `docs/OBSERVABILITY.md`, tests/CI → `docs/TESTING.md`, file moves → `docs/REPO_MAP.md` |
| Taught you a non-obvious prod trap | `docs/GOTCHAS.md` | Append as the **next number**. Numbering is frozen — code, CLAUDE.md, and memory reference entries by `#N`. Never renumber, reorder, or delete; a wrong old gotcha gets a dated correction sentence inside it |
| Changed the deferred/known-gaps picture | `docs/ROADMAP.md` | Add or **remove** the bullet — a gap that shipped must be deleted, not left standing |
| Changed a seam other features hook into | `docs/EXTENDING.md` | Update the walkthrough for that seam |
| Changed tenant prod state (connections, rounds, admins) | `docs/TENANTS.md` | Update the row with a "verified as of YYYY-MM-DD" date |
| Added/changed an env var or secret | `docs/ENV.md` + `.env.example` | Ownership matrix row (who holds it: Render / Vercel / local) |
| Made a binding decision (DNS, proxy, RLS strategy, scheduler ownership) | `docs/ARCHITECTURE.md` | Decision + rejected alternative + why |
| Touched the staff console | `docs/PLATFORM_CONSOLE.md` | Its own runbook — keep console auth/routes there, not in ROUTES/AUTH content elsewhere |
| Changed a model, ran a model eval, or measured AI cost/billing | `docs/AI_MODELS.md` | Model roster + who gets billed + measured cost. Evals are **append-only dated sections** (the decision matters later even when it was "keep the status quo"); the roster and cost tables are current-state — correct them in place |
| Changed commands, layout, ports, or the burn list | `CLAUDE.md` | It is the only file agents auto-load — a stale index there degrades every future session |
| Touched the voice agent — prompt, tools, voice, model, agent rotation | `docs/RETELL.md` | Mirror policy, version table, provisioning paths live there; the repo prompt file is a mirror, never the deploy source |

## Step 3 — write in the house style

- **Correct, don't append.** Current-state sections describe *now*. If your
  change falsifies a sentence, rewrite that sentence — don't add a
  contradicting paragraph below it. Only CHANGELOG and gotchas are append-only.
- **Dense, bold-led bullets** — match the surrounding entries. State the
  invariant or trap first in bold, then the mechanism, then file:line or
  commit references.
- **Absolute dates** ("2026-07-22"), never "today" / "recently".
- **No PII in docs**: no personal email addresses, no Composio
  connected-account ids (`ca_…`) — use role descriptions ("the client's
  personal Gmail — id in the Composio dashboard"). Work emails are tolerated
  but prefer names.
- **Mirror less, point more.** Don't hand-copy column lists or route
  signatures the code already expresses — state the invariant and point at
  the file. Hand-mirrored reference lines were the #1 source of doc rot.

## Step 4 — verify

```bash
bash scripts/check_doc_refs.sh
```

Must pass before committing: it checks internal anchors resolve, referenced
docs/ paths exist, gotchas are contiguous 1..N with no duplicates, and the
documented migration head matches `apps/api/migrations/versions/`. If you
added a heading or a gotcha, it will catch numbering/anchor mistakes here
rather than in the next incident.

Then stage the doc edits **with** the code change — one commit/PR, so the
diff reviewer sees code and its documentation move together.
