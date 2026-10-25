---
title: "Backlog Entry: 0000262 - PowerShell halves skip locally without pwsh"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000262 - PowerShell halves skip locally without pwsh

> Path: `plan/backlog/0000262-powershell-halves-skip-locally-without-pwsh/entry.md`

**Source feature:** 0000039-ravintio-rebrand
**Source phase:** P6
**Deferral source:** tech debt
**Date filed:** 2026-10-25

---

## Problem

The PowerShell halves of the req-002 and req-006 suites skip when `pwsh` isn't on `PATH`. In feature 0000039, `pwsh` was installed at `/opt/homebrew/bin/pwsh`, but several subagent shells lacked that folder on `PATH`. Their suite runs skipped the PowerShell cases and reported `pwsh` as missing. Only the CI legs proved those cases, which cost a CI round trip. The `.ps1` helper failed on every runner because PowerShell turned `$null` into an empty backup path for `File.Replace`. No local run could show it.

## Suggested Action

Document `pwsh` as a local test prerequisite, or add a container recipe that runs the PowerShell legs. Have `run-tests.sh` print a visible skipped count when it skips them.

## Why Deferred

It is a tooling gap that predates feature 0000039. The feature's own cost is the cycle 3 record in `plan/current/build-log.md`, and the fix needs its own design decision on how to install `pwsh`.
