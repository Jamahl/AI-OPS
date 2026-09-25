# Workflow script scaffold for one QA round

The proven shape. Adapt the bracketed parts; keep the
structure — every deviation listed under "Traps" in SKILL.md came from breaking
one of these rules.

## Script skeleton

```js
export const meta = {
  name: 'qaN-dry-check',
  description: 'Loop iteration N: hunt the rX fold, declare dry or find survivors',
  phases: [
    { title: 'Find', detail: '3 finders on the freshest code' },
    { title: 'Verify', detail: '2 adversarial skeptics per finding' },
  ],
}

const WT = '[worktree path]'
const SCRATCH = '[session scratchpad]/qaN'

const ENV_RECIPE = `
## Environment (proven)
Worktree: ${WT}, branch [branch], head [SHA] (= the rX fold; the feature is the
last K commits). DO NOT modify the worktree; probes go under ${SCRATCH}/<yourname>/.
[Exact, copy-pasteable test invocation — for this repo: cd apps/api, source .env
with set -a, then export TEST_DATABASE_URL/DATABASE_URL/MIGRATION_DATABASE_URL at
the hermetic agora_test URL + dummy API keys, then .venv/bin/pytest -q. NEVER
scripts/test_api.sh from an agent.]
Baseline: full suite [N] passed; pnpm typecheck + next build clean.

## Settled ground — do NOT re-report
Spec: [spec path]. Dispositions (ALL settled): [every prior fold doc, newest
last, with its by-design carve-outs summarized inline].

## Bar for this round        ← add from the first all-LOW round onward
Report ONLY findings with a concrete user-visible or data-integrity
consequence. Copy nits and unreachable-API hypotheticals go in clean_summary.
`

const FINDINGS_SCHEMA = {
  type: 'object',
  required: ['findings', 'clean_summary'],
  properties: {
    findings: { type: 'array', items: { type: 'object',
      required: ['id', 'severity', 'file', 'claim', 'scenario', 'fix'],
      properties: {
        id: { type: 'string' }, severity: { type: 'string', enum: ['HIGH', 'MEDIUM', 'LOW'] },
        file: { type: 'string' }, line: { type: 'integer' },
        claim: { type: 'string' }, scenario: { type: 'string' },
        fix: { type: 'string' }, evidence: { type: 'string' },
      } } },
    clean_summary: { type: 'string' },   // REQUIRED — silent coverage is no coverage
  },
}

const VERDICT_SCHEMA = {
  type: 'object',
  required: ['refuted', 'reasoning'],
  properties: {
    refuted: { type: 'boolean' }, reasoning: { type: 'string' },
    severity_adjust: { type: 'string', enum: ['HIGH', 'MEDIUM', 'LOW', 'keep'] },
  },
}

const FINDERS = [
  { key: 'rX-diff',        prompt: `Code reviewer: review ONLY the rX fold commit (git -C ${WT} show [SHA]) plus its interactions with the previous folds. This commit changed: [one line per change]. Hunt for: [3–6 SPECIFIC failure hypotheses drawn from what the fold touched — fixes contradicting each other, a reordered branch breaking another caller, state computed from not-yet-loaded data, closure staleness…]. Run probes where uncertain.${ENV_RECIPE}` },
  { key: 'lifecycle-sweep', prompt: `Lifecycle prober: drive complete REAL lifecycles against the hermetic DB through the actual endpoints + the real background-job entry points, covering combinations prior rounds did NOT re-run after the rX changes: [(a)…(f) concrete end-to-end paths, each naming the assertion]. Compare every intermediate against the spec's tables. Anything deviating is a finding.${ENV_RECIPE}` },
  { key: 'fresh-eyes-N',   prompt: `Fresh-eyes hunter (you may NOT reuse prior rounds' leads — read the disposition files to know what those were): read git -C ${WT} diff HEAD~K..HEAD cold, then chase only what survives the dispositions. Extra attention to: [the surfaces with the fewest prior probe rounds]. Probes allowed.${ENV_RECIPE}` },
]

log('QAN: 3 finders on the rX fold')
phase('Find')
const results = await parallel(
  FINDERS.map((f) => () => agent(f.prompt, { label: `find:${f.key}`, phase: 'Find', schema: FINDINGS_SCHEMA })),
)

const all = []
results.forEach((r, i) => {
  if (!r) return
  for (const fnd of r.findings || []) all.push({ ...fnd, finder: FINDERS[i].key })
})
// Dedupe BEFORE verification — same defect, two phrasings = 4 wasted skeptics.
const seen = new Set()
const unique = all.filter((f) => {
  const key = `${f.file}|${(f.claim || '').slice(0, 60).toLowerCase()}`
  if (seen.has(key)) return false
  seen.add(key)
  return true
})
log(`QAN: ${all.length} raw, ${unique.length} unique`)

phase('Verify')
const verified = await parallel(
  unique.map((f) => () =>
    parallel(
      ['reproduce', 'design-intent'].map((lens) => () =>
        agent(
          `Adversarial skeptic (${lens}). Claim on [branch] (head [SHA]):\nCLAIM: ${f.claim}\nFILE: ${f.file}:${f.line || '?'}\nSCENARIO: ${f.scenario}\nFIX: ${f.fix}\nEVIDENCE: ${f.evidence || 'none'}\n\nREFUTE it. ${lens === 'reproduce' ? 'Reproduce for real or it is refuted.' : 'If the spec or the disposition files settle it, or the claim misreads the code, it is refuted.'} Default refuted=true when uncertain.${ENV_RECIPE}`,
          { label: `verify:${f.id}:${lens}`, phase: 'Verify', schema: VERDICT_SCHEMA },
        ),
      ),
    ).then((votes) => {
      const live = votes.filter(Boolean)
      return { ...f, survives: live.length > 0 && live.every((v) => !v.refuted), votes: live }
    }),
  ),
)

const survivors = verified.filter(Boolean).filter((v) => v.survives)
log(`QAN: ${survivors.length} survivors — ${survivors.length === 0 ? 'DRY ROUND' : 'loop continues'}`)
return {
  dry: survivors.length === 0,
  survivors,
  killed: verified.filter(Boolean).filter((v) => !v.survives)
    .map((k) => ({ id: k.id, claim: (k.claim || '').slice(0, 160), why: k.votes.map((v) => v.reasoning).join(' | ').slice(0, 300) })),
  clean: Object.fromEntries(results.map((r, i) => [FINDERS[i].key, r ? r.clean_summary : 'agent failed'])),
}
```

## Reading the result

- **`dry: true` is only trustworthy if the agents ran.** Check the task
  notification's `agents_done` / `agents_error` (or the `clean` map for
  `'agent failed'`). A run where every agent died on a session limit returns
  `{dry: true, survivors: []}` — a false dry. Re-run it.
- Full per-agent returns live in the run's `journal.jsonl` (one
  `{"type":"result",...}` line per agent, under the `result` key). Read it when
  the notification's payload is truncated.
- `severity_adjust` votes from skeptics override the finder's severity when
  both agree; note adjustments in the fold doc.

## Sizing

A round runs 7–21 agents, roughly 0.75–2.3M tokens, 16–29 min. The final
(post-convergence) round can drop to 2 finders: rX-diff + a whole-branch
integration sweep that also re-runs the full suite and re-verifies every
"deliberately not fixed" claim in the disposition docs.
