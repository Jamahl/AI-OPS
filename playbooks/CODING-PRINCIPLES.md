# Coding principles

Stack-agnostic merge of the rules in [`claude/CLAUDE.md`](../claude/CLAUDE.md),
[`agents/codex/AGENTS.md`](../agents/codex/AGENTS.md) and
[`agents/windsurf/global_rules.md`](../agents/windsurf/global_rules.md). Paste into any agent's
global instructions.

## Core
- **Minimal impact** — touch only what's needed; no sweeping or unrelated changes.
- **Don't break working code.** Grep callers before changing shared code. This is paramount.
- **Root causes only** — no temporary fixes, no stopgaps meant to be replaced later.
- **DRY** — modular, reusable, testable. Be ruthless about what you write. But three similar lines
  beat a premature abstraction.
- **Simplest thing that fully works** — no speculative abstraction, config, or indirection (YAGNI).
- **No TODOs or placeholders** — implement fully.
- **No backward-compat shims for callers you control** — delete the old path, fix every call site.
  Callers you don't control (live deploys, stored rows, webhooks, public APIs) are contracts.
- **Search before building** — reuse existing deps and patterns; check library docs before assuming
  a capability is missing.
- **If uncertain, say so** — never guess.
- **Self-review**: would a principal engineer approve this? Is there a more elegant way?
- Wide-reaching architecture decisions need human sign-off; feature-scoped ones are autonomous.

## Code standards
- Absolute minimum code that is functional, elegant, correct.
- Early returns; descriptive names; event handlers prefixed `handle`.
- Types everywhere they help; `const` arrow functions over `function` (TS/JS).
- Small, focused files and functions.
- Read a file before editing it; follow its existing patterns and comment density.
- Document where it helps, never verbosely.
- Don't overcomplicate state, auth, or patterns.
- Accessibility: keyboard reachable, `aria-label`, `onKeyDown` alongside `onClick`.
- Performance: code splitting, optimised images, minimal re-renders.

## UI / UX
- Mobile-first, responsive; for native apps use platform gestures and primitives.
- Stay inside the existing design system — no new UI kits unless asked.
- Think like a user and a PM: flows must make sense, not just compile.

## Errors & debugging
- Trace the full user flow; fix the cause, not the symptom.
- Descriptive logging to isolate issues; validate inputs and outputs (security first).
- Bug fix starts with a failing test.
- After a fix, say exactly how to test and confirm it.

## Workflow
- Plan before coding on non-trivial work: concise pseudocode plan with decisions → confirm → code.
- Work one task at a time; stop after each and say what/how to test.
- Keep the project overview doc current (see [doc-system](../doc-system/PLAYBOOK.md)).
- Never push without permission (or an explicit wrap-up workflow).
