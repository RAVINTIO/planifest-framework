---
title: "Backlog Entry: 0000092 - Windows PowerShell 5.1 CI coverage"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000092 - Windows PowerShell 5.1 CI coverage

**Source feature:** 0000031-ci-test-and-powershell-coverage
**Source phase:** P6
**Deferral source:** deliberate scope decision
**Date filed:** 2026-10-16

---

## Problem

CI runs `test_setup.ps1` under PowerShell 7 only. Windows PowerShell 5.1 ships with Windows, and `setup.ps1` already guards one 5.1 behaviour (a comment near line 709). No test runs `setup.ps1` under 5.1.

## Suggested Action

First decide whether 5.1 is a supported runtime. If it is, add a `shell: powershell` leg to the `setup-powershell` job and update `docs/architecture-overview.md`.

## Why Deferred

See 0000031 `scope.md` and ADR-001. The documented runtime is PowerShell 7+.
