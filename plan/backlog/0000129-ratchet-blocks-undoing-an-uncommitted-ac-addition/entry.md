---
title: "Backlog Entry: 0000129 - Ratchet blocks undoing an uncommitted AC addition"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000129 - Ratchet blocks undoing an uncommitted AC addition

**Source feature:** 0000035-write-gate-scope-and-path-hardening
**Source phase:** P1 (design-critic loop, approach 2)
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-22

---

## Problem

`ratchet-check.mjs` compares a proposed write with the file on disk. It blocks the removal of any `- [ ]` line in an `## Acceptance Criteria` section while a loop is active. It doesn't check whether the line exists in the last commit.

In 0000035, a P1 fix agent added three acceptance criteria to `req-002-product-yml-in-p7.md`, which took it to six. `consistency-check.mjs` allows at most three. The agent then tried to fold the three new lines into sub-bullets of the existing criteria, and the ratchet blocked it. Undoing a line that no commit ever held needed a `.ratchet-approve` line from the human on the loop. The `autonomous` run stopped for it.

## Suggested Action

Compare against `HEAD` as well as the disk. If a removed line is absent from the committed file, treat its removal as undoing an uncommitted addition and let it pass. Reading `HEAD` without a spawn can reuse the git-state reader that 0000035 adds to `path-rules.mjs`. Add a suite case for both paths.

## Why Deferred

It changes an enforcement hook outside this feature's scope. The run recovered through the human approval path.
