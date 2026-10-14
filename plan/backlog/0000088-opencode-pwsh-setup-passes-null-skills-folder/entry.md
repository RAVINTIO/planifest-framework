---
title: "Backlog Entry: 0000088 - opencode PowerShell setup passes a null skills folder"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000088 - opencode PowerShell setup passes a null skills folder

**Source feature:** 0000030-context-mode-and-telemetry-mcp-removal
**Source phase:** P3
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-14

---

## Problem

In `setup.ps1`, opencode setup passes a null skills folder to `Join-Path`, which throws. Nobody has run it live on a machine with `pwsh`, so the error stayed hidden. `pwsh` isn't installed where 0000030 was built.

## Suggested Action

Set the opencode skills folder in `setup/opencode.ps1` the same way `setup/opencode.sh` does. Run `setup.ps1 opencode` in CI under `pwsh` to prove it.

## Why Deferred

Agent A found it by static reading during 0000030. It predates that feature and couldn't be checked live.
