---
title: "Backlog Entry: 0000213 - duration-weighted Windows shards"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000213 - duration-weighted Windows shards

**Source feature:** 0000037-green-ci-before-ship
**Source phase:** P3
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-24

---

## Problem

`run-tests.sh` shards by position: a suite runs in shard `(position - 1) % count + 1`. On `windows-latest` under Git Bash, four setup-heavy suites dominate the run time:

- `test-0000030-req-004-install-clean-up-and-retired-flags.sh` takes about 600 seconds.
- `test-0000027-req-002-cline-path-collision.sh` takes about 170 seconds.
- `test-0000025-req-004-setup-config-relocation.sh` takes about 140 seconds.
- `test-0000020-req-008-install-time-marker-write.sh` takes about 110 seconds.

With four shards, all four landed in shard 2, which hit its 20-minute cap on PR #64. Seven shards separate them today. A new suite shifts every later position, so the split can regroup them without warning.

## Suggested Action

Assign shards by measured duration, for example from a small committed weights file with greedy balancing. Or move the slowest suites to a named shard of their own. A check could also warn when one shard's known weight passes a threshold.

## Why Deferred

Feature 0000037 needed a green Windows leg now. Seven positional shards achieve that. Balanced sharding is a separate design choice with its own trade-offs.
