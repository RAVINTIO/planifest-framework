---
title: "Backlog Entry: 0000258 - OpenCode old plugin stays registered after upgrade"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000258 - OpenCode old plugin stays registered after upgrade

**Source feature:** 0000039-ravintio-rebrand
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-25

---

## Problem

After a 0.36.0 consumer upgrades, `ravintio-framework/setup/opencode.sh` and `.ps1` install the plugin under `@ravintio`. They leave the old `@planifest` plugin folder and its `opencode.json` registration in place, so OpenCode can load both. The 0000039 P5 fix (S-02) made the old plugin path an enforcement path again, so no agent can write to it, but the stale registration stays.

## Suggested Action

Have the OpenCode setup remove the old registration from `opencode.json`, and move the old plugin folder aside rather than delete it. Add a test.

## Why Deferred

Low after the S-02 fix, and specific to one tool's setup script.
