---
title: "Backlog Entry: 0000116 - shell guard misses cd variants"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000116 - shell guard misses cd variants

**Source feature:** 0000032-governance-continuity-and-write-gate-scope
**Source phase:** P5
**Deferral source:** deliberate scope decision
**Source finding:** pre-existing cd gaps noted in the 0000032 P5 re-review (`plan/_archive/0000032-governance-continuity-and-write-gate-scope/build-log.md` once archived)
**Severity:** Low
**Priority:** Low
**Date filed:** 2026-10-17

---

## Problem

`shell-write-guard.mjs` tracks a plain `cd` to resolve later relative writes. It doesn't track other forms that change the directory. These pass with no block and no warning:

- `pushd ../src/other && touch x.js`
- `builtin cd ../src/other && touch x.js`
- `command cd ../src/other && touch x.js`
- `CDPATH=.. cd src/other && touch x.js`

These forms pass with a warning only:

- `cd -P ../src/other`
- `cd -L ../src/other`
- `cd "$PWD/..."`

## Suggested Action

Treat `pushd`, `builtin cd`, and `command cd` as `cd`. Treat `-P` and `-L` as flags, not as the target. Mark the base directory unknown when `CDPATH` is set.

## Why Deferred

At P5 gate decision 2, the human on the loop chose to fix the Medium re-review findings and N-3 and N-8 in 0000032. These gaps predate 0000032, so they went to the backlog. The decision is in the 0000032 build log.
