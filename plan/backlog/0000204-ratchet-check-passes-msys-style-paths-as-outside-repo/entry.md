---
title: "Backlog Entry: 0000204 - enforcement hooks treat Git Bash style paths as outside the repository"
summary: "On Windows, a file_path such as /tmp/x/plan/current/a.md resolves to C:\\tmp\\x\\..., outside the project root, so ratchet-check and gate-write pass it."
status: "open"
---
# Backlog Entry: 0000204 - enforcement hooks treat Git Bash style paths as outside the repository

**Source feature:** 0000037-green-ci-before-ship
**Source phase:** P3
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-24

---

## Problem

The first Windows Git Bash CI run (run 40047595064) showed `ratchet-check.mjs` returning exit 0 where the suites expected exit 2. The failing checks were in `test-0000016-pipeline-governance.sh` and `test-0000017-req-002-ratchet-approve.sh`.

P3 traced the cause to the suites. `mktemp -d` under Git Bash gives a `/tmp/...` path. The suites pass that path as `file_path` to a node hook, and node on Windows reads it as `C:\tmp\...`. That folder is outside the fixture root, so the hook applies the rule that paths outside the repository are never gated, and it passes the write. P3 fixed the suites by using `pwd -W` for the fixture root.

This is a test-side cause, and P3 does not claim a hook defect. The residual question is hardening. The hooks cannot tell a Git Bash style path (`/c/...` or `/tmp/...`) from a real outside path. If any tool on Windows hands the hooks such a path for a file inside the project, the write passes ungated. Claude Code on Windows normally gives native paths, so the exposure is unconfirmed.

P3 could not confirm the fix on Windows. If the next CI run still shows `expected 2, actual 0` after the suite change, this entry becomes a confirmed enforcement defect.

## Suggested Action

Check the next Windows CI run. If the ratchet suites pass, decide whether `path-rules.mjs` should translate `/c/...` style paths on `win32`, or whether the exposure is closed. If they still fail, raise a design-defect report for the hooks.

## Why Deferred

P3 does not edit hooks (stream ownership), and the cause found so far sits in the test fixtures. A hook change needs its own design decision.
