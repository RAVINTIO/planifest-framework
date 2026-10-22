---
title: "Backlog Entry: 0000186 - req-001 suite lacks a branch-diff check"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000186 - req-001 suite lacks a branch-diff check

**Source feature:** 0000036-pipeline-friction-and-gate-fixes
**Source phase:** P6
**Deferral source:** tech debt
**Date filed:** 2026-10-23

---

## Problem

`planifest-framework/tests/test-0000036-req-001-rerun-setup-migration.sh` checks only `path-rules.mjs` and `standard-boot.md` in the migration's Background. It does not compare the file list in `planifest-framework/migrations/migrate-0.34.0-rerun-setup.md` with the files the release changes. At P4, verify by execution found that the list missed six changed skills and named four unchanged files, and the suite still passed. The orchestrator fixed the list by hand in `16df927`.

## Suggested Action

Add a check that runs `git diff --name-only` against the previous release tag and compares the setup-delivered files in the result with the migration's list. Skip the check when the tag is absent, so CI clones without it still pass.

## Why Deferred

The P4 decision in the build log left the check out because CI clones may lack a `main` ref. The end-of-P6 recheck covers the list for this release. A tag-based check needs its own design.
