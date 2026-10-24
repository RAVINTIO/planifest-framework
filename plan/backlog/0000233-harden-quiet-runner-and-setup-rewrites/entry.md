---
title: "Backlog Entry: 0000233 - harden the quiet runner and setup rewrites"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000233 - harden the quiet runner and setup rewrites

**Source feature:** 0000038-token-efficiency-windows-shard
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-24

---

## Problem

The 0000038 security review rated the feature Low and raised two hardening items. See `plan/_archive/0000038-token-efficiency-windows-shard-*/security-report.md`, findings L1 and L5.

- **L1:** `planifest-framework/tests/run-tests.sh --quiet` traps only `INT` and `TERM`. A `HUP` can leave a mode-0600 capture file in the temp folder and an orphaned suite process. `KILL` can't be trapped at all.
- **L5:** the link rewrites in `setup.sh` and `setup.ps1` fail silently. In `setup.ps1`, a missing destination file ends up as an empty file. The `SKILL.md` rewrite had the same gap before 0000038.

## Suggested Action

Add `HUP` to the quiet-mode trap. Make each setup rewrite report a failure, and skip a destination file that doesn't exist.

## Why Deferred

Both items are Low. Neither lets a failed suite read as passed or weakens a gate. The `setup.sh` part predates 0000038.
