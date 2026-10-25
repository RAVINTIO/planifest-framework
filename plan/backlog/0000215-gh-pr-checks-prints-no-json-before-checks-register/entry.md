---
title: "Backlog Entry: 0000215 - gh pr checks prints no JSON before checks register"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "closed"
---
# Backlog Entry: 0000215 - gh pr checks prints no JSON before checks register

**Source feature:** 0000037-green-ci-before-ship
**Source phase:** P4
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-24

---

## Resolution

Closed in 0000037 P4, self-correct cycle 2. The gap sat in this feature's own req-001 and req-002, so the orchestrator fixed it in the same run. Ship Step 10c reads `no checks reported` on stderr as an empty list and keeps polling. GUTD step 5 reports "no checks reported" for that PR. The req-001 and req-002 suites assert both. A future P0 discards this entry at pickup.

## Problem

Step 10c in `ravintio-framework/skills/ravintio-ship-agent/SKILL.md` assumes that `gh pr checks {n} --json name,bucket,link` prints an empty JSON list while no checks exist. Verify-by-execution showed otherwise.

For PR #30 (no checks), the command prints nothing on stdout, writes `no checks reported on the 'feat/planifest-framework-v0.7' branch` to stderr, and exits 1.

Step 10c says output that is not valid JSON reads as "CI status could not be read". A fresh PR whose jobs have not registered yet would therefore read as unreadable on the first poll. It would not wait and reread, and the "empty list reads unknown, no checks reported" branch never runs.

The same applies to `ravintio-overrides/instructions/custom-003-git-up-to-date-shorthand.md` step 5 for a merged PR with no checks. A check never reads as a pass in either case, so the risk is a premature `P9 blocked`, not a false green.

## Suggested Action

Treat empty stdout with the stderr text `no checks reported` as the empty-list case in Step 10c and GUTD step 5. Keep polling in Step 10c, and report "unknown: no checks reported" at the end of the window.

## Why Deferred

The behaviour is safe (it never reads as a pass) and the fix needs a decision on how Step 10c separates this case from a real `gh` failure. It also needs a change to the shell tests over both texts.
