---
title: "Backlog Entry: 0000157 - Hard Limit 8 names two rules"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000157 - Hard Limit 8 names two rules

**Source feature:** 0000035-write-gate-scope-and-path-hardening
**Source phase:** P6
**Deferral source:** tech debt
**Date filed:** 2026-10-22

---

## Problem

Two framework files number different rules as Hard Limit 8:

- `planifest-framework/templates/standard-boot.md` line 14: code changes go through **Write** or **Edit**, with the sanctioned-scripts sentence.
- `planifest-framework/skills/planifest-orchestrator/SKILL.md` line 27: write a build-log entry at every phase start and gate.

The orchestrator skill also calls a missing build-log block "a pipeline error (Hard Limit 8)" at lines 328 and 567. 0000035 req-008 and its dispatch prompts cite Hard Limit 8 for the file-write rule. An agent that reads only the orchestrator skill reads the other rule.

`planifest-framework/standards/agent-dispatch-standards.md` doesn't state the file-write rule. In 0000035 P1, a fix agent changed four shared artifacts through a Python script. Every later dispatch prompt had to restate the rule by hand.

## Suggested Action

Give each rule its own number across the boot templates and the orchestrator skill, or cite each by name. Add the file-write rule to the agent dispatch template.

## Why Deferred

See TD-013 and REC-008 in the 0000035 `recommendations.md`. Renumbering the Hard Limits touches every skill that cites one, which is outside the 0000035 scope.
