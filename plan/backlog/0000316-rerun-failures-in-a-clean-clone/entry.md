---
title: "Backlog Entry: 0000316 - run the P4 suite in a clean clone of HEAD"
summary: "At P4 Validate, run the suite in a fresh clone before self-correcting, and record the OS and toolchain as evidence."
status: "open"
---
# Backlog Entry: 0000316 - run the P4 suite in a clean clone of HEAD

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Change Pipeline
**Related:** 0000262

---

## Context

A review of RAVINTIO Zero on 2026-10-31 found failures that existed only in a working tree. CI runs the suite in a fresh checkout. A local run that differs from CI gives evidence that nobody can reproduce.

## Problem

- `skills/ravintio-validate-agent/` runs the suite in the working tree. It has no clean-clone step.
- Untracked files, ignored caches, and OS differences can change a local result. A local run can pass where CI fails, or fail where CI passes.
- Zero backlog 0000296 (`zero/plan/backlog/0000296-p3-clean-clone-suite/entry.md`) cites seven records of such failures.
- In Zero's retrospective for 0000253, a clean clone separated ignored run state from real failures (`zero/plan/retrospectives/0000253-refresh-setup-2026-10-29.md` lines 20 and 25).
- Zero builds 0000037, 0000160, 0000198, and 0000239 lost CI rounds to Bash 3.2 and BSD tool differences between macOS and the Linux CI runner.

## Suggested Action

- At P4 Validate, clone `HEAD` into a temporary folder and run the suite there before any self-correction.
- Record the local OS and toolchain versions in the build log as evidence.
- Compare the local OS with the CI OS from the workflow file, and name any gap in the build log.
- Remove the temporary clone when the run ends.
- Add a plan-time check at P1 or P2 that flags shell code that needs Bash 4 or GNU-only tool flags.

## Wanted outcome

P4's result matches CI for committed code. Tests check these conditions:

- The validate skill runs the suite in a clean clone of `HEAD`.
- An untracked file the suite needs makes P4 fail.
- The build log records the OS and toolchain versions, and names any gap with CI.

## Why Deferred

The human asked for it on 2026-10-31 after the Zero comparison review. It changes P4 Validate and adds a plan-time check.
