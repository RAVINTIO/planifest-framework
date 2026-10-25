---
title: "Backlog Entry: 0000264 - setup.ps1 tests need TEMP on macOS"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000264 - setup.ps1 tests need TEMP on macOS

**Source feature:** 0000039-ravintio-rebrand
**Source phase:** P3
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-25

---

## Problem

`ravintio-framework/tests/test_setup.ps1` line 7 builds its workspace from `$env:TEMP`. PowerShell on macOS and Linux sets no `TEMP` variable, so `Join-Path` gets a null path and the suite stops at line 7. The suite passes on macOS only when you run it with `TEMP="$TMPDIR"`. CI runs it on Windows, where `TEMP` is set, so CI doesn't show the problem.

## Suggested Action

Use `[System.IO.Path]::GetTempPath()` in place of `$env:TEMP`. It works on Windows PowerShell 5.1 and PowerShell 7 on every platform.

## Why Deferred

Out of scope for 0000039. The req-002 implementer found it while running the suite locally, and the fault predates this feature.
