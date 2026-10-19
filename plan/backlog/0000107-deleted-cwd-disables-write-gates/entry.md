---
title: "Backlog Entry: 0000107 - a deleted cwd disables both write gates"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000107 - a deleted cwd disables both write gates

**Source feature:** 0000032-governance-continuity-and-write-gate-scope
**Source phase:** P5
**Deferral source:** deliberate scope decision
**Source finding:** F9 in the 0000032 P5 security report (`plan/_archive/0000032-governance-continuity-and-write-gate-scope/security-report.md` once archived)
**Severity:** Low
**Priority:** Low
**Date filed:** 2026-10-17

---

## Problem

If the working directory no longer exists, the root lookup in `path-rules.mjs` fails. Both `gate-write` and the shell-write guard then fail open, so neither gate blocks a write into `src/`.

## Suggested Action

Resolve the root from the nearest existing parent of the working directory, or from `CLAUDE_PROJECT_DIR` when it is set.

## Why Deferred

At the P5 gate, the human on the loop chose to fix the Medium findings and the cheap Low ones in 0000032. This Low finding went to the backlog. The decision is in the 0000032 build log.
