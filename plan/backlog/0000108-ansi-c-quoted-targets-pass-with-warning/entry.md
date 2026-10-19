---
title: "Backlog Entry: 0000108 - ANSI-C quoted targets pass with only a warning"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000108 - ANSI-C quoted targets pass with only a warning

**Source feature:** 0000032-governance-continuity-and-write-gate-scope
**Source phase:** P5
**Deferral source:** deliberate scope decision
**Source finding:** F10 in the 0000032 P5 security report (`plan/_archive/0000032-governance-continuity-and-write-gate-scope/security-report.md` once archived)
**Severity:** Low
**Priority:** Low
**Date filed:** 2026-10-17

---

## Problem

The shell-write guard reads an ANSI-C quoted target such as `$'src/x.js'` as a variable. It cannot judge a variable, so it warns and passes. Bash treats the same text as a literal path, so the write lands in a gated path.

## Suggested Action

Decode ANSI-C quoting as a literal string before the guard judges the target.

## Why Deferred

At the P5 gate, the human on the loop chose to fix the Medium findings and the cheap Low ones in 0000032. This Low finding went to the backlog. The decision is in the 0000032 build log.
