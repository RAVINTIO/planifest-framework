---
title: "Backlog Entry: 0000259 - Prune parity on a linked skills folder, and a req-008 test that needs the repo"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000259 - Prune parity on a linked skills folder, and a req-008 test that needs the repo

**Source feature:** 0000039-ravintio-rebrand
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-25

---

## Problem

The 0000039 P5 re-review found two Low items:

- **N-01:** if the tool's skills folder is itself a symbolic link, `setup.sh` prunes old skill folders inside the link's target, but `setup.ps1` skips the prune. The two shells disagree.
- `test-0000039-req-008-emitted-names.sh` AC3 reads the workflow name from the repo above the pack, so the suite fails in any copy of the pack without that workflow.

## Suggested Action

Pick one rule for a linked skills folder, apply it in both shells, and test it. Point the req-008 check at the pack's own `hooks/ravintio.yml`, or skip it with a reason when the repo workflow is absent.

## Why Deferred

Both are Low and don't affect a normal consumer install or this repo's CI.
