---
title: "Backlog Entry: 0000231 - split the ship-agent skill by phase"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000231 - split the ship-agent skill by phase

**Source feature:** 0000038-token-efficiency-windows-shard
**Source phase:** P1
**Deferral source:** deliberate scope decision
**Date filed:** 2026-10-24

---

## Problem

`ravintio-framework/skills/ravintio-ship-agent/SKILL.md` is 42,318 bytes. A session loads all of it for P7, P8, and P9, even when it needs only one of them. Backlog 0000230 change 3 named this file as the second split, after the orchestrator. Feature 0000038 split only the orchestrator, and its `scope.md` records the ship-agent split as deferred.

## Suggested Action

Move each phase's steps into reference files that the ship agent loads when it reaches that phase. Keep every rule word for word, and move each test assertion that greps the moved text. Reuse the pattern that 0000038 req-004 sets for the orchestrator.

## Why Deferred

The confirmed 0000038 design scoped US-004 to the orchestrator alone. A second split would add a large text move to a run that already holds seven stories.
