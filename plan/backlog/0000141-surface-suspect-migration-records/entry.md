---
title: "Backlog Entry: 0000141 - surface suspect migration records"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000141 - surface suspect migration records

**Source feature:** 0000035-write-gate-scope-and-path-hardening
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-22

---

## Problem

Any agent can write `plan/_migrations/{stem}.md`, because `plan/` is always permitted. A record with outcome `applied`, `not applicable`, or `skipped` stops that migration from running again. For a migration marked "Safe to skip: No", that leaves a needed change unapplied. The worst case is `migrate-0.31.0-rerun-setup-for-shell-write-guard.md`, which would leave the shell-write guard uninstalled.

ADR-019 says every downstream migration applies, but the migrator skill doesn't enforce it. The record body must name a reason, but nothing checks the reason. Risks R-021 and R-022 in the 0000035 risk register record this.

## Suggested Action

Resume detection or the migrator lists every record whose outcome is `not applicable` or `skipped` for a migration marked "Safe to skip: No". The human on the loop then sees each one and can confirm or rerun it.

## Positioning note (2026-10-26)

The 0000279 differentiation review raises the priority of this entry. Under audit, a record that any agent can write is not evidence that a control was applied. Pair it with 0000289, so each migration record names who wrote it and can't change unseen.

## Why Deferred

P5 records findings and fixes defects in the feature's own code. This change adds a new check to resume detection and the migrator, which needs its own design.
