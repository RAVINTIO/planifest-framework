---
title: "Backlog Entry: 0000199 - CI checkout fetches no release tags"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000199 - CI checkout fetches no release tags

**Source feature:** 0000037-green-ci-before-ship
**Source phase:** P1
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-24

---

## Problem

The `test-suite` job in `.github/workflows/ravintio.yml` uses `actions/checkout@v4` with its defaults. That fetches one commit and no tags. The migration branch-diff test (req-008 of 0000037) needs the previous release tag. It skips when the tag is absent, so it never compares anything in CI. A wrong migration file list then fails only on a local run.

## Suggested Action

Add `fetch-depth: 0` (or `fetch-tags: true` with enough depth) to the checkout step of the `test-suite` job. Confirm the job stays inside its 10-minute limit.

## Why Deferred

0000037 keeps the skip so shallow clones pass, as 0000186 asks. Changing the checkout is a workflow change outside the stream that owns the test.
