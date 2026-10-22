---
title: "Backlog Entry: 0000179 - an always-permitted .gitattributes can hide enforcement diffs"
summary: "The gate permits .gitattributes anywhere outside the enforcement list, so an agent can mark hook files -diff or linguist-generated and hide their changes from review."
status: "open"
---
# Backlog Entry: 0000179 - an always-permitted .gitattributes can hide enforcement diffs

**Source feature:** 0000036-pipeline-friction-and-gate-fixes
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-23

---

## Problem

`ALWAYS_PERMITTED_FILES` in `planifest-framework/hooks/enforcement/path-rules.mjs` holds `.gitattributes`. The gate admits that name with no design in any folder outside `FAST_PATH_ENFORCEMENT_PATHS`, including the repository root and `planifest-framework/`.

A line such as `planifest-framework/hooks/** -diff linguist-generated` makes `git diff` print `Binary files ... differ` for a hook change. GitHub also collapses generated files by default. An agent with a design that covers the hooks could land a hook change that the human on the loop doesn't read. The `.gitattributes` change still shows in the diff, which limits the risk.

The gap predates 0000036. See finding 6 in `plan/current/security-review-hooks.md` (0000036 P5).

## Suggested Action

Route `.gitattributes` through the normal design route when it sits in the root or in a folder above an enforcement path. Another option is to add the root `.gitattributes` to `FAST_PATH_ENFORCEMENT_PATHS`.

## Why Deferred

It changes the always-permitted list outside enforcement paths, which 0000036 req-009 keeps unchanged. It needs its own design decision.
