---
title: "Backlog Entry: 0000115 - cp and mv target option prefixes pass"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000115 - cp and mv target option prefixes pass

**Source feature:** 0000032-governance-continuity-and-write-gate-scope
**Source phase:** P5
**Deferral source:** deliberate scope decision
**Source finding:** N-7 in the 0000032 P5 re-review (`plan/_archive/0000032-governance-continuity-and-write-gate-scope/build-log.md` once archived)
**Severity:** Low
**Priority:** Low
**Date filed:** 2026-10-17

---

## Problem

GNU `cp` and `mv` accept any unambiguous prefix of a long option. `shell-write-guard.mjs` matches only the full `--target-directory` name, so a shorter prefix hides the destination. These commands write into a gated path without a block:

- `cp --target=src/other plan/a`
- `cp --target-dir=src/other plan/a`
- `mv --targ src/other plan/a`

## Suggested Action

Treat any unambiguous prefix of `--target-directory` as that option, in both the `--opt=value` and `--opt value` forms.

## Why Deferred

At P5 gate decision 2, the human on the loop chose to fix the Medium re-review findings and N-3 and N-8 in 0000032. This Low finding went to the backlog. The decision is in the 0000032 build log.
