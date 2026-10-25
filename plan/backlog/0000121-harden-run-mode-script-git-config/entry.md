---
title: "Backlog Entry: 0000121 - Harden run-mode.mjs against user and repo git config"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000121 - Harden run-mode.mjs against user and repo git config

**Source feature:** 0000033-human-on-the-loop-run-mode
**Source phase:** P5 (verification of security cycle 3)
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-19

---

## Problem

`ravintio-framework/scripts/run-mode.mjs` decides whether a run is `autonomous` from git history. It ignores textconv, external diff, replace refs, and inherited `GIT_*` variables, and it blocks system git config. User and repo config still load. These paths are untested: `core.fsmonitor`, `includeIf`, an alternate object store (`objects/info/alternates`), grafts (`info/grafts`), and a shallow file. Each would need deliberate, multi-step tampering. The script's header already says it is an integrity check, not a security boundary, and the hard limits never depend on the run mode. The P5 verifier rated it Low.

## Suggested Action

Set `GIT_CONFIG_GLOBAL=/dev/null` and pass `-c core.fsmonitor=false` on every git call. Print `interactive` when `.git/shallow`, `.git/info/grafts`, or `.git/objects/info/alternates` exists. Add a fixture for each case.

## Why Deferred

The 0000033 P5 loop reached its cap of 3 fix cycles. Only Low and Info findings remained, so the gate passed and this item moved to the backlog.
