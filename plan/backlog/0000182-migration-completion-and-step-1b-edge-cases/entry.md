---
title: "Backlog Entry: 0000182 - Migration completion and step 1b edge cases"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000182 - Migration completion and step 1b edge cases

**Source feature:** 0000036-pipeline-friction-and-gate-fixes
**Source phase:** P5
**Deferral source:** deliberate scope decision
**Date filed:** 2026-10-23

---

## Problem

The second P5 re-review of 0000036 (`plan/_archive/0000036-*/security-rereview-2.md`) rated the feature Low and left three gaps:

- M-1 (Low): if setup can't write a settings file, it prints `could not write ... left unchanged` and still exits 0. The drift check and the hook match then pass, so `planifest-framework/migrations/migrate-0.34.0-rerun-setup.md` step 7 counts the run as complete, and the migrator records `applied` with no hooks wired.
- M-2 (Low): step 1b of the orchestrator's Resume Detection loads source copies when step 1a "found no framework update". A first session fits both that state and the excluded "no recorded previous version" state. Step 1a checks version strings only, so an unversioned change to a source `SKILL.md` also reads as no update. The step's "build log" names no file, and a session with no active feature has none.
- M-3 (informational): a regular `design.md` whose open fails with `EIO` or `ETIMEDOUT` now blocks, which fails closed. The block message says the file is not a regular file, which is wrong for that case.

## Suggested Action

Treat any `!` warning line from setup as an incomplete run in the migration's completion rule. Rewrite step 1b's allowed states so a first session and an unversioned change load no source copy, and name `plan/current/build-log.md`. Give the gate a separate reason line for an open error on a regular file. Backlog 0000181 covers the step 1a detection gap that M-2 rests on.

## Why Deferred

Each gap is Low and needs a wording or rule decision. P5 had already run two fix rounds with fresh re-reviews, and each round found smaller edge cases. The P5 gate passes at Low with no Critical, High, or Medium finding.
