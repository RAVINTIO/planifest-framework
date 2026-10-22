---
title: "Backlog Entry: 0000140 - hook branch tests past the acceptance criteria"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000140 - hook branch tests past the acceptance criteria

**Source feature:** 0000035-write-gate-scope-and-path-hardening
**Source phase:** P4
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-22

---

## Problem

The P4 semantic check for 0000035 found every acceptance criterion and Input Validation line covered. It also found functional-requirement branches that run in the code but have no test of their own. Each one works when read, but no suite would catch a regression.

- `path-rules.mjs` scope record (req-001):
  - a relative `gitdir:` line in a `.git` file
  - the 200-character cut in the admit notice
  - matching a record against the real target of a link
  - the once-per-root scope cache
  - a reftable ref store
- `resolveTarget` (req-003):
  - an `EACCES` or `EIO` error during resolution inside the root
  - a link from outside the root into a loop inside it (`err.reached`)
  - the `toRootRelative` contract
  - `relPath` keeping its original case
- `resolveRoot` (req-004):
  - an `EACCES` stop with the target outside the `CLAUDE_PROJECT_DIR` root
  - a `CLAUDE_PROJECT_DIR` with no marker
  - a deleted cwd under a linked ancestor
  - a runtime `ENOTDIR` stop
- `ratchet-check.mjs` (req-005):
  - the `process.cwd()` and `CLAUDE_PROJECT_DIR` fallbacks
  - a `null` root
  - the `build-log.md` and `ratchet-log.md` exemptions from a subfolder
  - the uncommitted-approval backstop from a subfolder
  - an upper-case path after normalisation
- `markedRoot` (req-006):
  - the shell guard on the `.git` file and `CLAUDE_PROJECT_DIR` cases
  - a trusted marker between a planted one and the outer root
  - `ratchet-check.mjs` from a planted cwd
  - a bare `child_process` import, which the `node:child_process` grep misses
- Skills and scripts (req-002, req-007, and req-008):
  - each FR-007.3 unreadable-record condition in the orchestrator step 1 text
  - `setup.sh` and `setup.ps1` never reading `_done/`
  - ship Step 10b never editing `product.yml`
  - `max-component-version` derived from the new `components[]` list
  - `set-product-release.mjs` validating before it reads `product.yml`
- `scopeVerdict` (req-009):
  - the enforcement check running before the stale-record check
  - `.github/hooks/` entries other than `planifest.json`
  - `planifest-framework/setup/windsurf.sh`

The `resolveRoot` doc comment also says it returns `null` when `realpathSync` throws. req-004 says it returns `null` only for a cwd that is not a non-empty string. The code fails open, which matches the wider rule, but the two texts disagree.

## Suggested Action

Add one assertion per branch to the matching `test-0000035-req-NNN-*.sh` suite. Reconcile the `resolveRoot` wording in req-004 or the doc comment.

## Why Deferred

P4 closes gaps against the acceptance criteria and must not widen scope. These branches sit below the criteria, and each needs its own fixture.
