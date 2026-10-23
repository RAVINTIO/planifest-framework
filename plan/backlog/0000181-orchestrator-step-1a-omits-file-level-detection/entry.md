---
title: "Backlog Entry: 0000181 - orchestrator step 1a omits file-level update detection"
summary: "Step 1a's summary of the detection signal checks only version strings, but the policy says detection keys on changed framework files."
status: "open"
---
# Backlog Entry: 0000181 - orchestrator step 1a omits file-level update detection

**Source feature:** 0000036-pipeline-friction-and-gate-fixes
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-23

---

## Problem

Step 1a in `planifest-framework/skills/planifest-orchestrator/SKILL.md` describes two signals. Both compare version strings:

- a mismatch with the recorded `component.yml` version
- framework files that declare a newer version

`planifest-framework/standards/framework-update-policy.md` lists the same two signals. A later paragraph then says detection keys on new or changed files under `planifest-framework/`, not on the version string alone. The two texts disagree, and step 1a's inline summary gives only the narrower reading.

The gap matters more since 0000036 changed step 1b. Step 1b now loads source skill copies when step 1a "found no framework update". Suppose a push changes `planifest-framework/skills/*/SKILL.md` without a version bump. An agent that follows step 1a's summary finds no update. The drift check then reports those skills as stale, and step 1b loads the unconfirmed source copies for the session.

The re-review fixture can't reproduce this, because the behaviour lives in skill text. The finding comes from reading step 1a and step 1b against the policy.

## Suggested Action

Make the policy's detection signal list include changed framework files as its own signal, and make step 1a say the same. Also, consider making step 1b treat a `stale:` result with an unchanged version as a candidate update for step 1a.

## Why Deferred

Step 1a and the policy text predate 0000036. Fixing the detection signal needs its own design decision about what counts as a changed file, and since when.
