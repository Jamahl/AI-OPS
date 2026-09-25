# AGENTS.md
- Do not preserve backward compatibility for callers you control. Delete the
  old path and update every call site in the same change — no aliases, no
  deprecation shims, no "keep both for now".
  The test is: **can I see and change every caller from this repo?**
  - Yes → delete it. Renaming an internal service function, dropping a config
    key nothing reads, removing a feature flag after rollout: change the
    definition, fix the call sites, done. A wrapper kept "just in case" is
    debt, and the next reader can't tell it's dead.
  - No → the old path is a contract, and removing it is a breaking change to
    be planned, not a cleanup. Callers you don't control include: a live
    deploy window where the previous version is still serving traffic (drop
    or rename a column only after the code that reads it is gone — additive
    first, contract in a later release); rows already written by older code;
    payloads third parties send you, such as webhooks; and any published
    package, HTTP route, or CLI flag someone outside the repo depends on.
  Do not confuse a runtime fallback with legacy support. A documented
  degradation path — retry, cache miss, secondary provider when the primary
  is unavailable — is a feature that is supposed to fire. Removing it removes
  behaviour the system needs, not dead code.
- Choose the simplest implementation that fully meets the current
  requirements. Avoid speculative abstractions, configuration, and
  indirection.
- Grow the system in layers. Start from the smallest version that works end
  to end, and add each new capability on top of a product that already
  works. Never trade a working product for unfinished complexity.
- Keep components modular and concerns clearly separated.
- Prefer established, well-maintained libraries when they reduce overall
  complexity or improve reliability. Do not reimplement common
  functionality without a clear reason.
- Lean on the dependencies already in the project before writing your own
  implementation or adding packages. Do not assume a library lacks a
  capability without checking its documentation and types.
- Make architectural decisions for the long term. Do not accept a stopgap
  that only works for now and is meant to be replaced later.
- These are defaults. A project-level CLAUDE.md overrides them wherever the
  two conflict — it knows constraints this file cannot.
