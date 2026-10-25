---
title: "Backlog Entry: 0000222 - scan output path glob chars stall unstage"
summary: "The credential scan prints unusual path characters as ? so the unstage step can fail and stall."
status: "open"
---
# Backlog Entry: 0000222 - scan output path glob chars stall unstage

**Source feature:** 0000037-green-ci-before-ship
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-24

---

## Problem

`ravintio-framework/scripts/credential-scan.mjs` replaces unusual path characters with `?` when it prints a `{path}:{line} {rule}` line. A non-ASCII name such as `plan/current/é.txt` prints as `plan/current/?.txt`. Scan-then-commit (`ravintio-framework/standards/autonomous-run-standards.md`) tells the run to pass that printed path to `git restore --staged --`. Git reads `?` as a one-byte glob. A two-byte UTF-8 character does not match, so the restore fails with `did not match` and the scan exits 1 on every rescan. A path with a colon prints as `a?b.txt`, which also breaks the `{path}:{line}` split. The failure is closed, since nothing commits, but the run stalls with no cap on the repeat step.

## Suggested Action

Have the unstage step read paths from `git diff --cached --name-only -z` and match them to the scan's sanitised names, or have the script print an unsanitised path in a `-z` mode. Add a repeat cap to step 3 of Scan-then-commit that stops under exception item 7.

## Why Deferred

The case needs a held-back file with a non-ASCII or colon name. It fails closed and leaks nothing. The fix touches the scan script's output contract, which needs its own design decision.
