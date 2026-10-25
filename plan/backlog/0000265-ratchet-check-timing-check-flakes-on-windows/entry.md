---
title: "Backlog Entry: 0000265 - ratchet-check timing check flakes on Windows"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000265 - ratchet-check timing check flakes on Windows

**Source feature:** 0000039-ravintio-rebrand
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-25

---

## Problem

`ravintio-framework/tests/test-0000032-req-007-stderr-block-reasons.sh` asserts that one `ratchet-check` call completes under 200 ms. On `windows-latest`, CI run 40186688263 failed this check in two shards: 242 ms in shard 1 and 203 ms in shard 5. The same check passed in every shard of run 40183688865 an hour earlier. 0000039 doesn't change `ratchet-check`, so the failure comes from runner load, not from the code under test. The regression copy under `tests/regression/` holds the same check.

## Suggested Action

Measure the median of several calls instead of one call, or raise the Windows limit with a stated reason. Keep the check strict enough to catch a real slowdown.

## Why Deferred

Out of scope for 0000039, which leaves `ratchet-check` unchanged. A rerun of the failed shards clears it.
