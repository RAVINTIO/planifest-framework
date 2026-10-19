---
title: "Backlog Entry: 0000106 - a dangling symbolic link in plan/ writes into a gated path"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000106 - a dangling symbolic link in plan/ writes into a gated path

**Source feature:** 0000032-governance-continuity-and-write-gate-scope
**Source phase:** P5
**Deferral source:** deliberate scope decision
**Source finding:** F6 in the 0000032 P5 security report (`plan/_archive/0000032-governance-continuity-and-write-gate-scope/security-report.md` once archived)
**Severity:** Low
**Priority:** Low
**Date filed:** 2026-10-17

---

## Problem

`gate-write` permits any path under `plan/`. If a symbolic link in `plan/` points at a file that does not exist yet, the target can sit in a gated path such as `src/`. A write to the link creates that file, and the gate never sees the real target. The gate before 0000032 had the same gap.

## Suggested Action

Follow link targets with `lstatSync` and `readlink`, with a hop limit, and judge the final target rather than the link path.

## Why Deferred

At the P5 gate, the human on the loop chose to fix the Medium findings and the cheap Low ones in 0000032. This Low finding went to the backlog. The decision is in the 0000032 build log.
