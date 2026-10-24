---
title: "Requirement: req-001 - stable Windows timing"
summary: "Timed hook checks make one warm-up call and one timed call, so a cold start no longer fails CI."
status: "active"
version: "0.1.0"
---
# Requirement: req-001 - stable Windows timing

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000038-token-efficiency-windows-shard
**Source:** US-001
**Priority:** must-have

## User Story

As the human on the loop, I see CI fail only when a hook is slow, so that a red check means a real fault.

## Functional Requirements
- Each timed check in `test-0000032-req-003-no-run-triage-message.sh`, `test-0000032-req-007-stderr-block-reasons.sh`, and `test-0000032-req-009-shell-guard-path-parity.sh` makes one untimed warm-up call, then one timed call.
- The timed call must finish under 200 ms. The limit stays at 200 ms in all three suites.
- No check retries a slow call. Today `req-009` times the best of three runs per command (lines 298 to 324). That best-of-three loop is a retry and gives way to one warm-up plus one timed call.
- Each suite has a copy in `planifest-framework/tests/regression/`. The copies change with the originals.
- The hook still runs as a fresh Node process on every timed call. The warm-up only warms disk caches.

## Acceptance Criteria
- [ ] In all three suites and their regression copies, each timed check makes one untimed warm-up call before one timed call. Verified by: integration
- [ ] The timed call fails the check when it takes 200 ms or more, and no suite retries it. A test with a hook stub that sleeps past 200 ms proves the failure. Verified by: unit
- [ ] The 200 ms limit is unchanged in every timed assertion of the three suites and their regression copies, and the full suite passes. Verified by: integration

## Dependencies
- The `now_ms`, `run_node`, and `under_200` helpers in the `req-003` and `req-007` suites.
- None on other requirements.

Split step: keep. The three suites share one outcome, a warm-up and a single timed call.
