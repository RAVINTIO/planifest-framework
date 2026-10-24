---
title: "Scope - token efficiency and Windows shard fix"
summary: "In, out, and deferred work for feature 0000038."
status: "active"
version: "0.1.0"
---
# Scope - token efficiency and Windows shard fix

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000038-token-efficiency-windows-shard
**Wave:** 1
**Version:** 0.36.0

## In Scope

- US-001 (req-001): warm-up plus one timed call in `test-0000032-req-003`, `req-007`, and `req-009`, and their regression copies. The 200 ms limit stays.
- US-002 (req-002): accepted model values in the Claude Code column, the dispatch skeleton, any skill `model:` line, and a new values test.
- US-003 (req-003): `--quiet` in `run-tests.sh` and the refactor, validate, and codegen skill edits.
- US-004 (req-004): Phase 0 and Adoption Modes moved word for word to reference files, with test greps moved and a new absence test.
- US-005 (req-005): an advisory reset prompt after each passed gate.
- US-006 (req-006): a size floor in `custom-002` and the Agent Dispatch Template.
- US-007 (req-007): one partial-read directive in `standard-boot.md`.
- A re-run-setup migration and the 0.36.0 version bump.
- Backlog 0000230 folded in. The design confirmation commit deleted it.

## Out of Scope

- Raising or removing any timing limit.
- Any change to CI output.
- Removing any gate, critic, security review, cross-model review, TDD loop, or test assertion.
- Splitting the ship-agent skill (42,318 bytes). Backlog 0000230 named it as a follow-on to the orchestrator split. This feature doesn't cover it.
- Model-tier mappings for tools other than Claude Code.
- Changing the tier assigned to any task type.

## Deferred

- The one-week usage re-run. It needs a week of sessions after release, so it runs outside this pipeline. Until it runs, the savings in the 0000230 estimate (19.9% to 26.1% from req-002 alone) stay unconfirmed.
- Splitting the ship-agent skill. It is blocked on the orchestrator split landing and the usage re-run showing the remaining context cost. File a backlog entry if the re-run supports it.
