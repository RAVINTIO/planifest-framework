---
title: "Backlog Entry: 0000076 - P0 asks too many coaching questions"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000076 - P0 asks too many coaching questions

**Source feature:** reported by the human after the `ovelunor` product's `0000016-ads-in-one-switch` run (a downstream consumer of this framework)
**Source phase:** P0
**Deferral source:** process defect
**Date filed:** 2026-10-03

---

## Problem

The orchestrator's P0 asks one question at a time and applies recommend-then-confirm to every decision. That includes adoption mode, version, stack, component split, NFRs, risks, and the feature ID. Most of these are derivable, so each question only restates the recommendation and waits for "yes".

The `ovelunor` product hit this on feature 0000013, whose P0 asked about twelve one-at-a-time confirmations. It added a repo override, `planifest-overrides/instructions/p0-ask-only-real-forks.md`, to stop it. The human still reports too many P0 questions, so the framework default remains the problem for every other product.

The override reads:

> Ask one coaching question only when the answer needs the human's judgement or changes what gets built. Scope, data rules, and anything with a trade-off to weigh are real forks.
>
> Put everything you can derive into the design draft as a recommendation, and let the human confirm it once. Derivable items include an unchanged stack, security, NFR targets, the component split, risks, the version, and the feature ID.

## Suggested Action

- Make the override the framework default in the orchestrator skill's "How you coach" and Phase 0 Start Actions.
- Step 3a (adoption mode) and the version bump should go into the design draft rather than ask a question each, unless a conflict warning applies.
- Keep one combined confirmation for the design, the Scope Lock batch, and the run mode, as `ovelunor` already does in practice.
- Count questions asked at P0 in the build log, so the build report can flag a run that asks too many.

## Why Deferred

Filed from a downstream product's session. The fix belongs in the framework's orchestrator skill.
