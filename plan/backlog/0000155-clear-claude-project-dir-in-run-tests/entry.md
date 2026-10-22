---
title: "Backlog Entry: 0000155 - Clear CLAUDE_PROJECT_DIR in run-tests"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000155 - Clear CLAUDE_PROJECT_DIR in run-tests

**Source feature:** 0000035-write-gate-scope-and-path-hardening
**Source phase:** P6
**Deferral source:** tech debt
**Date filed:** 2026-10-22

---

## Problem

`resolveRoot` in `planifest-framework/hooks/enforcement/path-rules.mjs` reads `CLAUDE_PROJECT_DIR` first. A suite run inside a Claude Code session inherits that variable. The hooks under test then find the real repo as the root, not the fixture.

At least 20 suites and regression copies now carry their own `unset CLAUDE_PROJECT_DIR` line. Examples are `test-0000016-pipeline-governance.sh` and `test-0000017-req-002-ratchet-approve.sh`. `planifest-framework/tests/run-tests.sh` doesn't clear it. CI doesn't set the variable, so a new suite that forgets the line passes on CI and fails locally.

## Suggested Action

Unset `CLAUDE_PROJECT_DIR` once in `run-tests.sh` before it starts any suite. Keep the per-suite line only where a suite runs on its own, or add a shared test helper.

## Why Deferred

See TD-011 in the 0000035 `recommendations.md`. The P3 deviation in the 0000035 `build-log.md` added the per-suite lines, which sat outside the req-005 file list.
