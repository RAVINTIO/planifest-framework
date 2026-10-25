---
title: "Backlog Entry: 0000130 - No check ties setup wiring files to the Fast Path enforcement list"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000130 - No check ties setup wiring files to the Fast Path enforcement list

**Source feature:** 0000035-write-gate-scope-and-path-hardening
**Source phase:** P2
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-22

---

## Problem

In 0000035, req-001 adds `FAST_PATH_ENFORCEMENT_PATHS` to `ravintio-framework/hooks/enforcement/path-rules.mjs`. It lists the hook wiring files that `setup.sh` and `setup.ps1` write, such as `.claude/settings.json` and `.windsurf/hooks.json`. The req-001 suite checks the constant against the `ravintio-framework/workflows/fast-path.md` prerequisites only.

Nothing checks the constant against the paths the setup scripts write. The per-tool scripts under `ravintio-framework/setup/` set those paths. If a later change adds a supported tool or moves a wiring file, the constant can miss it. A Fast Path scope record could then list the new wiring file and unwire `gate-write`.

0000035 ADR 004 records this gap as a risk.

## Suggested Action

Add a suite that collects every wiring file path the setup scripts write and asserts each one matches `FAST_PATH_ENFORCEMENT_PATHS`. One option is to run setup into a fixture and compare the written files with the constant.

## Why Deferred

The 0000035 scope covers the enforcement list and its parity with `fast-path.md`, not setup behaviour. A setup-level check needs its own design for how to enumerate wiring files across every tool.
