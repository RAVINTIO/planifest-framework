---
title: "Requirement: req-015 - parallel-streams-toggle-and-state"
summary: "A parallel_streams loop toggle, on by default in autonomous runs, moves independent requirements through P1 to P4 as separate streams, each with a state file that resume detection reads."
status: "draft"
version: "0.1.0"
---
# Requirement: req-015 - parallel-streams-toggle-and-state

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Source:** US-006
**Priority:** must-have

## User Story

As the human on the loop, I see independent requirements move through P1 to P4 as parallel subagent streams, so that a run with many small requirements finishes faster.

## Functional Requirements

### Loop toggles template (`planifest-framework/templates/loop-toggles.template.yml`)

- Add a `parallel_streams` entry. It ships as a commented-out line, `# parallel_streams: on`, with a comment that states the default. A human who copies the template to enable another loop therefore keeps the run-mode default.
- The header comment gains one line: "Exception: `parallel_streams` has a run-mode default. See the loop-runner Toggle Protocol."
- No uncommented line in the template reads `: on`. The existing "Absent file = all loops off" sentence stays, with the exception line under it.

### Loop-runner skill (`planifest-framework/skills/planifest-loop-runner/SKILL.md`)

- **`## Toggle Protocol (ADR-003)`:** Add a bullet for `parallel_streams`. It resolves in this order:
  1. If the key holds `on` or `off`, use that value in every run mode.
  2. If the file is absent, or the key is absent, use the run-mode default. The default is `on` when `plan/.run-mode` reads `autonomous` (req-001), and `off` otherwise.
  3. Any other value, `report-only` included, reads as `off` with a one-line warning. This matches the existing invalid-value rule.
- The bullet states that `parallel_streams` is a dispatch setting, not a loop. It arms no loop-state file and no stop rule.

### Dispatch standards (`planifest-framework/standards/agent-dispatch-standards.md`)

Add a `## Parallel Streams` section after `## Parallelism Rules`. It holds the stream mechanics, so the orchestrator skill only links to it (design risk on orchestrator size). The section says:

- **When streams run:** the orchestrator resolves `parallel_streams` at the start of P1 and records the value and its source in the P1 build-log block. Sources are `toggle file` or `run-mode default`.
- **Forming streams:** if the toggle resolves `on`, the orchestrator groups the in-scope user stories into streams. Two stories go in separate streams only if they pass the dependency test in `## Parallelism Rules`. If fewer than two streams result, the run proceeds as a single stream with no state files.
- **Stream scope:** each stream carries its requirements through P1, P2, P3, and P4. P5 onward runs once over the joined set.
- **Identifier blocks:** before dispatch, the orchestrator pre-assigns each stream a distinct block of requirement IDs, ADR IDs, and backlog IDs. No two streams allocate from the same block. This extends the existing backlog-ID rule in `## Agent Dispatch Template`.
- **Commits:** stream subagents don't commit. They share one working tree, so concurrent commits would race on the git index. The orchestrator commits each stream's artifacts when the stream reports back, before the join. This keeps the Hard Limit 7 cadence.
- **State files:** each stream has one state file at `plan/current/streams/stream-{nn}-{slug}.md`, created from the new template below. The orchestrator writes and commits it when the stream starts, at every phase change, and at every join.

### Stream state template (new, `planifest-framework/templates/stream-state.template.md`)

- Front matter fields: `stream-id`, `kind` (`stream`), `status` (`active`, `at-join`, `blocked`, or `done`), `phase` (`P1` to `P4`), `requirements` (the requirement IDs), `stories` (the user story IDs), `id-blocks`, and `updated`.
- Sections: `## Phase history` (a table of phase, start, end, subagents, and result), `## Files changed`, `## Declares`, `## Consumes`, and `## Next step`. req-017 defines what `## Declares` and `## Consumes` hold.
- Add `stream-state.template.md` to the orchestrator's `bundle_templates` front-matter list, since the orchestrator writes every stream file.

### Orchestrator skill (`planifest-framework/skills/planifest-orchestrator/SKILL.md`)

- **`## Agent Dispatch Standards`:** Add one sentence that names `## Parallel Streams` in `agent-dispatch-standards.md` as the home of stream mechanics.
- **`## Resume Detection`:** Add step 6b after step 6a. It reads every file under `plan/current/streams/` whose `kind` is `stream`:
  1. If any stream has `status: active`, resume each active stream at its recorded `phase` and `## Next step`. Dispatch all of them in one batch.
  2. If every stream has `status: at-join`, run the join for that phase (req-017).
  3. If a stream has `status: blocked`, handle it as an escalation for the current run mode.
  4. If stream files exist, the run stays in streams even when the toggle now resolves `off`. A toggle change takes effect at the next feature.
- **`## Phase Invocation Table (P1-P6)`:** Add one line under the table. If streams are active, each P1 to P4 gate runs once over the joined streams, not once per stream.

### Tests

- Add `planifest-framework/tests/test-0000033-req-015-parallel-streams-toggle-and-state.sh`. `run-tests.sh` picks it up.
- `planifest-framework/tests/test-0000016-pipeline-governance.sh` asserts that no toggle defaults to `on` (req-011). Its assertion stays unchanged and must still pass, because the new line ships commented out.

### Verified by

- The toggles template contains `parallel_streams` only on a line that starts with `#`.
- The toggles template has no line that matches `^[a-z_]*: on$`.
- The loop-runner `## Toggle Protocol` section names `parallel_streams`, `autonomous`, and the run-mode default.
- In that section, the explicit-value rule comes before the absent-file rule, checked by line number.
- `agent-dispatch-standards.md` has a `## Parallel Streams` heading after `## Parallelism Rules`, checked by line number.
- That section names `plan/current/streams/`, the P1 to P4 stream scope, the ID blocks, and the rule that stream subagents don't commit.
- `templates/stream-state.template.md` exists and names `status`, `phase`, `requirements`, `## Declares`, `## Consumes`, and `## Next step`.
- The orchestrator `## Resume Detection` section has a step 6b that names `plan/current/streams/`, `status: active`, and `at-join`.
- Step 6b sits after step 6a and before step 7, checked by line number.
- The orchestrator `## Agent Dispatch Standards` section links to `## Parallel Streams`.

## Acceptance Criteria

- [ ] `parallel_streams` resolves to `on` in an `autonomous` run with no toggles file, and to `off` in `interactive` and `continuous` runs with no toggles file. An explicit `on` or `off` wins in every mode.
- [ ] With the toggle `on`, each stream carries its requirements through P1 to P4 and keeps a state file under `plan/current/streams/` that resume detection reads.
- [ ] The new suite and the unchanged 0000016 suite pass under `run-tests.sh`.

## Dependencies

- req-001 defines the `autonomous` value of `plan/.run-mode`. This requirement reads it for the default.
- req-017 defines the join, the `## Declares` and `## Consumes` sections, and the reconciliation check.
- req-016 defines the always-parallel units that run inside each stream.
- req-012 (archive script) must copy `plan/current/streams/` to the archive, as P7 Step 6 copies `plan/current/` today.
- 0000016 ADR-003 (toggle protocol). This requirement adds a run-mode default for one key and leaves the protocol unchanged for every loop.
