---
title: "Backlog Entry: 0000112 - the post-P9 refusal of new work is instruction only"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000112 - the post-P9 refusal of new work is instruction only

**Source feature:** 0000032-governance-continuity-and-write-gate-scope
**Source phase:** P5
**Deferral source:** deliberate scope decision
**Source finding:** K-5 in the 0000032 P5 security report (`plan/_archive/0000032-governance-continuity-and-write-gate-scope/security-report.md` once archived)
**Severity:** Low
**Priority:** Low
**Date filed:** 2026-10-17

---

## Problem

After P9, the skills tell the agent to refuse new work until a new P0 starts. No hook enforces this. `gate-write` still blocks code paths once `design.md` is archived, but an agent that ignores the instruction can still change other files.

## Suggested Action

The P5 review accepted this as residual risk. If it causes a problem, add a hook that blocks writes outside `plan/` while the post-P9 sentinel is present.

## Why Deferred

At the P5 gate, the human on the loop chose to fix the Medium findings and the cheap Low ones in 0000032. This Low finding went to the backlog. The decision is in the 0000032 build log.
