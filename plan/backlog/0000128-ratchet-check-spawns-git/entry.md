---
title: "Backlog Entry: 0000128 - ratchet-check spawns git from a hook"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000128 - ratchet-check spawns git from a hook

**Source feature:** 0000035-write-gate-scope-and-path-hardening
**Source phase:** P1
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-22

---

## Problem

`ravintio-framework/hooks/enforcement/ratchet-check.mjs` calls `execFileSync("git", ["status", "--porcelain", ...])` in `isUncommitted`. That call backs the uncommitted-marker check from 0000017 ADR-001. Feature 0000035 states an NFR of Node built-ins only and no process spawn in hooks. 0000032 ADR-004 sets the same rule for `path-rules.mjs`.

In 0000035, req-005 makes `ratchet-check.mjs` import `path-rules.mjs` but leaves the spawn in place. The suite source check for the no-spawn rule therefore can't cover `ratchet-check.mjs`. A slow or missing `git` also adds its own delay to every guarded write.

## Suggested Action

Decide whether the no-spawn rule covers every enforcement hook. If it does, replace the `git status` call with a file read. One option compares the marker's content with its blob in the index or `HEAD`, through the git-file reader that 0000035 req-001 adds. Then extend the source check to `ratchet-check.mjs`.

## Why Deferred

The backstop belongs to 0000017 ADR-001, and changing it needs its own design decision. 0000035 changes only how `ratchet-check.mjs` finds the root and the target path.
