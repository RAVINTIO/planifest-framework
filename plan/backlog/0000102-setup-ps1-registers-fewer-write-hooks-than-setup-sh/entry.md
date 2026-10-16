---
title: "Backlog Entry: 0000102 - setup.ps1 registers fewer Write and Edit hooks than setup.sh"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000102 - setup.ps1 registers fewer Write and Edit hooks than setup.sh

**Source feature:** 0000032-governance-continuity-and-write-gate-scope
**Source phase:** P1
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-17

---

## Problem

For Claude Code, `setup.sh` registers three hooks on **Write** and **Edit**: `gate-write.mjs`, `ratchet-check.mjs`, and `em-dash-guard.mjs`. `setup.ps1` (`Merge-EnforcementHookSettings`) registers only `gate-write.mjs`. A project set up on Windows therefore gets no ratchet check and no em-dash guard.

## Suggested Action

Make `setup.ps1` register the same Write and Edit hooks as `setup.sh`, and add a parity assertion to `tests/test_setup.ps1`.

## Why Deferred

The gap predates 0000032. 0000032 only adds the Bash shell-write guard to both scripts.
