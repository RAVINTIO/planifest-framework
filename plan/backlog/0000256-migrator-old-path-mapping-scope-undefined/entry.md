---
title: "Backlog Entry: 0000256 - Migrator old-path mapping scope is undefined"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000256 - Migrator old-path mapping scope is undefined

**Source feature:** 0000039-ravintio-rebrand
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-25

---

## Problem

The 0000039 P5 review (finding L-008) found that `ravintio-framework/skills/ravintio-migrator/SKILL.md`, around lines 65 to 75, maps old pack paths to new ones without saying which text the mapping covers. One older body, `migrate-product-yml-component-paths.md` around line 30, searches the whole project. Under the mapping, an agent could rewrite matches in consumer-owned files as well as pack paths. Each proposed change still needs the human on the loop to confirm it, so nothing changes silently.

## Suggested Action

State that the mapping applies only to paths the migration body names as pack paths, and that it never rewrites consumer-owned text. Add a migrator test for the product-yml body.

## Why Deferred

Out of scope. The fix redesigns the migrator's scope rules, and the human-confirmation step already guards each change.
