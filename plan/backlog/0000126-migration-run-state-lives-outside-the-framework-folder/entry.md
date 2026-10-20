---
title: "Backlog Entry: 0000126 - Migration run state lives outside the framework folder"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000126 - Migration run state lives outside the framework folder

**Source feature:** 0000035-write-gate-scope-and-path-hardening
**Source phase:** P0 (resume detection)
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-21

---

## Problem

The migrator records that a migration has run by moving its file from `planifest-framework/migrations/` to `planifest-framework/migrations/_done/`. The file and its run state share one location, so a migration can't be complete in one repo and pending in another.

This breaks in the framework source repo. Two migrations sit outside `_done/`:

- `migrate-0.31.0-rerun-setup-for-shell-write-guard.md`
- `migrate-remove-context-mode-and-telemetry.md`

Both target downstream projects. If the migrator ran them here, the move to `_done/` would ship them to every downstream project already marked done. So resume detection flags them as pending at every P0 in this repo, and the orchestrator must skip them by hand.

A downstream project has the same coupling in reverse. A framework refresh copies `planifest-framework/` again, which can bring back a migration the project already ran, or drop the `_done/` record.

## Suggested Action

Keep every migration file in place under `planifest-framework/migrations/`, and never move it. Record each project's run state under `plan/_migrations/`, for example one record per migration that names the file, the outcome, and the date. Resume detection then reads pending migrations as those with no record in `plan/_migrations/`. Update the migrator skill, the orchestrator's resume detection, setup, and the tests that read `_done/`. Decide how existing `_done/` files map to the new layout.

## Why Deferred

Filed at P0 of 0000035 at the request of the human on the loop, who asked to pull it into the same run.
