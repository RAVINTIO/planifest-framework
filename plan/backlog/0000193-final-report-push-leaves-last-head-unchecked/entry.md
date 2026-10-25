---
title: "Backlog Entry: 0000193 - final report push leaves the last head unchecked"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000193 - final report push leaves the last head unchecked

**Source feature:** 0000037-green-ci-before-ship
**Source phase:** P1
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-24

---

## Problem

P9 Step 11 commits `{archive-dir}/final-report.md` and pushes it after the PR exists. That push starts a new `pull_request` run on the PR head. The CI check in Step 10c reads the earlier head, and the final report records that result. The last head of the PR therefore ships with no CI result read. See `ravintio-framework/skills/ravintio-ship-agent/SKILL.md` Steps 10c and 11.

## Suggested Action

Read the checks of the final head after the Step 11 push, and report a mismatch with the recorded result in the chat message. Or commit the final report before the Step 10c wait.

## Why Deferred

The 0000037 design reads checks once after Step 10b. Moving the final report changes the Step 11 and Step 12 order, which needs its own design decision.
