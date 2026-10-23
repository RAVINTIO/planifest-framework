---
title: "Backlog Entry: 0000191 - Ship and GUTD ignore red CI"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000191 - Ship and GUTD ignore red CI

**Source feature:** 0000036-pipeline-friction-and-gate-fixes
**Source phase:** P9
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-23

---

## Problem

PR #62 merged with a failing `Test suite (ubuntu-latest)` check, and no agent reported it. Three things let the failure through:

- The ship agent raises the PR at P9 and reports done. It never waits for the PR's CI checks or reads their result.
- The GUTD routine pulls `main` and lists untracked files. It never checks the CI status of the latest `main` commit, so a red `main` looked healthy.
- The local suite runs on macOS only. BSD and GNU tools differ, so a portability defect surfaces only in CI.

The defect itself was in `test-0000036-req-005-hard-limits-cited-by-name.sh`. It called `grep -rnE` on one file. GNU grep drops the file name for a single file operand, and BSD grep keeps it. The Fast Path fix on `feat/fix-req005-gnu-grep-filename` adds `-H`.

## Suggested Action

- At P9, after `gh pr create`, run `gh pr checks --watch`. If a check fails, report it, fix it on the feature branch, and push before the final report.
- In GUTD, run `gh run list --branch main --limit 1` after the pull. If the run failed, report the failing job and offer to fix it.
- Consider a lint for unportable tool use in suites, such as `grep -r` without `-H`, or a Linux run of the suite before ship.

## Why Deferred

The CI check belongs in the ship skill and the GUTD instruction, and each change needs its own design decision. The Fast Path fix covers only the failing suite.
