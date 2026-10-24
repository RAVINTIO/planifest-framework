---
title: "Backlog Entry: 0000221 - shard list not checked against real suites"
summary: "No check proves the CI shard count and shard list cover every real suite."
status: "open"
---
# Backlog Entry: 0000221 - shard list not checked against real suites

**Source feature:** 0000037-green-ci-before-ship
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-24

---

## Problem

The Windows leg runs seven shards. A text test counts seven shard entries in `.github/workflows/planifest.yml` and the literal `7`. Nothing proves the shards cover every real suite. After F-01 a shard that selects zero suites fails, but a drifted count that still gives each shard one suite would pass. The test file is `planifest-framework/tests/test-0000037-req-010-windows-git-bash-leg.sh`.

## Suggested Action

Add a check that reads the shard count from the workflow, counts the real suites (feature plus regression), and asserts that every position maps to exactly one shard index.

## Why Deferred

The security review F-01 fix covers the fail-closed parser. A coverage check needs its own design decision on how to read the count from the workflow without a YAML library.
