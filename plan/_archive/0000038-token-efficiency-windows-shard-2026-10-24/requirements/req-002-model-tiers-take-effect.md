---
title: "Requirement: req-002 - model tiers take effect"
summary: "Subagent dispatch passes only model values the Claude Code Agent tool accepts."
status: "active"
version: "0.1.0"
---
# Requirement: req-002 - model tiers take effect

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000038-token-efficiency-windows-shard
**Source:** US-002
**Priority:** must-have

## User Story

As the human on the loop, I see subagents run on the tier the framework names, so that cheap work stops running on Opus.

## Functional Requirements
- The Claude Code column of the tier-to-model table in `planifest-framework/standards/agent-dispatch-standards.md` (line 35) uses only `sonnet`, `opus`, `haiku`, or `fable`.
- The dispatch skeleton in the same file (lines 124 and 127) passes `model: "haiku"` in place of `model: "claude-haiku-4-5"`.
- Any other Claude Code dispatch example that names a full model id changes to an accepted value. Known cases are `planifest-framework/skills/planifest-ship-agent/SKILL.md` line 186 and the Claude Code row of `planifest-framework/pipeline-reference.md` (line 111).
- The tier for each task type doesn't change. Primary maps to `sonnet` and cheaper maps to `haiku`, as the table maps them today.
- Rows for other tools stay as they are.
- A new test fails on any other value in the Claude Code column, the dispatch skeleton, or a skill's `model:` line.

## Acceptance Criteria
- [ ] The Claude Code column, the dispatch skeleton, and every `model:` line in a skill hold only `sonnet`, `opus`, `haiku`, or `fable`, and no task type changes tier. Verified by: unit
- [ ] The new test fails when a fixture puts `claude-haiku-4-5` in the Claude Code column, the skeleton, or a skill `model:` line. Verified by: unit
- [ ] At P4, the agent dispatches one `haiku` subagent and the model it reports is a Haiku model. Verified by: execution

## Dependencies
- The Claude Code Agent tool `model` parameter.
- Installed copies under `.claude/skills/*/references/` refresh when `setup.sh` re-runs.

Split step: keep. The table, skeleton, and skill values form one outcome, accepted model values everywhere.
