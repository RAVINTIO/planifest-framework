---
title: "Backlog Entry: 0000275 - shell guard timing check flakes on Windows"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000275 - shell guard timing check flakes on Windows

**Source feature:** 0000039-ravintio-rebrand
**Source phase:** P9
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-25

---

## Problem

`ravintio-framework/tests/test-0000032-req-009-shell-guard-path-parity.sh` asserts `req-009: F7 a 20,000-segment target returns within 2 seconds`. On `windows-latest`, CI run 40198983603 failed this check in shard 3 of 7. 0000039 doesn't change the shell guard, and the same check passed in earlier runs on the same branch. So the failure comes from runner load, not from the code under test. Backlog 0000265 records the same kind of flake for the `ratchet-check` 200 ms check.

## Suggested Action

Treat both timing checks the same way. Measure the median of several runs, or raise the Windows limit with a stated reason, and keep the check strict enough to catch a real slowdown. Consider picking this up with 0000265.

## Why Deferred

Out of scope for 0000039, which leaves the shell guard unchanged. A rerun of the failed shard clears it.
