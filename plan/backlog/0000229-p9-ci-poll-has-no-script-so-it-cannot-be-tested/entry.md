---
title: "Backlog Entry: 0000229 - P9 CI poll has no script, so it cannot be tested"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000229 - P9 CI poll has no script, so it cannot be tested

**Source feature:** 0000037-green-ci-before-ship
**Source phase:** P6
**Deferral source:** deliberate scope decision
**Date filed:** 2026-10-24

---

## Problem

ADR-001 keeps the P9 Step 10c poll and the fix-and-push loop as agent instructions. No script runs them. The verify-by-execution report (`plan/current/verification-report.md`) lists the 30-second poll, the 20 and 30 minute windows, the three fix attempts, `gh pr ready --undo`, and the `cancel` bucket as not verifiable here. The req-001 execution check covers the read command and the exit-1-with-JSON case only. The defect in backlog 0000215 (real `gh pr checks` prints no JSON before checks register) was found only because P4 ran the real `gh` CLI.

## Suggested Action

Move the poll into a script such as `planifest-framework/scripts/ci-checks.mjs` with exit codes for pass, red, and unknown. Test it against a stub `gh` for each bucket, the window limits, and the empty-list case. Keep the fix-and-push loop in skill text.

## Why Deferred

ADR-001 chose agent text so the feature needed no new script beyond the credential scan. See `plan/current/recommendations.md` Deferred Items and the P3 Deviation line on the req-001 execution check.
