---
title: "Backlog Entry: 0000094 - Live PowerShell test for stale clean-up and retired flags"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000094 - Live PowerShell test for stale clean-up and retired flags

**Source feature:** 0000031-ci-test-and-powershell-coverage
**Source phase:** P6
**Deferral source:** tech debt
**Date filed:** 2026-10-16

---

## Problem

The Windows CI job runs `setup.ps1` on a fresh install only. The 0000030 clean-up of stale settings entries and the retired-flag notices never run under PowerShell. Source-text assertions in `test-0000030-req-004-install-clean-up-and-retired-flags.sh` are their only check (Q-013).

## Suggested Action

Extend `test_setup.ps1` to seed a stale settings entry and a stale hook folder, run setup with one retired flag, and assert the clean-up and the notice.

## Why Deferred

See 0000031 `recommendations.md` TD-001 and `src/setup-hook-integration/docs/tech-debt.md` TD-010.
