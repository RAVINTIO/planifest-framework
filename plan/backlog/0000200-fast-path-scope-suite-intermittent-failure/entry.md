---
title: "Backlog Entry: 0000200 - fast-path scope suite fails intermittently"
summary: "test-0000035-req-001-fast-path-scope-record.sh failed once from /tmp and passed on rerun. P3 could not reproduce it or name the failing assertion."
status: "open"
---
# Backlog Entry: 0000200 - fast-path scope suite fails intermittently

**Source feature:** 0000037-green-ci-before-ship
**Source phase:** P3
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-24

---

## Problem

`ravintio-framework/tests/test-0000035-req-001-fast-path-scope-record.sh` failed once in the req-009 baseline run from `/tmp` (outside the repository). It passed on rerun with 171 passed and 0 failed.

P3 diagnosed it under req-009 (FR-009.2) and could not reproduce it. The suite ran 22 times from `/tmp` with no failure: 6 and 16 in parallel, and 3 more under 12 busy node processes. The suite has no path that depends on the working directory. It builds `FRAMEWORK` from `$SCRIPT_DIR` and keeps every fixture under `mktemp -d`.

The one timing-dependent code is two wall-clock assertions at lines 320 and 325. Each requires a hook call with 10,000 packed refs to finish in under 500 ms. A slow node start on a loaded machine could fail either. This is a hypothesis. No run showed it. The cause is therefore not a working-directory dependence, and P3 changed nothing in the suite.

## Suggested Action

Capture the failing assertion name the next time the suite fails (rerun with the output saved). If it is a 500 ms assertion, widen the bound or measure the hook's own time rather than the process start. If it is another assertion, diagnose from the saved output.

## Why Deferred

P3 has no failing output to act on. A change to a timing bound without evidence would guess at the cause.
