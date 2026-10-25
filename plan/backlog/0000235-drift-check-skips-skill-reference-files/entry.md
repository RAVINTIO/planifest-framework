---
title: "Backlog Entry: 0000235 - drift check skips skill reference files"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000235 - drift check skips skill reference files

**Source feature:** 0000038-token-efficiency-windows-shard
**Source phase:** P6
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-24

---

## Problem

`ravintio-framework/scripts/skill-drift-check.mjs` compares each installed `SKILL.md` with its source and nothing else. Feature 0000038 moved about 37 KB of orchestrator rules into `skills/ravintio-orchestrator/references/phase-0-assess-and-coach.md` and `references/adoption-modes.md`. A stale installed copy of either file passes the drift check, so Resume Detection can't warn that the P0 rules are out of date.

## Suggested Action

Extend the drift check to compare a skill's own `references/*.md` files. Apply the same link rewrites that setup applies to them before the byte compare.

## Why Deferred

The cross-model reviewer found it at P6. The drift check's scope predates 0000038, and widening it needs its own design decision.
