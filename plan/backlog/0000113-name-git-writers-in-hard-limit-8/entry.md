---
title: "Backlog Entry: 0000113 - name git writers in boot-file Hard Limit 8"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000113 - name git writers in boot-file Hard Limit 8

**Source feature:** 0000032-governance-continuity-and-write-gate-scope
**Source phase:** P5
**Deferral source:** deliberate scope decision
**Source finding:** M-1 in the 0000032 P5 security report (`plan/_archive/0000032-governance-continuity-and-write-gate-scope/security-report.md` once archived)
**Severity:** Low
**Priority:** Low
**Date filed:** 2026-10-17

---

## Problem

The boot file lists the commands the shell-write guard passes, including git commands. Hard Limit 8 does not say that some of those git commands also write code. An agent can read the list as permission to change `src/` through git.

## Suggested Action

Name `git checkout`, `git restore`, `git apply`, and `git stash` in Hard Limit 8 of both boot templates as commands that also write code.

## Why Deferred

At the P5 gate, the human on the loop chose to fix the Medium findings and the cheap Low ones in 0000032. This Low finding went to the backlog. The decision is in the 0000032 build log.
