---
title: "Backlog Entry: 0000160 - Ship commit subjects overrun 72 characters"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000160 - Ship commit subjects overrun 72 characters

**Source feature:** 0000035-write-gate-scope-and-path-hardening
**Source phase:** P9
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-22

---

## Problem

The P9 marker step in `planifest-framework/skills/planifest-ship-agent/SKILL.md` commits with the subject `plan(p9): clear session markers for {feature-id}`. With the 43-character ID `0000035-write-gate-scope-and-path-hardening`, the subject is 79 characters. The `commit-msg` hook rejects any subject over 72 characters, so the step's single command sequence failed after it had deleted and staged the markers. The run recovered by committing with a short subject and the feature ID in the body.

Step 7 (`plan(p7): archive {feature-id}`) is close to the limit too. It passes at 61 characters for this ID, but an ID of 55 characters or more would fail.

## Suggested Action

Put `{feature-id}` in the commit body in every ship-skill commit template, as the P8 and Step 10b templates already do. Add a suite check that no template subject in the ship skill holds `{feature-id}`.

## Why Deferred

It changes the ship skill outside this feature's requirements, and the run recovered with a compliant message.
