---
title: "Backlog Entry: 0000228 - legacy reference lines kept in the ship and docs skills"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000228 - legacy reference lines kept in the ship and docs skills

**Source feature:** 0000037-green-ci-before-ship
**Source phase:** P6
**Deferral source:** tech debt
**Date filed:** 2026-10-24

---

## Problem

Two skills hold superseded text only because older suites assert it.

- The ship skill keeps the old path-list commit lines as labelled interactive and continuous references beside the new `git --literal-pathspecs commit --pathspec-from-file` commands (P5 approach 2 deviation). The P9 marker block does the same.
- The docs-agent skill keeps `Post-P6 revalidation: skipped, no P6 edits`, marked as replaced, because the 0000033 req-014 suite asserts it (P3 deviation).

A reader can mistake a reference line for the live command. Two forms of one rule also invite drift.

## Suggested Action

Move the assertions in the older suites to the new commands and phrase, then delete the reference lines. Run the full suite from three start directories before you merge.

## Why Deferred

Removing the lines means editing suites for earlier features while the P5 fixes were still under review. See the Deviation lines for P3 and P5 in `plan/current/build-log.md` and `plan/current/recommendations.md` row TD-003.
