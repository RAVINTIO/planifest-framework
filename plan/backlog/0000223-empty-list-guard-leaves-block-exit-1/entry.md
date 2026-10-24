---
title: "Backlog Entry: 0000223 - empty-list guard leaves a block's exit code at 1"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000223 - empty-list guard leaves a block's exit code at 1

**Source feature:** 0000037-green-ci-before-ship
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-24

---

## Problem

Each scan-then-commit commit line in `planifest-framework/skills/planifest-ship-agent/SKILL.md` and `planifest-framework/standards/autonomous-run-standards.md` starts with `[ -s "{out-file}" ] &&`. When the safe list is empty, the test fails and the line exits 1. Where that line ends a block (the P8 leftover commit, the P9 CI record, the P9 final report, and step 6 of the standard), the whole block then exits 1.

Nothing aborts and nothing leaks. `bash -e` ignores a failed `&&` list, as re-review 6 confirmed (`plan/_archive/` copy of `security-rereview-6.md`, finding N-17). A tool that treats any non-zero exit as a failure could still misread a correct skip.

## Suggested Action

Write each guard as `if [ -s "{out-file}" ]; then git --literal-pathspecs commit ...; fi`, so an empty list exits 0. Update the guard assertion in `test-0000037-req-003-archive-held-back.sh` to match.

## Why Deferred

Re-review 6 rated it Low and approved the P5 gate. Fixing it in 0000037 would reopen the review loop for a cosmetic exit code.
