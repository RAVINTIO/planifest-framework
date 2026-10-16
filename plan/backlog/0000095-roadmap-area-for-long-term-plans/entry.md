---
title: "Backlog Entry: 0000095 - Roadmap area for long-term plans"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000095 - Roadmap area for long-term plans

**Source feature:** 0000032-governance-continuity-and-write-gate-scope (raised by the human on the loop)
**Source phase:** P0
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-16

---

## Problem

`plan/` has no place for long-term plans. `plan/current/` holds one run, `plan/backlog/` holds single deferred items, and `plan/_archive/` holds finished runs. Direction that spans several releases has nowhere to live, so it stays in the human's head or in chat.

## Suggested Action

Add a roadmap area under `plan/`, for example `plan/roadmap/`, with a template for a long-term plan. P0 backlog pickup could read it to suggest which entries fit the current direction.

## Why Deferred

Out of scope for 0000032, which fixes governance gaps in the existing run lifecycle. It needs its own design decision about format and how P0 uses it.
