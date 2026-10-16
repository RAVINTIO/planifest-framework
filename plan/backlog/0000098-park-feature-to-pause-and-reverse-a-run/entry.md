---
title: "Backlog Entry: 0000098 - Park a feature to pause and reverse a part-finished run"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000098 - Park a feature to pause and reverse a part-finished run

**Source feature:** 0000032-governance-continuity-and-write-gate-scope (raised by the human on the loop)
**Source phase:** P0
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-16

---

## Problem

The Pause command stops a run so it can resume later. The framework has no way to park a part-finished feature. Parking would stop the run and unpick its progress, so other work can start from a clean state. Today the human must revert commits and clear `plan/current/` and the sentinels by hand.

## Suggested Action

Add a "park feature" command. It saves the run's artifacts somewhere it can resume from, for example a parked folder under `plan/`. It then reverts the run's changes outside `plan/` and clears the sentinels. A later P0 offers parked features for pickup, as it does for backlog entries.

## Why Deferred

Out of scope for 0000032. It needs its own design for what it reverts, where parked state lives, and how a parked feature resumes.
