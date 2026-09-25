---
name: git-commit-messages
description: House rules for writing git commit messages — subject/body structure, imperative mood, 50/72 wrapping, and what belongs in the body. Use whenever writing a commit message, amending one, squashing, rewording during rebase, or drafting a PR title/description. Sourced from tpope's "A Note About Git Commit Messages" and cbeams' "How to Write a Git Commit Message".
---

# Writing git commit messages

A diff shows *what* changed. Only the message can say *why*. The message is
read by every future person doing `git log`, `git blame`, `git shortlog`, or
bisecting a regression — write for them, not for the moment of committing.

## The seven rules

1. **Separate subject from body with a blank line.** Git tooling treats the
   first line as the title and everything after the blank line as the body.
   No blank line = no body, just a very long title.
2. **Limit the subject line to ~50 characters.** Not a hard cap, but a hard
   ceiling of 72 — GitHub warns at 50 and truncates at 72.
3. **Capitalize the subject line** — unless a project convention overrides it
   (see below).
4. **Do not end the subject line with a period.** Wasted characters.
5. **Use the imperative mood in the subject.** Test:
   *"If applied, this commit will ___."*
   - ✓ `refactor subsystem X for readability`
   - ✗ `fixed bug with Y` / `fixes bug with Y` / `fixing bug with Y`
   Rationale: git's own generated messages (`merge`, `revert`, `cherry-pick`)
   are imperative. Match them.
6. **Wrap the body at 72 characters.** Git never wraps for you. `git log`
   pages with `less -S` and indents 4 columns each side — 72 keeps it inside
   an 80-column terminal, and leaves room for `>` quoting when
   `git format-patch` turns the commit into an email.
7. **Use the body to explain what and why, not how.** The code is the *how*.
   The body carries: what the problem was, why this approach, what was
   considered and rejected, what the reader would otherwise get wrong.

## Template

```
type(scope): summary in the imperative, under 50 chars

Body wrapped at 72 columns. State the problem first — what was broken,
what was missing, what the previous behaviour was. Then the change and
why this shape of it.

Blank line between paragraphs.

- Bullets are fine; hyphen or asterisk, single space, hanging indent
- Blank line between bullets if any of them run long

Refs #123
```

## Project conventions override rule 3

This repo (and most repos using Conventional Commits) uses a lowercase
`type(scope):` prefix with a lowercase summary, no period:

```
fix(sentry): scrub tokens from breadcrumb messages, not just data URLs
feat(db): enable RLS on job_heartbeat + revoke anon/authenticated (0063)
docs: archive 013 spec + plan + review (shipped)
```

Follow the surrounding history. Check `git log --pretty=%s -20` before
writing the first commit in an unfamiliar repo. Everything else — imperative
mood, blank line, 72-column body, why-not-how — still applies unchanged.

## When a one-liner is enough

Small, obvious, self-contained changes (a typo, a version bump, a lint fix)
need no body. If the subject alone leaves any "but why?" unanswered, write
the body. Multi-paragraph bodies are cheap and permanent; the reconstruction
work you save later is not.

## Anti-patterns

- `fix bug` / `update code` / `changes` — says nothing.
- `Fixed the thing where the parser blew up on empty input.` — past tense,
  trailing period, no body explaining why empty input reached the parser.
- A 200-character single line with the whole rationale crammed in.
- Body that narrates the diff line by line. The diff already does that.
- Committing several unrelated changes so the message has to say "and".
  Split the commit instead.

## Trailers

Keep machine-read trailers at the bottom, after a blank line:
`Refs #`, `Fixes #`, `Co-Authored-By:`, `Signed-off-by:`.

## Sources

- https://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html
- https://cbea.ms/git-commit/
