---
title: "Backlog Entry: 0000261 - Remove the old-name reads at 1.0.0"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000261 - Remove the old-name reads at 1.0.0

> Path: `plan/backlog/0000261-remove-old-name-reads-at-1-0-0/entry.md`

**Source feature:** 0000039-ravintio-rebrand
**Source phase:** P6
**Deferral source:** deliberate scope decision
**Date filed:** 2026-10-25

---

## Problem

ADR-004 of feature 0000039 keeps these old-name reads through every 0.x release. Version 1.0.0 removes them. Each read has brand guard allowlist entries in `ravintio-framework/tests/test-0000039-req-007-brand-guard.sh`.

- The old session ID variable (req-003). The OpenCode adapter reads it only when `RAVINTIO_SESSION_ID` is unset.
- The old boot-file block markers (req-002). Setup replaces each block with the RAVINTIO form.
- The old ignore-file headers (req-002). Setup replaces them the same way.
- The old setup flags marker file (req-002). Setup and refresh-setup read it once, write the new marker, and remove it.
- The old manifest marker file (req-002). Setup and refresh-setup read it once to prune old skill copies, then remove it.
- The old em-dash guard sentinel (req-008). The guard accepts it beside the new sentinel.

The exact names are in `plan/current/adr/ADR-004-old-name-reads.md` while that file is current, and in the archive after P7.

A consumer that skips the 0.x window and upgrades straight to 1.0.0 would meet markers setup no longer recognises. The 1.0.0 release notes must name this.

## Suggested Action

Remove each read and its tests. Remove the matching allowlist entries and confirm the stale-entry check passes. Add a migration or release note for consumers still on 0.36.0 or earlier.

## Why Deferred

The 0.x window is a deliberate scope decision. See ADR-003 and ADR-004 of feature 0000039, and the Deferred section of its `scope.md`.
