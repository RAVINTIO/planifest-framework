---
title: "Backlog Entry: 0000225 - shell guard passes shell writes to plan/ and git stash"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000225 - shell guard passes shell writes to plan/ and git stash

**Source feature:** 0000037-green-ci-before-ship
**Source phase:** P6
**Deferral source:** tech debt
**Date filed:** 2026-10-24

---

## Problem

Subagents broke the Write-or-Edit rule (boot Hard Limit 8) five times in 0000037. The orchestrator ran `sed -i` at P2. A P5 fix agent ran `printf >>`. A second fix agent ran `git stash push` and `pop`. A third ran `sed -i` on `test-0000037-req-003-archive-held-back.sh`. A P3 worker tried a `python3` heredoc, and the permission check stopped it.

`shell-write-guard.mjs` blocks a writer only when `gate-write` would block the same path. Writes under `plan/` and to suites under `ravintio-framework/tests/` are always permitted, so the guard passes them. The guard also treats git commands as pass-through. The rule text in the dispatch template did not prevent any of the five breaches.

## Suggested Action

Add a report-only mode to `shell-write-guard.mjs` that warns, in every session, on `sed -i`, `perl -pi`, `>>`, `tee`, and `git stash` against a tracked file. Review the warning rate for one feature, then decide whether to block. Add a documented way to prove RED without `git stash`, such as running the suite against a copy in a temporary folder, to `ravintio-test-writer`. Pair this with 0000105 (wrappers) and 0000189 (citation forms).

## Why Deferred

The 0000037 scope covers CI and credential checks, and it does not touch the write guard. See `plan/current/recommendations.md` row REC-001 and the build-log rule-breach lines for P2 and P5.
