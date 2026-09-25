---
name: qa-dry-loop
description: Run the loop-until-dry adversarial QA process on a feature branch — repeated fleet rounds (parallel finders → skeptic verification → fold the survivors) until a round finds nothing, which is the evidence-based answer to "are there bugs left?". Use this whenever a substantial feature is code-complete and the owner asks to QA it hard, "run a round of QA", "check for remaining bugs", "review until clean", "make sure there are no bugs", or before flipping a prod lever on a risky feature. Also use it to run ONE fleet round on a fold commit (iteration N+1 of an existing loop).
---

# QA dry loop — adversarial fleet rounds until a clean round

The premise: one review pass finds the bugs that are easy to find. The bugs
that ship are the ones living in the seams *between* fixes — so every round of
fixes gets its own round of hunting, and the loop only ends when a full-strength
round comes back empty ("dry"). A dry round is evidence; "we reviewed it twice"
is not. Expect several rounds, and expect the worst bug to turn up inside code
an earlier round's fixes touched — that is the seam the loop exists to cover.

Requires the Workflow tool (multi-agent orchestration) and owner opt-in — fleet
rounds cost real tokens (roughly 1–2.5M per round). Confirm scale before the
first round; after that the standing plan ("loop until dry") carries.

## The round

One round = one Workflow run. Full script template + prompt patterns:
**read [references/workflow-script.md](references/workflow-script.md) before
writing the script** — it carries the exact scaffold, schemas, and the traps.

```
3 FINDERS (parallel, different lenses)      2 SKEPTICS per unique finding
┌─ diff-reviewer: ONLY the newest fold ─┐   ┌─ reproduce: "reproduce it for
│  commit + its interactions with the   │──▶│  real or it is refuted"
│  previous folds                       │   │
├─ lifecycle-prober: drives REAL         │   ├─ design-intent: "if the spec or
│  endpoints + DB end-to-end, compares  │──▶│  a disposition doc settles it,
│  every intermediate against the spec  │   │  or the claim misreads the code,
├─ fresh-eyes: cold-reads the whole      │   │  it is refuted"
│  branch diff, BANNED from reusing     │   │
│  prior rounds' leads                  │   └─ default refuted=true when
└────────────────────────────────────────┘      uncertain; survives only if
        dedupe by file+claim prefix             BOTH skeptics fail to refute
```

Why this shape works:
- **Different lenses beat more eyes.** Three finders re-reading the same diff
  converge; a diff-reviewer, a prober that *executes* the code, and a cold
  reader see disjoint failure classes. The prober is the one that catches what
  static reading can't — give it the hermetic test DB and the real HTTP layer,
  and have it compare every intermediate state against the spec's tables.
- **Skeptics kill the plausible-but-wrong.** Finders overclaim; that's fine —
  the two-skeptic gate (one must reproduce, one checks it isn't settled design)
  means only real defects cost a fold. Skeptics may CONFIRM mechanics yet still
  kill on design-intent — record those kills with reasons, they're decisions.
- **Fresh-eyes must be barred from prior leads** or every round re-litigates
  round one. Point it at the disposition docs and say "anything in these files
  is settled".

## The fold (between rounds)

Every survivor gets fixed before the next round — no carrying findings:

1. Fix each survivor; add a **regression test per backend logic bug** (FE-only
   repos gate on typecheck + build). The regression test encodes the exact
   scenario the finder proved, not a nearby one.
2. Full suite + typecheck + build green.
3. Write a dated **disposition doc** (`dev-team/NNN-review-rX-fold.md`): every
   survivor + its fix, every kill + why, and a *deliberately-not-fixed* list.
   These docs are the loop's memory — the next round's prompts cite them as
   settled ground, which is what stops the fleet from re-reporting.
4. One commit per fold, pushed. The next round targets **this commit** — fixes
   create seams, and the seams are where the next round's findings live: a fix's
   own mechanism is often still alive on a sibling endpoint it didn't cover.

## Convergence and exit

- **The severity trajectory is the convergence signal.** Healthy loop:
  logic bugs → contract bugs → copy/disclosure gaps → dry. If severity isn't
  falling by round 3, the feature needs design work, not more QA.
- **Raise the bar in late rounds.** Once a round comes back all-LOW, tell the
  next round's finders: only findings with a concrete user-visible or
  data-integrity consequence count; copy nits go in the clean summary. Without
  this the loop asymptotes into hint-sentences-about-hint-sentences forever.
- **Declare a hard stop one round ahead.** "QA-N is final: dry ends it clean;
  anything sub-LOW gets documented, not folded." Write that rule into the fold
  doc so it's a commitment, not a mood.
- **Exit = a dry round from a full-strength fleet.** Close with a short
  `rX-dry.md` doc recording what the dry round actually verified (suite count,
  lifecycles driven, debris greps) — that doc is the shippable evidence.

## Traps (each of these burned us once)

- **False dry.** A workflow can return `dry: true` because every agent FAILED
  (session limits, API errors) — `survivors: []` with zero work done. Always
  check the run's `agents_done` / failure list before believing a dry verdict.
- **Prober artifacts.** Backdating rows to force a fire changes what
  consumption-floor math *means* — a probe that fakes time can manufacture a
  "bug". Skeptics must reproduce with a faithful simulation before a timing
  finding survives.
- **Probes must never mutate the worktree.** Agents write probes under the
  session scratchpad and treat the branch as read-only; concurrent agents that
  edit the tree produce phantom test failures for each other.
- **Dedupe before verifying**, not after — two finders phrasing one defect two
  ways otherwise costs four skeptic runs and returns "two" survivors.
- **The fold can introduce bugs.** That is the entire reason the loop re-runs.
  Never merge on the round that found things; merge on the round that found
  nothing.
