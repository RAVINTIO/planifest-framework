---
title: "Backlog Entry: 0000218 - workflow jobs lack permissions, tag-pinned actions, and inline base_ref"
summary: "Two workflow jobs inherit the default token scope, actions/checkout floats on @v4, and base_ref is expanded inside run scripts, in both the repository and consumer copies."
status: "open"
---
# Backlog Entry: 0000218 - workflow jobs lack permissions, tag-pinned actions, and inline base_ref

**Source feature:** 0000037-green-ci-before-ship
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-24

---

## Problem

Three hardening gaps sit in `.github/workflows/planifest.yml` and in the consumer copy at `planifest-framework/hooks/planifest.yml`.

- The `validate-branch` job (line 8) and the `self-description-check` job (line 52) set no `permissions:` block. They take the repository default token scope. The newer jobs set `permissions: contents: read`.
- `actions/checkout@v4` is pinned to a moving tag on every checkout (lines 11, 55, 94, 110, 136).
- `validate-branch` expands `${{ github.base_ref }}` inside the `run` script (lines 17 and 18). The `pull_request` trigger limits it to `main` and `master` today, so it is not exploitable. A wider `branches:` filter would make it an injection point.

## Suggested Action

Add a top-level `permissions: contents: read`. Pin `actions/checkout` to a commit SHA with the tag in a comment. Pass `github.base_ref` through `env:` and use `"$BASE_REF"` in the script. Apply all three to the consumer copy as well.

## Why Deferred

The lines pre-date feature 0000037, and the consumer copy is out of its scope (R-014). The change needs the human on the loop to decide on the consumer workflow.
