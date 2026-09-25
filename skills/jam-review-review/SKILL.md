---
name: jam-review-review
description: >-
  Pressure-test a proposed bug fix before it gets applied — a review of the review. Use this after a codebase
  review or bug report has produced one or more suggested fixes, and the question is whether each fix is
  actually the right one: does it address the root cause or just the symptom, is it the minimal-but-complete
  change (not an over-fit one-off and not an over-engineered refactor), does it hold up under scale and data
  growth, does it respect multi-tenant isolation, does it break other callers or other routes, and does the
  same bug class exist elsewhere in the codebase. Trigger whenever someone asks "is this the best fix?",
  "will this scale?", "does this consider other tenants / other routes?", "what does this break?", "is this
  over-engineered?", or "should I apply this fix?" — and also proactively before applying any non-trivial fix
  that came out of a review, even without those exact words. This is an adjudication layer that runs on an
  existing fix proposal; it does not find bugs from scratch.
---

# Jam Review Review

A bug report tells you *what's wrong* and proposes *a* fix. This skill reviews that review — it decides
whether the proposed fix is the *right* fix, by actually investigating the codebase, not by re-reading the
report.

## The failure mode you're guarding against

A reviewer (human or agent) finds a bug on one route, writes a patch that makes the symptom disappear, and
moves on. The patch ships. Three things commonly go wrong, and they pull in opposite directions:

- **Under-fix:** the patch suppresses the symptom but not the cause, so the same bug resurfaces through a
  different trigger; or the identical bug class lives on five other routes that nobody checked; or it breaks
  tenant isolation under load that the single repro never exercised.
- **Over-fit:** the patch special-cases the one input from the repro (`if id == 1234: ...`), so it "passes"
  but solves nothing general.
- **Over-engineer:** a three-line guard clause becomes a 400-line refactor that rewrites working code,
  increases surface area, and creates merge risk for no proportionate benefit.

Your job is to land in the narrow band between these: **the smallest change that resolves the root-cause
*class*, generalises to its sibling instances, survives scale and multi-tenancy, and breaks nothing
downstream.** Comprehensive but minimal. Not one without the other.

The operational definition of the right scope: **the root-cause class is every input, route, and tenant that
can trigger the same cause — fix exactly that set, nothing narrower, nothing wider.**

## Core principle: scale your scrutiny to the blast radius

This skill embodies the same discipline it enforces. A typo in a log string does not warrant a tenant-isolation
audit. A change to a shared auth middleware warrants a very thorough one. **Triage first, then spend effort
proportional to what the fix actually touches.** Over-reviewing a trivial fix is itself a form of the
over-engineering you're trying to catch.

---

## Inputs you need

Before adjudicating, make sure you have:

1. **The proposed fix** — the actual diff or the described change. If it's prose ("add a null check"), pin it
   down to the concrete edit and file before evaluating; you can't review what isn't specified.
2. **The bug and its claimed root cause** — what was observed, and what the report says is causing it. If the
   report only describes a symptom and never names a root cause, that's your first finding: the fix is
   probably aimed at the symptom.
3. **Codebase access** — you must be able to read the surrounding code, grep for call sites, and open sibling
   files. If you don't have it, say so; an adjudication done from the report alone is speculation, and you
   should label it `confidence: low (report-only, unverified)` rather than present it as a verified finding.

If the report contains multiple fixes, adjudicate each one separately — they have independent verdicts.

---

## Step 1 — Triage the fix

Classify the change so you know how hard to look. Be quick here.

- **Local / leaf:** touches code with no other callers, no shared state, no tenant data, no hot path
  (e.g. a copy string, a local variable, a single-use helper). → Light review. Confirm root cause, confirm
  no sibling instances, done.
- **Shared / structural:** touches a function with multiple callers, a shared utility, middleware, a
  data-access layer, a query, schema, config, or anything on a request hot path. → Full review, all four
  lenses below.
- **Cross-cutting / systemic:** touches auth, tenancy/isolation, money, migrations, permissions, or
  anything where a mistake is irreversible or leaks data across tenants. → Full review plus explicit
  reversibility and isolation analysis, and treat your default verdict as *Amend* until proven otherwise.

State which bucket the fix is in and why, in one line. That decision is itself reviewable by the user.

---

## Step 2 — Investigate along four lenses

