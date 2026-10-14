---
title: "Backlog Entry: 0000091 - CI runs no tests and no PowerShell"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000091 - CI runs no tests and no PowerShell

**Source feature:** 0000030-context-mode-and-telemetry-mcp-removal
**Source phase:** P4
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-14

---

## Problem

`.github/workflows/planifest.yml` runs two checks: code/doc parity and `self-description-check.mjs`. It never runs `planifest-framework/tests/run-tests.sh`, and it never runs `setup.ps1` under `pwsh`. A pull request can break the suite and still pass CI.

PowerShell setup is the larger gap. The machine that built 0000030 has no `pwsh`, so its `setup.ps1` changes have static checks only. The P5 review found a PowerShell-only defect (F2) by reading the code.

## Suggested Action

Add a CI job that runs `bash planifest-framework/tests/run-tests.sh` on Linux and macOS. Add a Windows job that runs `setup.ps1` against a fixture project under PowerShell 7 and Windows PowerShell 5.1.

## Why Deferred

Changing CI coverage is outside the removal feature. 0000030 assumed CI could exercise `setup.ps1` (assumption A-002), and P4 showed that assumption was false.
