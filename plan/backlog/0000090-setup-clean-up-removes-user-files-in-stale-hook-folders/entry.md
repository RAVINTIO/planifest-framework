---
title: "Backlog Entry: 0000090 - setup clean-up removes user files in stale hook folders"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000090 - setup clean-up removes user files in stale hook folders

**Source feature:** 0000030-context-mode-and-telemetry-mcp-removal
**Source phase:** P5 (finding F6)
**Deferral source:** deliberate scope decision
**Date filed:** 2026-10-14

---

## Problem

The 0.29.0 setup clean-up (0000030-ADR-004) deletes each tool's whole `hooks/telemetry/` and `hooks/context-mode/` folder. It also removes any settings entry whose command runs a file in those folders. If a person put their own hook file in one of those folders, setup removes both the file and its entry.

The pass also removes hook groups by matcher alone when the matcher is `mcp__structured-telemetry-mcp__emit_event`. That departs from ADR-004's rule of matching on command path. It is harmless, because that MCP server no longer exists.

The path match is case-sensitive, so it misses mixed-case Windows paths. It also misses commands that `cd` into the hooks folder first.

## Suggested Action

Delete only the file names Planifest shipped in those folders, then remove each folder only if it is empty. Remove settings entries only when they run one of those shipped file names.

## Why Deferred

The P5 security review rated it Low. The folders are Planifest-owned install locations, and setup prints every removal. The human on the loop asked for a continuous run, so this is recorded rather than redesigned mid-run.
