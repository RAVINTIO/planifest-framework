---
title: "Backlog Entry: 0000103 - release sizing and a configurable release budget"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000103 - release sizing and a configurable release budget

**Source feature:** `planifest-zero` 0000037-self-host-on-planifest-zero
**Source phase:** P0
**Deferral source:** discovered mid-flight
**Moved:** copied from `planifest-zero` backlog entry 0000109 on 2026-10-17, at the human's request
**Date filed:** 2026-10-17

---

## Problem

The orchestrator sizes a release with one fixed rule of thumb: more than 3 user stories is too big. No setting lets a repo say how much work a release should hold. So P0 sizes each run conservatively, and the human must push for more scope by hand. In 0000037, the first plan held 3 stories, and four small backlog items stayed out until the human asked.

The rule also counts stories, not effort. Four one-line fixes and one new pipeline concept score the same.

## Suggested Action

1. Add a release-size setting, for example in `product.yml` or `planifest-overrides/`. It could hold a target and a ceiling in user stories or requirements, or a size class such as small, medium, or large.
2. At P0, size each candidate requirement, for example by files touched or by a size class.
3. Fill the release from the backlog up to the configured budget. Recommend the fill, and keep the human's confirm step.
4. Replace the fixed 3-story rule in the orchestrator and the plan skill with the setting. When no setting exists, keep a default.

## Why Deferred

The change needs its own design decision about where the setting lives and how P0 measures size. It touches the orchestrator and plan skills in `planifest-framework/`. It fits with the pipeline-governance group in 0000095 to 0000098.
