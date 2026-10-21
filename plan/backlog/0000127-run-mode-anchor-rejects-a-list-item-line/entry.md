---
title: "Backlog Entry: 0000127 - Run-mode anchor rejects a list-item confirmation line"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000127 - Run-mode anchor rejects a list-item confirmation line

**Source feature:** 0000035-write-gate-scope-and-path-hardening
**Source phase:** P0 (design confirmation)
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-22

---

## Problem

`planifest-framework/scripts/run-mode.mjs` anchors `autonomous` only on a build-log line that starts with `Run mode confirmed: autonomous`. The orchestrator skill tells P0 to "append" that line to the P0 build-log block. Every other P0 audit-trail entry in that block is a list item, so the natural form is `- Run mode confirmed: autonomous (...)`. The script ignores that form and prints `interactive`.

In 0000035, the confirmation commit `38541a5` used the list-item form. Fixing it needed a second commit that adds a bare line and re-states the design Confirmation line. A force push to amend the first commit would breach a standing rule. Nothing in the skill or the template warns about the format.

## Suggested Action

Either have the script accept an optional `- ` list prefix, or have the orchestrator skill and the build-log template show the exact bare line in a code block. Add a suite case for the list-item form. Also have P0 run `run-mode.mjs` before pushing the confirmation commit, so a bad anchor shows before it reaches the remote.

## Why Deferred

It changes `run-mode.mjs`, an integrity check outside this feature's write-gate scope. The run recovered with one extra commit.
