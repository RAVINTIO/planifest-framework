---
title: "Backlog Entry: 0000089 - test-0000010 depends on the working directory"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000089 - test-0000010 depends on the working directory

**Source feature:** 0000030-context-mode-and-telemetry-mcp-removal
**Source phase:** P3
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-14

---

## Problem

`planifest-framework/tests/test-0000010-framework-quality-improvements.sh` passes only when you run it from the repository root. If you start `run-tests.sh` from inside `planifest-framework/tests/`, it fails. It behaves the same on `main`.

## Suggested Action

Resolve paths from the script's own location, as `run-tests.sh` does with `SCRIPT_DIR`, rather than from the current directory.

## Why Deferred

Two 0000030 agents found it while running tests. It predates that feature.
