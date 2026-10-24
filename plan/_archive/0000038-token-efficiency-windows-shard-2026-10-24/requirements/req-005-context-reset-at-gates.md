---
title: "Requirement: req-005 - context reset at gates"
summary: "After each passed phase gate, the orchestrator recommends a compact or a new session."
status: "active"
version: "0.1.0"
---
# Requirement: req-005 - context reset at gates

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000038-token-efficiency-windows-shard
**Source:** US-005
**Priority:** should-have

## User Story

As the human on the loop, I get a reset prompt after each passed gate, so that long sessions stop growing.

## Functional Requirements
- The Context Hygiene section of `planifest-framework/skills/planifest-orchestrator/SKILL.md` (heading at line 229, advisory compaction at line 235) gains a prompt after each passed phase gate. It recommends `/compact` or a new session.
- The prompt names `plan/current/` and the build log as the resume state. It works when no `pause.md` exists.
- The prompt is advisory and never blocks a phase. In `continuous` and `autonomous` runs, the run carries on and doesn't wait for an answer.
- The blocking reset after P9, which feature 0000032 set, doesn't change.

## Acceptance Criteria
- [ ] After each passed phase gate, Context Hygiene recommends `/compact` or a new session and names `plan/current/` and the build log as the resume state. Verified by: unit
- [ ] The prompt text never requires `pause.md`, and it states that it is advisory and doesn't block a phase. Verified by: unit
- [ ] The blocking after-P9 reset text, which feature 0000032 set, is unchanged, and the tests that pin it still pass. Verified by: unit

## Dependencies
- The blocking reset after P9, which feature 0000032 set.
- req-004 moves Phase 0 text in the same file. The two edits touch different sections.

Split step: keep. One section edit gives one outcome, a reset prompt at each gate.
