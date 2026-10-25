---
title: "Backlog Entry: 0000254 - Quality suite stops silently on its first miss"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000254 - Quality suite stops silently on its first miss

**Source feature:** 0000039-ravintio-rebrand
**Source phase:** P4
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-25

---

## Problem

`ravintio-framework/tests/test-0000010-framework-quality-improvements.sh` counts misses with `((missing_skill++))` under `set -e`. The expression returns 1 when the counter is 0, so the first miss ends the suite with no FAIL line. In 0000039 P4 on Windows CI, two missing `SKILL.md` files made the suite exit after printing `attribution.txt`, with no reason given.

## Suggested Action

Replace each `((x++))` with `x=$((x + 1))`, and add a lint rule that flags `((...++))` in suites that set `-e`.

## Why Deferred

Out of scope. 0000039 renames the pack, and the suite passes once the held-back files move.
