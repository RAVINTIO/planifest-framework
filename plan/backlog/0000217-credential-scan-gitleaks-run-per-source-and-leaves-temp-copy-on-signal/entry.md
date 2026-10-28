---
title: "Backlog Entry: 0000217 - credential scan runs gitleaks once per source and can leave a temp copy"
summary: "gitleaksHits starts one gitleaks process per source, a signal skips the temp-directory cleanup, and a gitleaks usage error reads as a finding."
status: "open"
---
# Backlog Entry: 0000217 - credential scan runs gitleaks once per source and can leave a temp copy

**Source feature:** 0000037-green-ci-before-ship
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-24

---

## Problem

`gitleaksHits` in `ravintio-framework/scripts/credential-scan.mjs` copies each source into a `mkdtempSync` directory and starts one `gitleaks` process for it. Three behaviours follow. A large commit pays one process start per file. A signal skips the `finally` cleanup and leaves a copy of staged content in the temp directory. A `gitleaks` usage error exits 1 and reads as a finding at line 1. The credentials review (F-13) notes these and the branch was not run against a real `gitleaks`.

## Suggested Action

Copy all sources into one temp directory and run `gitleaks` once. Register a signal handler that removes the directory. Separate usage errors from findings by reading the report file.

## Positioning note (2026-10-26)

The 0000279 differentiation review keeps this entry, folded into 0000281. When an external scanner becomes the main path, the gitleaks call is the integration. Fix the per-source runs and the temp-copy cleanup there, as part of reading the scanner's report as evidence.

## Why Deferred

The behaviour fails closed and needs a real `gitleaks` in CI to test. It is outside the P5 fixes for feature 0000037.
