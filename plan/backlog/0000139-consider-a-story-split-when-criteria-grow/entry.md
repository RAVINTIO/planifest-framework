---
title: "Backlog Entry: 0000139 - Consider a story split when criteria grow"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000139 - Consider a story split when criteria grow

**Source feature:** 0000035-write-gate-scope-and-path-hardening
**Source phase:** P2
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-22

---

## Problem

In 0000035, a P1 critic-loop fix agent added three acceptance criteria to `req-002-product-yml-in-p7.md`, which took it to six. The orchestrator then planned to fold them into sub-bullets to meet the count. Nobody asked whether req-002 held two concerns. It did: the P7 `product.yml` update and the Hard Limit 8 sanctioned-scripts rule. The human on the loop had to ask for the split.

The rule to split above 3 criteria appears only in `planifest-framework/templates/feature-brief.template.md`. These places carry no such step:
- the spec agent skill
- the design critic skill
- the loop runner fix dispatch
- the orchestrator's dispatch template

`consistency-check.mjs` now warns from 4 to 10 criteria, but no skill says what to do with the warning.

## Suggested Action

Add a standing step wherever criteria are added or the warning fires. The step asks whether the requirement holds more than one concern. If it does, split it into a new requirement and story before adding criteria or folding them. Put the step in the spec agent, the design critic rubric, and the loop runner's fix dispatch. Add a suite check that each skill carries it.

## Why Deferred

It changes several framework skills outside this feature's scope. In 0000035, the human on the loop asked for the split by hand.
