---
title: "Requirement: req-003 - quiet test output"
summary: "A quiet mode in run-tests.sh prints only failures and totals, and the skills use it."
status: "active"
version: "0.1.0"
---
# Requirement: req-003 - quiet test output

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000038-token-efficiency-windows-shard
**Source:** US-003
**Priority:** must-have

## User Story

As an agent running the suite, I get only failures and totals, so that each run adds little context.

## Functional Requirements
- `planifest-framework/tests/run-tests.sh` accepts a `--quiet` flag. In quiet mode it prints only `FAIL` lines, the failed-suite list, and the totals.
- A suite that exits non-zero with no `FAIL` line still appears in the failed-suite list, and the run still exits non-zero.
- Without the flag, output is unchanged, so CI output doesn't change.
- Quiet mode works with the shard variables `PLANIFEST_SHARD_INDEX` and `PLANIFEST_SHARD_COUNT`.
- `planifest-framework/skills/planifest-refactor/SKILL.md` (lines 19 and 45), `planifest-framework/skills/planifest-validate-agent/SKILL.md` (Test step), and the TDD loop in `planifest-framework/skills/planifest-codegen-agent/SKILL.md` name quiet mode for full-suite runs.
- On a failure, those skills rerun only the failing suite in full.

## Acceptance Criteria
- [ ] In quiet mode, a run with one failing suite prints that suite's `FAIL` line, the failed-suite list, and the totals, and prints no `PASS` line or suite header. Verified by: integration
- [ ] In quiet mode, a suite that exits non-zero with no `FAIL` line appears in the failed-suite list, and the run exits non-zero. Verified by: integration
- [ ] Without `--quiet`, run output is unchanged, and the refactor, validate, and codegen skills name quiet mode and a full rerun of only the failing suite. Verified by: unit

## Dependencies
- The shard logic in `run-tests.sh`.
- The CI workflow calls the runner without the flag.

Split step: keep. The runner flag and the skill edits that call it serve one outcome, small test output.
