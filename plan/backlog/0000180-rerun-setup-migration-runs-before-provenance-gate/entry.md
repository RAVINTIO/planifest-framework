---
title: "Backlog Entry: 0000180 - re-run-setup migration runs before the provenance gate"
summary: "A re-run-setup migration installs the arriving framework files before the human on the loop confirms their provenance or sees any finding."
status: "open"
---
# Backlog Entry: 0000180 - re-run-setup migration runs before the provenance gate

**Source feature:** 0000036-pipeline-friction-and-gate-fixes
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-23

---

## Problem

Resume Detection runs pending migrations at step 1 in `planifest-framework/skills/planifest-orchestrator/SKILL.md`. It runs the dependency-update provenance gate later, at step 1a. A re-run-setup migration then installs whatever `planifest-framework/` holds. That covers hooks, settings wiring, skills, and the boot file. If the human on the loop would reject the update at step 1a, setup has already installed those files.

A re-run-setup migration also puts "Re-run setup" under `## Migrator Instructions`, ahead of `## Present Findings`. The migrator therefore runs setup before the human on the loop sees or confirms anything. This holds for `migrations/migrate-0.31.0-rerun-setup-for-shell-write-guard.md` on `main`. The new `migrations/migrate-0.34.0-rerun-setup.md` inherits the same order.

## Suggested Action

Run step 1a before step 1, or make step 1 skip any migration that runs setup until step 1a records a confirmed provenance. Add a confirmation before the setup run in each re-run-setup migration, as `planifest-refresh-setup` Step 4 already does.

## Why Deferred

The order predates 0000036 and needs its own design decision about Resume Detection order. 0000036 adds no new path through it.
