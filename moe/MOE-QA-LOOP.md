# Mixture-of-experts QA loop

Fable (Claude) orchestrates; other models serve as independent reviewers. The point is **model
diversity**: different model families catch different failure classes, and agreement between them
is a strong signal. Developed on Orla/Agora (features 006–019, 2026-07 → 2026-09).

## Roles

| Role | Who | Job |
|---|---|---|
| Orchestrator | **Fable** (Claude Code main loop) | Writes spec + code, picks reviewers, writes prompts, triages findings, folds fixes, decides exit |
| In-house fleet | Claude subagents (Opus etc.) via Agent / Workflow | Finder + skeptic rounds — see [`skills/qa-dry-loop`](../skills/qa-dry-loop/SKILL.md). No permission needed |
| External experts | **Devin CLI**: GPT-5.6 Sol, Kimi K3, GLM, SWE | Independent spec / design / impl review rounds. **Owner permission every run** (costs Devin quota) |
| Adjudicator | [`skills/jam-review-review`](../skills/jam-review-review/SKILL.md) | Pressure-tests each proposed fix before it lands: root cause vs symptom, scale, tenancy, blast radius |

## Flow per feature

1. **Spec** → `dev-team/NNN-<feature>.md`. Optional external design review (Sol + K3 in parallel).
2. **Build** (Fable).
3. **Review rounds** — mix of:
   - External: Sol + K3 in parallel, read-only, same worktree. When their HIGH findings converge,
     treat as real.
   - In-house fleet: 3 lensed finders → 2 skeptics per finding → survivors only.
4. **Fold**: fix survivors, regression test per logic bug, run `jam-review-review` on non-trivial
   fixes, write disposition doc `dev-team/NNN-review-rN-<model|fold>.md` (fixed / killed + why /
   deliberately-not-fixed). Next round cites these as settled.
5. **Loop until dry** — a full-strength round finding nothing. Severity should fall each round
   (logic → contract → copy → dry); if not by round 3, it's a design problem.
6. Commit review outputs with the PR.

## Devin CLI recipe

```bash
devin --model gpt-5-6-sol-high --permission-mode auto -p "$(cat prompt.md)" < /dev/null > out.md 2>&1
```

- Model ids: `devin models list` — `gpt-5-6-sol-{low..max}`, `kimi-k3-high`, GLM, SWE.
- **Never** `-p --prompt-file` — hangs on stdin forever. Inline the prompt, close stdin.
- Output buffers until done: empty file = still running. Stalled vs thinking → check CPU time
  (`ps -o pid,etime,time -p <pid>`); stalled runs don't gain CPU → kill + rerun.
- Daily quota can kill runs mid-session. Check usage before parallel high-thinking runs.
- Kill by **specific pid**, never `pgrep -f pattern` — sibling sessions' runs match too.
- Pointing reviewers at the post-fix working tree ("review these changes, here's what/why") beats
  "review this commit".

## Rules

- External review spend is the owner's call — "build it" ≠ permission for Devin runs.
- Agents that run experiments use worktree isolation or the scratchpad; never mutate the shared
  tree while tests run (phantom failures).
- A "dry" result where agents failed is not dry — check agent completion.
- Merge on the round that found nothing, never on the round that found things.
