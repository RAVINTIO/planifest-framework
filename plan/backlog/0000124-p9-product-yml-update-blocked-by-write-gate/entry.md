---
title: "Backlog Entry: 0000124 - P9 can't update product.yml after the design is archived"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000124 - P9 can't update product.yml after the design is archived

**Source feature:** 0000033-human-on-the-loop-run-mode
**Source phase:** P9 (Step 9, create git tag)
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-19

---

## Problem

Ship Step 9 tells the agent to update the top-level `version` and `feature` fields in `product.yml`. By then, P7 Step 6 has moved `plan/current/design.md` into the archive. The `gate-write` hook then blocks the **Edit** with "No confirmed design at plan/current/design.md". The `shell-write-guard` hook blocks a shell write to the same path.

In 0000033, `product.yml` therefore stayed at `0.30.0` while the tag was `v0.32.0`. It was already stale at 0000032, which suggests every run since the archive script hits the same block. Under `versionPolicy: max-component-version` the field is informational, so the tag stays correct. Under `versionPolicy: explicit` the field is authoritative, and the block would stop a correct release.

## Suggested Action

Move the `product.yml` update into P7, before Step 6 archives the design, and commit it with the archive. Or let `gate-write` permit `product.yml` at the repo root, as it permits `plan/` and `docs/`. Add a suite that runs the close-out order and checks that `product.yml` matches the tag. In the same change, set `product.yml` to the current release.

## Why Deferred

0000033 found the problem at P9, after the code phases had closed. The tag reads its version from `component.yml`, so the release itself was unaffected.
