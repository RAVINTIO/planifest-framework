---
title: "Backlog Entry: 0000236 - orchestrator split follow-ups"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000236 - orchestrator split follow-ups

**Source feature:** 0000038-token-efficiency-windows-shard
**Source phase:** P6
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-24

---

## Problem

The 0000038 cross-model review approved on iteration 3 with four minor findings. See `plan/_archive/0000038-token-efficiency-windows-shard-*/cross-model-review-iteration-3.md`.

- **m-1:** the instruction to fill the build-log Summary table at P7 now sits only in `skills/planifest-orchestrator/references/phase-0-assess-and-coach.md` (step 2 of Phase 0 Start Actions). The ship agent doesn't state it. The template heading in `templates/build-log.template.md` still prompts it.
- **m-2:** `standards/agent-dispatch-standards.md` points to the backlog ID rule at its old place in the orchestrator `SKILL.md`. That rule now lives in the Phase 0 reference file.
- **m-3:** the `SKILL.md` pointer section writes `Gate accepted: P{N}` without the `({ISO-8601 timestamp})` that the moved text gives.
- **m-4:** the pointer section is 983 bytes against the 650-byte budget in 0000038 ADR-002, and the ADR text wasn't updated. `SKILL.md` has 109 bytes spare under 41,500.

## Suggested Action

State the P7 Summary rule in the ship agent. Point the dispatch standard at the Phase 0 reference file. Add the timestamp to the pointer line. Record the pointer's real size where the next feature that edits `SKILL.md` will see it.

## Why Deferred

All four are minor and none blocks. Each fix after the approving review would reopen the review loop.
