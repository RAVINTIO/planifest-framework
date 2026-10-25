---
title: "Backlog Entry: 0000137 - Migration progress file lives in the framework folder"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000137 - Migration progress file lives in the framework folder

**Source feature:** 0000035-write-gate-scope-and-path-hardening
**Source phase:** P1
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-22

---

## Problem

`ravintio-framework/migrations/migrate-adoption-mode-and-about-md.md` keeps its resume state in `ravintio-framework/migrations/_progress/migrate-adoption-mode-and-about-md.json`. ADR-005 and ADR-006 in `docs/decisions-index.md` describe the same layout.

That file is per-project run state inside the framework folder. It has the coupling that 0000126 removes for run records. A framework refresh can overwrite or drop it, and a progress file left in the framework repo would ship to every downstream project.

## Suggested Action

Move resumable progress files to `plan/_migrations/{stem}.progress.json`, beside the run record from 0000035 req-007. Update the migration file and ADR-006 to match.

## Why Deferred

0000035 req-007 covers the completion record only. Progress files need their own change to the resumable-migration layout from ADR-006.
