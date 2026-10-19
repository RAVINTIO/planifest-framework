---
title: "Requirement: req-018 - subagent-count-and-wall-clock"
summary: "The build log records subagent count and wall-clock time per phase, and the P8 report uses them to measure parallel dispatch."
status: "draft"
version: "0.1.0"
---
# Requirement: req-018 - subagent-count-and-wall-clock

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Source:** US-006
**Priority:** should-have

## User Story

As the human on the loop, I read the subagent count and wall-clock time for each phase in the P8 report, so that I can see whether parallel streams made the run faster.

## Functional Requirements

### Build log template (`planifest-framework/templates/build-log.template.md`)

- **Header table:** add a `Parallel streams` row. Its value is `on` or `off`, with the source from req-015, for example `on (run-mode default)`.
- **P0 block and the copyable phase block:** keep `Start` and `Agents spawned`. Add three rows after `Start`:
  - `End`: the timestamp when the phase gate passes.
  - `Wall-clock`: whole minutes from `Start` to `End`.
  - `Streams`: the number of streams active in the phase, or `n/a`.
- `Agents spawned` keeps its label. Its meaning becomes the number of subagents dispatched in the phase, across all streams.
- **Summary table:** add `Total wall-clock` and `Phases using streams`. The Summary fills at P7, so `Total wall-clock` runs from the P0 `Start` to the P7 `End`.

### Orchestrator skill (`planifest-framework/skills/planifest-orchestrator/SKILL.md`)

- **`## Hard Limits`, limit 8:** the gate entry fills `End`, `Wall-clock`, `Agents spawned`, and `Streams` for the phase.
- **`## Phase Conventions`:** add one bullet. Take every timestamp from `date -u +%Y-%m-%dT%H:%M:%SZ`, never from an estimate. If streams are active, the phase `Start` is the first stream's start and the `End` is the join gate.

### Ship skill (`planifest-framework/skills/planifest-ship-agent/SKILL.md`)

- The P7, P8, and P9 build-log lines say to fill `End`, `Wall-clock`, and `Agents spawned` when the phase finishes.

### Build assessment skill (`planifest-framework/skills/planifest-build-assessment-agent/SKILL.md`)

- **`## Report Structure`:** add a `## Phase Timing` section after `## Subagent Dispatch`. It is a table of phase, subagents, parallel batches, streams, and wall-clock. A total row sums subagents and wall-clock.
- **`## Critical Audit`, parallelism audit:** add three checks.
  1. Flag a phase that has two or more always-parallel units (req-016) and recorded fewer than two subagents.
  2. Flag a run with 10 or more independent requirements where `Parallel streams` reads `off`. This is the design's scalability target.
  3. If `Parallel streams` reads `on`, compare P1 to P4 wall-clock with the sum of the stream phase times, from the stream state files' `## Phase history`. Report the time saved.
- **`## Critical Audit`, build log integrity:** name `End`, `Wall-clock`, and `Streams` among the per-phase fields to check.
- A build log from before this feature lacks the new fields. The existing rule applies: mark them "not captured".

### Wording constraint

- No new text uses the word "telemetry". `test-0000030-req-003-telemetry-pipeline-text-removal.sh` scans the build-log template, the orchestrator, and the ship skill for it.

### Tests

- Add `planifest-framework/tests/test-0000033-req-018-subagent-count-and-wall-clock.sh`. `run-tests.sh` picks it up.
- These existing suites read the files this requirement changes. Their assertions stay unchanged and must still pass:
  - `planifest-framework/tests/test-0000006-build-assessment.sh`, which asserts `Agents spawned`, `Parallel task`, `Subagent`, and `Parallel` in the template and the P8 skill.
  - `planifest-framework/tests/test-0000030-req-003-telemetry-pipeline-text-removal.sh`.

### Verified by

- The build-log template names `Parallel streams`, `End`, `Wall-clock`, `Streams`, and `Total wall-clock`.
- In the copyable phase block, `End` and `Wall-clock` come after `Start`, checked by line number.
- The template still names `Agents spawned` and `Parallel task batches`.
- The orchestrator `## Phase Conventions` section names `date -u` and `Wall-clock`.
- The ship skill's P7, P8, and P9 build-log lines name `Wall-clock`.
- The build-assessment skill has a `## Phase Timing` heading after `## Subagent Dispatch` in its report structure, checked by line number.
- The build-assessment parallelism audit names `Parallel streams`, the 10-requirement threshold, and `Wall-clock`.
- No changed file gains the word `telemetry`.

## Acceptance Criteria

- [ ] Every phase block in the build log records subagent count and wall-clock time, from real timestamps.
- [ ] The P8 report has a `Phase Timing` table and flags phases that under-dispatch and runs that skip streams at 10 or more independent requirements.
- [ ] The new suite and the unchanged 0000006 and 0000030 suites pass under `run-tests.sh`.

## Dependencies

- req-015 supplies the `Parallel streams` value and the stream state files' `## Phase history`.
- req-016 supplies the always-parallel unit lists that the P8 audit checks against.
- req-006 also adds per-phase build-log lines and a touchpoint count to the same template and P8 skill. The two changes must land in one consistent template.
- req-005 changes the P9 final report, which may quote these timings.
