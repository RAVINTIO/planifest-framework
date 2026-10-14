---
title: "Backlog Entry: 0000087 - setup all stops before later tools"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000087 - setup all stops before later tools

**Source feature:** 0000030-context-mode-and-telemetry-mcp-removal
**Source phase:** P3
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-14

---

## Problem

`setup.sh all` stops at roo-code. The roo-code tool config runs `exit 0` while `setup.sh` sources it, so the whole script ends there. Tools after it in the loop, including opencode, never install.

The `TOOL_*` variables that each sourced config sets also carry over from one tool to the next under `all`. A later tool can inherit a value it never set.

## Suggested Action

Replace `exit 0` in sourced tool configs with `return 0`, or run each tool in a subshell. Reset every `TOOL_*` variable before sourcing the next config. Add a test that runs `setup.sh all` and checks the last tool installed.

## Why Deferred

Agent A found it while editing the setup scripts for 0000030. It predates that feature and isn't part of the Context Mode and Telemetry removal.
