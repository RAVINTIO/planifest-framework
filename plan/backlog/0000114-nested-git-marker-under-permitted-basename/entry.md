---
title: "Backlog Entry: 0000114 - nested .git marker under a permitted basename"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000114 - nested .git marker under a permitted basename

**Source feature:** 0000032-governance-continuity-and-write-gate-scope
**Source phase:** P5
**Deferral source:** deliberate scope decision
**Source finding:** N-6 in the 0000032 P5 re-review (`plan/_archive/0000032-governance-continuity-and-write-gate-scope/build-log.md` once archived)
**Severity:** Low
**Priority:** Low
**Date filed:** 2026-10-17

---

## Problem

`path-rules.mjs` takes a folder that holds `.git` as a repository root marker. Take a repo with `.git` but no `planifest-framework/`, and with `CLAUDE_PROJECT_DIR` unset. In that repo, these commands plant a new root marker:

```bash
mkdir -p plan/w/.git && mv plan/w src/claude.md
```

The gate allows the move, because `claude.md` is an always-permitted basename. `src/claude.md` then reads as its own repository root. A write from `src/claude.md` to `../other/x.js` passes the write gate.

## Suggested Action

Ignore a root marker if its path below a higher marked folder holds an always-permitted basename segment. Otherwise ignore nested `.git` folders below a marked root.

## Why Deferred

At P5 gate decision 2, the human on the loop chose to fix the Medium re-review findings and N-3 and N-8 in 0000032. This Low finding went to the backlog. The decision is in the 0000032 build log.
