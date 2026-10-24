---
title: "Requirement: req-006 - decomposition size floor"
summary: "Subagents are for units that need their own reads. Small units run as parallel tool calls."
status: "active"
version: "0.1.0"
---
# Requirement: req-006 - decomposition size floor

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000038-token-efficiency-windows-shard
**Source:** US-006
**Priority:** should-have

## User Story

As an agent, I dispatch a subagent only for work that needs its own reads, so that small units don't pay a fresh context.

## Functional Requirements
- `planifest-overrides/instructions/custom-002-prefer-subagent-decomposition.md` adds a size floor. Dispatch a subagent only when the unit needs its own reads or many tool calls.
- The same file says to run small independent units as parallel tool calls in the main thread.
- The Agent Dispatch Template in `planifest-framework/standards/agent-dispatch-standards.md` carries the same floor.
- The parallel critics and the Scope Lock drafts stay as they are.
- The floor exempts every fresh-context role dispatch, by name: the design critic, security review, cross-model review, reversal assessor, test-writer, implementer, refactor, verify-by-execution, and the Scope Lock drafts.
- The floor never removes a maker-checker split or a TDD step. A role that needs a fresh context runs in a subagent whatever the unit size.
- `setup.sh` (`append_override_instructions`, lines 248 to 298) strips and re-appends every file in `planifest-overrides/instructions/` into the generated boot file, `CLAUDE.md` for Claude Code, between sentinel markers. A setup re-run therefore refreshes the generated copy of custom-002. The copy stays stale until that re-run, so the migration covers it.
- The existing escape clause stays. An agent that doesn't split states the reason.

## Acceptance Criteria
- [ ] `custom-002-prefer-subagent-decomposition.md` states the floor and the main-thread alternative for small independent units. Verified by: unit
- [ ] The Agent Dispatch Template in `agent-dispatch-standards.md` states the same floor. Verified by: unit
- [ ] The parallel critic and the four Scope Lock draft dispatches are unchanged, and the tests that pin them still pass. Verified by: unit
- [ ] Extends the third criterion. Both `custom-002-prefer-subagent-decomposition.md` and the Agent Dispatch Template name each exempt role (design critic, security review, cross-model review, reversal assessor, test-writer, implementer, refactor, verify-by-execution, Scope Lock drafts) and state that the floor never removes a maker-checker split or a TDD step. Verified by: unit

## Dependencies
- custom-002 sits outside the `planifest-framework` component. The change reaches installs through the override sync.
- req-002 edits the same standard file, in the tier table and skeleton.

Split step: keep. The override and the template carry one rule, so they form one outcome.
