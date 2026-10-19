---
title: "Backlog Entry: 0000110 - setup Bash group edge cases"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000110 - setup Bash group edge cases

**Source feature:** 0000032-governance-continuity-and-write-gate-scope
**Source phase:** P5
**Deferral source:** deliberate scope decision
**Source finding:** S-1 and S-2 in the 0000032 P5 security report (`plan/_archive/0000032-governance-continuity-and-write-gate-scope/security-report.md` once archived)
**Severity:** Low
**Priority:** Low
**Date filed:** 2026-10-17

---

## Problem

Two edge cases affect how `setup.sh` and `setup.ps1` merge the Bash hook group in Claude Code settings.

- S-1: Setup drops a whole Bash group if any hook in it is the shell-write guard. A hook the human on the loop added to that group is lost.
- S-2: Setup never removes a guard entry under a combined matcher such as `Bash|Write`. Each re-run then adds a duplicate guard.

## Suggested Action

Remove only the guard entry, and drop the group only when it is empty. Match any matcher that contains `Bash` when looking for an existing guard entry.

## Why Deferred

At the P5 gate, the human on the loop chose to fix the Medium findings and the cheap Low ones in 0000032. This Low finding went to the backlog. The decision is in the 0000032 build log.
