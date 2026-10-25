---
title: "Backlog Entry: 0000239 - Pre-P0 discussion is lost at the mandatory context reset"
summary: "Backlog triage, item targeting, and migration handling often happen before Phase 0 Start Actions writes build-log.md or discovery.md. The Context Hygiene reset at step -1 then discards that discussion, and the human on the loop has to re-paste it."
status: "open"
---
# Backlog Entry: 0000239 - Pre-P0 discussion is lost at the mandatory context reset

**Source feature:** none. The orchestrator found this during a pre-P0 flow, before a feature ID existed.
**Source phase:** P0 (Context Hygiene step -1, before Phase 0 Start Actions)
**Deferral source:** discovered mid-flight
**Date filed:** 2026-08-08

> First filed on 2026-08-08 as 0000047 in commit `14d14465`. That commit stayed on a local backup branch and never reached `main`. A component-manifest entry also used 0000047 before feature 0000028 renumbered it to 0000061. Re-filed on 2026-10-25 as 0000239, the next unused ID.

---

## Problem

Real discussion often happens before Phase 0 Start Actions step -1 runs. A typical session goes like this:

1. The human on the loop asks what is in the backlog.
2. The assistant lists and summarises the open entries.
3. The human names the entries to target.
4. A pending-migration check runs and resolves inline.

None of this reaches `plan/current/build-log.md` or `plan/current/discovery.md`. Phase 0 Start Actions creates both files only after the reset. Step -1 then issues `/clear` or the manual-clear flag, and the whole exchange is gone.

The 2026-08-08 session lost these facts at the reset:

- The targeted entries: 0000043, 0000034, 0000035, 0000044, 0000045, 0000046, 0000024, and 0000021.
- The result of the migration check. The `migrate-product-yml-component-paths.md` migration was already applied.
- The reasoning behind both decisions.

The human on the loop recovered them only by re-pasting the transcript. A reset that loses decisions is lossy rather than hygienic.

Step -1 now lives in `planifest-framework/skills/planifest-orchestrator/references/phase-0-assess-and-coach.md`. The Context Hygiene section of `planifest-framework/skills/planifest-orchestrator/SKILL.md` defines the procedure. Neither file persists pre-reset state as of 2026-10-25.

## Suggested Action

Persist any pre-P0 state to a durable artifact before step -1 fires. Phase 0 Start Actions then reads it back. Options to weigh at pickup:

- **(a) Create `build-log.md` earlier.** A "P0 pre-flight" block captures targeted entries and migration handling before the reset.
- **(b) Write a scratch file.** The orchestrator writes `plan/current/.pre-p0-notes.md` before the reset, folds it into `discovery.md` and `build-log.md`, then deletes it.
- **(c) Reset at the first prompt.** Step -1 runs before any backlog or migration discussion, so nothing exists to lose.

Option (c) costs least but breaks the usual pattern, because people ask about the backlog before starting P0. Options (a) and (b) keep that pattern and make it durable.

## Why Deferred

The 2026-08-08 session had already targeted a different batch of entries. This gap sits in the orchestrator's own Context Hygiene protocol and needs its own design decision.
