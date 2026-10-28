---
title: "Backlog Entry: 0000292 - decide whether to build RAVINTIO Framework with RAVINTIO Zero"
summary: "The human on the loop is weighing Zero as the build tool for this repository. Trial it on one bounded change, and test Framework on separate consumer repositories."
status: "open"
---
# Backlog Entry: 0000292 - decide whether to build RAVINTIO Framework with RAVINTIO Zero

**Source feature:** none (human request)
**Source phase:** none (human request)
**Deferral source:** human request
**Date filed:** 2026-10-26

---

## Problem

This repository builds Framework with Framework. The human on the loop is weighing a switch to Zero, raised during the 0000279 differentiation review.

Reasons for the switch:

- Most open entries harden hooks, setup, and CI. Framework's full pipeline is more ceremony than that work needs. Zero's question, "How can we build this with minimal ceremony?", fits it.
- Framework enforces itself while it changes itself. Its hooks gate edits to its own enforcement files, and its migrations run against its own source (0000136, 0000180). A separate build tool removes that loop.
- Recent features started in Zero and reached Framework as ports, such as 0000244, 0000263, and 0000268.

Reasons against:

- Building with Framework is the main source of evidence about Framework. P8 build reports, loop-precision data (0000048), and token measurements (0000234) all come from runs in this repository.
- The governance features in 0000279 need a run to prove them. Without Framework runs here, only consumer projects such as `ovelunor` would exercise them.
- Both packs use the same layout. Each installs `CLAUDE.md`, `plan/` with `backlog/`, `_archive/`, and `changelog/`, `ravintio-overrides/`, and hooks in `.claude/settings.json`. Installed side by side, they would compete for the boot file, the hooks, and the backlog ID sequence.
- `ravintio-framework/` here is both the product source and the installed pack. Under Zero, it would become source only, and the repository would need another way to test an install.

## Suggested Action

Treat it as a decision with a trial, not a switch:

1. Separate product from tooling. Test Framework by installing it into fixture or consumer repositories, rather than relying on this repository's own install. That also matches what users have.
2. Trial Zero on one bounded change, such as a batch of setup or Windows CI entries. Compare it with a similar past Framework run on time, tokens, rework, and defects found after merge.
3. Keep at least one real Framework run per release on a consumer repository. Use it for the governance features in 0000279 and for P8 evidence.
4. Before installing Zero here, decide which pack owns `CLAUDE.md`, the hooks, and the backlog sequence. Migrate this repository's history if Zero takes over.
5. Record the decision as an ADR, whatever the trial shows.

## Option: keep both packs and switch with setup (2026-10-27)

The human on the loop proposed vendoring `ravintio-zero/` next to `ravintio-framework/` and running either pack's setup to switch builds. A read of both setup scripts on 2026-10-27 found that part of this works already. Nobody has run a switch yet.

What already works:

- Both setups write the same `.claude/skills/.ravintio-manifest`. A switch prunes the skills the other pack listed, then installs its own. The two packs share skill names such as `ravintio-orchestrator`, so this matters.
- Both write `CLAUDE.md` from their own boot template. Both also read the shared `ravintio-overrides/instructions/`, so repo rules such as GUTD carry across.
- Both skip `.github/workflows/ravintio.yml` when it exists. Framework's CI and test suite keep running under either pack.
- Hook files share paths under `.claude/hooks/enforcement/`, so the last setup's files win.

Gaps to close before the switch is safe:

1. **Stale hook wiring.** Each setup removes only its own hook commands from `.claude/settings.json`. After a switch to Zero, Framework's `shell-write-guard` stays wired. It may fail to load, because Zero doesn't install `path-rules.mjs`. After a switch back, Zero's `merge-guard` (Bash) and `check-reply-prefix` (Stop) stay wired. `check-reply-prefix` expects Zero's `P2 Implement:` form, so it would flag every Framework `P3:` reply.
2. **Shared run state.** Both packs read `plan/current/` and `plan/.orchestrator-active`, with different phase sets. Zero runs P0 to P4 and Framework runs P0 to P9. Zero also writes `plan/.orchestrator-strict`, `plan/.initiative-*`, and `plan/.roadmap-logs/`. A switch must refuse while a run is active or a sentinel exists.
3. **Migrations.** Each orchestrator scans its own pack's `migrations/` and records outcomes in the shared `plan/_migrations/`. The first Zero session here would offer Zero's pending migrations, such as `0004-ravintio-rename.md` and `0005-initiative-rename.md`. Check each `Applies when` condition against this repo first.
4. **Manifest pruning.** 0000272 found that Framework's manifest lists every folder under the skills folder, including ones it didn't install. A switch could then prune a person's own skill.
5. **Weaker self-protection under Zero.** Zero's `gate-write` checks paths against the design's component paths only. It has no enforcement-path list and no shell guard. Under Zero, a design that lists `ravintio-framework/hooks/` admits changes to Framework's own enforcement.
6. **Two packs to keep current.** The vendored `ravintio-zero/` copy needs its own update and provenance check (Resume Detection step 1a covers only `ravintio-framework/`).

Suggested shape (revised 2026-10-28):

- Give each pack an uninstall script that pairs with its setup (0000293). Each pack then knows only about itself. A switch runs one pack's uninstall, then the other pack's setup.
- The uninstall refuses while `plan/current/` holds artefacts or a run sentinel exists. That closes gap 2.
- The install record in 0000293 replaces the manifest and closes gap 4.
- Gaps 3, 5, and 6 stay open. Settle them before the trial.
- File the matching uninstall entry in the Zero repository.

This option makes the trial in steps 2 and 3 above cheap to run and to reverse.

## Wanted outcome

A recorded decision, based on one measured trial, on which tool builds this repository. Framework still gets at least one real run per release, wherever it runs.

## Why Deferred

The human on the loop raised the idea and said it may or may not be a good one. It changes how the repository builds itself, so it needs a decision before any setup change.
