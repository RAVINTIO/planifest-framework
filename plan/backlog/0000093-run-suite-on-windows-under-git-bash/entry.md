---
title: "Backlog Entry: 0000093 - Run the suite on Windows under Git Bash"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000093 - Run the suite on Windows under Git Bash

**Source feature:** 0000031-ci-test-and-powershell-coverage
**Source phase:** P6
**Deferral source:** deliberate scope decision
**Date filed:** 2026-10-16

---

## Problem

`run-tests.sh` runs on Linux and macOS in CI, but not on Windows. Windows users of `setup.sh` under Git Bash have no CI coverage. Some suites rely on POSIX tools and `mktemp` behaviour that differ under Git Bash (see Q-005 in `src/setup-hook-integration/docs/quirks.md`).

## Suggested Action

Add `windows-latest` with `shell: bash` to the `test-suite` matrix, then fix or skip the suites that fail there.

## Why Deferred

See 0000031 `scope.md` and ADR-001.
