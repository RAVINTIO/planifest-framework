---
title: "Backlog Entry: 0000109 - ratchet-check.mjs uses process.cwd()"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000109 - ratchet-check.mjs uses process.cwd()

**Source feature:** 0000032-governance-continuity-and-write-gate-scope
**Source phase:** P5
**Deferral source:** deliberate scope decision
**Source finding:** F12 in the 0000032 P5 security report (`plan/_archive/0000032-governance-continuity-and-write-gate-scope/security-report.md` once archived)
**Severity:** Low
**Priority:** Low
**Date filed:** 2026-10-17

---

## Problem

`ratchet-check.mjs` finds `plan/current/` from `process.cwd()`. If the working directory is a subfolder of the project, the hook finds no loop state and does not check anything. A write that weakens acceptance criteria then passes during an active loop. This predates 0000032.

## Suggested Action

Use `resolveRoot` and `toRootRelative` from `path-rules.mjs`, as `gate-write` and the shell-write guard already do.

## Why Deferred

At the P5 gate, the human on the loop chose to fix the Medium findings and the cheap Low ones in 0000032. This Low finding went to the backlog. The decision is in the 0000032 build log.