Investigate **empirically**. The point of this skill is that you go and look — grep, open files, trace
callers — and report what you actually found, with file:line evidence. Rhetorical questions ("one should
consider whether…") are worthless here. Either you checked and here's what's there, or you couldn't check
and you say so.

**Deriving the search pattern from the bug.** Most bugs are a *missing guard around a recognisable operation*:
a query missing a tenant filter, an endpoint missing an auth check, an input used without validation, a
resource opened without a close. Turn the bug into a search by naming the *operation*, then grep for every
occurrence of that operation and inspect each hit for the guard. The bug instance in the report is one hit;
the siblings are the other hits missing the same guard. If you can't name an operation to search for, you
probably haven't located the real root cause yet — go back to Lens A.

### Lens A — Is this the right fix?

- **Root cause vs symptom.** Trace from the observed symptom to the line being changed. Does changing it
  remove the *cause*, or just stop *this* manifestation? A fix that catches an exception thrown by a bad
  query is treating the symptom; fixing the query is treating the cause.
- **Minimality.** Is there a smaller change that fully resolves the root-cause class? If the proposed fix
  rewrites a working module to fix one branch, that's over-engineering — flag the smaller version.
- **Over-fit.** Does the fix encode the specific repro (a magic id, a hard-coded value, a single input
  shape) rather than the general condition? If so it will pass the one test and fail its siblings.
- **Is there a materially better fix?** Don't reflexively invent an alternative — a different-but-equivalent
  approach is noise and pushes toward over-engineering. Propose an alternative *only* when it is materially
  better on a named axis: lower risk, broader coverage of the root-cause class, or meaningfully smaller. If
  the proposed fix is the right call, say so plainly and move on. This is the honest answer to "is this the
  very best fix?" — including when the answer is "yes, ship it."

### Lens B — Does it scale and fit how the app is built?

- **Behaviour under load and data growth.** Does the fix introduce or preserve an N+1 query, an unbounded
  loop, a full-table scan, a missing index, in-memory state that won't survive horizontal scaling, or new
  lock/contention on a hot path? A fix that's correct for 100 rows and quadratic at 1M rows is not a fix.
- **Multi-tenancy / isolation.** This is a first-class concern, not an afterthought. Does the fix preserve
  tenant scoping on every query and cache key it touches? Does it bake a single tenant's assumption into
  shared code? Could it leak or cross-contaminate data between tenants under concurrency? If the codebase is
  multi-tenant, *verify the tenant filter is present in the changed query* — don't assume it.
- **Architectural direction.** Does the fix follow the patterns this codebase already uses, or bolt on a
  one-off that the next person will copy badly? A fix that fights the existing structure adds entropy even
  when it works. Prefer the fix that fits where the app is growing.

### Lens C — What does it touch, and what does it break?

- **Blast radius / call sites.** Grep for every caller of the function or signature being changed. Will the
  change alter behaviour, return shape, error semantics, timing, or ordering for any of them? Shared code is
  where "small" fixes cause regressions.
- **Sibling instances on other routes.** This is the heart of "does this consider other routes?" If the bug
  is a missing auth check / missing tenant filter / unvalidated input on route X, the same omission almost
  always exists on routes Y and Z. Use the search pattern from above and report which siblings share the
  defect, with file:line. A fix that patches one of five instances is a *partial* fix and must say so.
- **New failure modes.** What can now go wrong that couldn't before? Does the fix introduce a race, change an
  error into a silent success (or vice versa), swallow an exception, or change a contract consumers depend on?
- **Reversibility.** For migrations, schema changes, data backfills, or destructive operations: is it
  reversible? What's the rollback? Cross-cutting changes need this explicitly.

### Lens D — How do we know it's right?

- **A test that proves it.** Is there a test that fails before the fix and passes after, exercising the
  *root cause*, not just the repro? If the report didn't include one, specify it.
- **Coverage of siblings.** Does the test (or a parametrised version) also cover the sibling instances from
  Lens C, so the bug class can't quietly reappear elsewhere?

---

## Step 3 — Render a verdict

End with one of three verdicts per fix, each with an explicit confidence level:

- **Ratify** — the proposed fix is correct, minimal, complete, and safe. Apply as-is. (Still note siblings and
  the proving test if they're missing.)
- **Amend** — the fix is on the right track but needs specific changes: extend to siblings, add the tenant
  filter, shrink the over-engineered part, add the test. Give the concrete amended version.
- **Replace** — the fix targets the symptom, over-fits, or is the wrong approach. Give the better fix and say
  why it's better.

**Confidence:** tag the verdict `high` (verified against the code), `moderate` (mostly verified, one or two
assumptions stated), `low` (report-only or couldn't access key code — say what you couldn't check), or
`unknown`. A confident-sounding verdict you didn't verify is worse than an honest low-confidence one.

**Severity escalation.** If a sibling instance or a secondary risk you uncovered is *as severe or more severe*
than the original bug — e.g. you went to fix a display glitch and found the same unscoped query leaking data
across tenants on four endpoints — say so loudly at the top and re-rank. The most important output of an
adjudication is often not a verdict on the original fix but the bigger thing you found while checking it.

Then provide:

1. **The recommended change** — the actual edit (diff or precise description), at the right scope: as small as
   possible, as broad as the root-cause class requires.
2. **Sibling instances** — the list of other locations carrying the same defect, with file:line, and whether
   your recommended change covers them or they need follow-up.
3. **Secondary risks introduced** — anything the fix could break, with how to mitigate or verify.
4. **The proving test** — what it asserts and that it covers the class, not just the instance.

---

## Output template

Use this structure. Keep it tight; depth scales with the triage bucket.

```
## Review review: <short bug name>

**Proposed fix:** <one-line summary of the change + file>
**Claimed root cause:** <what the report says> — <confirmed / it's actually a symptom of X>
**Triage:** <local | shared | cross-cutting> — <why, one line>

**Verdict: RATIFY | AMEND | REPLACE  (confidence: high | moderate | low | unknown)**
<one or two sentences: the bottom line>
<if applicable: ⚠ ESCALATION — the siblings/secondary risk are more severe than the original bug: ...>

**Findings**
- Right fix? <root cause vs symptom; minimality; over-fit; materially better alternative only if one exists>
- Scale & architecture? <load/data growth; multi-tenancy/isolation; fit with existing patterns>
- Blast radius & regressions? <call sites checked; sibling instances found w/ file:line; new failure modes; reversibility>
- Proof? <test that fails-before/passes-after and covers the class>

**Recommended change**
<the actual edit, at the right scope>

**Siblings to fix (same defect class)**
<file:line list, or "none found — searched for <pattern>">

**Secondary risks**
<what to watch / verify, or "none material">
```

For a `local`-bucket fix, collapse the Findings to the one or two lines that actually matter and skip the
sections that don't apply — don't pad a trivial fix into a full report. That padding is the over-engineering
this skill exists to prevent.

---

## Worked example

**Input — from the bug report:**
> Bug: `GET /api/orders/[id]` occasionally returns another customer's order.
> Proposed fix: in the orders route handler, add
> `if (order.tenantId !== session.tenantId) return res.status(403)`.

**Output:**
```
## Review review: cross-customer order leak on /api/orders/[id]

**Proposed fix:** add a 403 tenant check in the orders route handler — app/api/orders/[id]/route.ts
**Claimed root cause:** "missing authorization check in orders route" — symptom. The real cause is an
unscoped data-access read: `prisma.order.findUnique({ where: { id } })` has no tenant predicate.
**Triage:** cross-cutting — tenancy / data leak.

**Verdict: REPLACE  (confidence: high — verified against the code)**
Don't bolt a 403 above an unscoped query. Enforce tenant scope at the data layer so an unscoped read is
impossible by construction.
⚠ ESCALATION — the original report scoped this to one route. The same unscoped pattern exists on three more
endpoints, including documents. This is a cross-tenant data leak on 4 endpoints, not a one-route bug. P0.

**Findings**
- Right fix? The 403 treats the symptom and is over-fit to this one route; you will forget to add it to the
  next endpoint. A data-layer fix is materially better on coverage and risk.
- Scale & architecture? Per-route checks scatter the invariant across handlers; a scoped query (or Prisma
  extension / Postgres RLS) centralises it where the app already does data access.
- Blast radius & regressions? Searched for `findUnique`/`findFirst` reading tenant-owned models without a
  tenant predicate: orders/[id]/route.ts:21, invoices/[id]/route.ts:18, documents/[id]/route.ts:24,
  members/[id]/route.ts:30. All four leak. Adding a tenant predicate returns null → 404 for cross-tenant
  ids; confirm no caller treats null-as-found.
- Proof? Test requesting tenant B's id while authenticated as tenant A asserts 404 — parametrised across all
  four routes so the class can't reappear.

**Recommended change**
Add `tenantId: session.tenantId` to the `where` clause of each of the four reads (or wrap reads in a
tenant-scoped client / enable RLS on these tables). Return 404, not 403, for not-found-in-tenant.

**Siblings to fix (same defect class)**
invoices/[id]/route.ts:18, documents/[id]/route.ts:24, members/[id]/route.ts:30 — covered by the same change.

**Secondary risks**
404-vs-403 change is intentional (don't confirm existence of other tenants' resources). Verify no client
branches on the old 403.
```

Note what the example demonstrates: it rejected a fix that "worked," named the real root-cause class, found
the siblings by searching for the *operation* rather than guessing, escalated because the discovered blast
radius dwarfed the reported bug, and recommended the centralised-but-minimal fix instead of either a one-off
403 or a sprawling refactor.

---

## Anti-patterns (in this skill's own behaviour)

- **Rhetorical review.** Listing the questions without answering them from the code. If you didn't grep, you
  didn't check.
- **Defaulting to Ratify.** If everything looks fine, you probably didn't look hard enough at siblings and
  call sites. Make yourself search before you bless.
- **Defaulting to Replace/refactor.** Rewriting the author's fix because you'd have done it differently is
  over-engineering. Only replace when the proposed fix is genuinely wrong or symptom-only.
- **Inventing a "better" fix that isn't.** If your alternative isn't materially better on risk, coverage, or
  size, don't propose it.
- **Reviewing every fix at maximum depth.** Respect the triage. A leaf fix gets a leaf review.
- **Presenting speculation as verification.** If you lack codebase access, mark the verdict low-confidence and
  say what you couldn't check. Don't dress up a guess as a finding.
