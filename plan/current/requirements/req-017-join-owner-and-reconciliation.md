---
title: "Requirement: req-017 - join-owner-and-reconciliation"
summary: "The orchestrator owns every join between streams or batches, and a reconciliation script checks after each join that every declared artifact has a consumer that uses it."
status: "draft"
version: "0.1.0"
---
# Requirement: req-017 - join-owner-and-reconciliation

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Source:** US-006
**Priority:** must-have

## User Story

As the human on the loop, I see one owner for every join between streams or batches, so that no artifact falls into a seam that no agent owns.

## Functional Requirements

### Dispatch standards (`planifest-framework/standards/agent-dispatch-standards.md`)

Add a `## Joins and Reconciliation` section after `## Parallel Streams` (req-015). It says:

- **Join owner:** the orchestrator owns every join. A join happens when a parallel batch returns, and when the streams meet at a P1 to P4 gate. The owner is the agent that placed the dispatch, never a dispatched subagent.
- **Declarations:** every dispatch prompt asks the subagent to report two lists with its result.
  - `Declares`: each artifact it produced for another unit to use. Each row gives an artifact ID, the file that defines it, and the intended consumer, a stream ID or a requirement ID.
  - `Consumes`: each artifact from another unit that it used, by artifact ID.
- **Where declarations live:** for a stream, the orchestrator writes them to the `## Declares` and `## Consumes` sections of the stream's state file. For a batch outside streams, the orchestrator writes one join record at `plan/current/streams/join-{phase}-{nn}.md`, with `kind: join`, in the same two-section format.
- **Shared files:** before P3 dispatch, the orchestrator compares the files each stream plans to change. If two streams plan to change the same file, the orchestrator orders those edits, so one stream at a time edits that file.
- **Reconciliation step:** after every join, and before the gate check, the orchestrator runs the reconciliation script below.
- **Findings:** a finding blocks the gate. The orchestrator assigns the fix to one stream or takes it itself, then runs the script again.
  - In `autonomous`, the fix runs as a loop under `planifest-loop-runner`, with the gate-loop cap that req-003 sets.
  - In `interactive` and `continuous`, the orchestrator lists the finding in the gate summary. This adds no new STOP point.

### Reconciliation script (new, `planifest-framework/scripts/stream-reconcile.mjs`)

- Node, no dependencies, the same style as `scripts/consistency-check.mjs`. Usage: `node stream-reconcile.mjs [planCurrentDir]`, defaulting to `plan/current`.
- It reads every `*.md` file under `{planCurrentDir}/streams/`, both stream state files and join records.
- It reports a finding for each declared artifact that fails any of these checks:
  1. The row names a consumer.
  2. The consumer is a different stream or unit than the producer. A stream can't consume its own artifact.
  3. If the consumer is a stream or unit, its `## Consumes` section lists the artifact ID. If the consumer is a requirement, the file `{planCurrentDir}/requirements/{req-id}-*.md` exists and names the artifact ID.
  4. The artifact ID appears in at least one changed file of the consumer, other than the file that defines it. For a stream, the changed files come from `## Files changed`.
- Exit codes: `0` when clean, `1` when there are findings, listed on stdout. An absent `streams/` directory exits `0` with no output.

### Why a script, and how it fits 0000006-ADR-003

- 0000006-ADR-003 says parallelism is enforced through skill text, not hooks. That still holds. The orchestrator decides what to dispatch and when, in skill text.
- The reconciliation is a verifier, not dispatch enforcement. It reads files after a join and decides nothing about dispatch. Skill text calls it, and no hook runs it.
- A script is justified because the seam it checks has slipped past model review three times (backlog 0000082). A deterministic file check gives the same answer on every run. `scripts/consistency-check.mjs` sets the precedent for a verifier script that skill text calls.
- P2 records this choice in an ADR.

### The 0000082 test

- Backlog 0000082 asks whether the mechanism would have caught the four unused masthead faces in 0000006 without a human opening a browser.
- It would. The faces stream declares each face, with the rules stream as its consumer. No rule file names the face IDs, so check 4 fails for each face, and the script reports four findings.
- The check depends on the producer declaring the faces. The dispatch prompt asks for every artifact meant for another unit, so a face built for another stream to apply falls inside that rule.

### Orchestrator skill (`planifest-framework/skills/planifest-orchestrator/SKILL.md`)

- **`## Phase Conventions`:** Add one bullet. After every join, run `node planifest-framework/scripts/stream-reconcile.mjs` before the gate check. A finding blocks the gate. Detail lives in `## Joins and Reconciliation` in `agent-dispatch-standards.md`.
- **`## Agent Dispatch Standards`:** Name `## Joins and Reconciliation` beside `## Parallel Streams`.

### Dispatch template (`agent-dispatch-standards.md`, `## Agent Dispatch Template`)

- The two `Agent(...)` skeleton prompts end with the `Declares` and `Consumes` request, after "Confirm: files modified, what changed".

### Tests

- Add `planifest-framework/tests/test-0000033-req-017-join-owner-and-reconciliation.sh`. `run-tests.sh` picks it up. It runs the script against fixture directories that the test builds in a temp directory:
  - a clean pair of streams, which exits `0`
  - a declared artifact with no consumer, which exits `1`
  - a stream that names itself as consumer, which exits `1`
  - a reproduction of 0000006: four declared faces and a consumer stream whose changed files never name them, which exits `1` with four findings
  - an absent `streams/` directory, which exits `0`
- No existing suite asserts the text this requirement changes.

### Verified by

- `planifest-framework/scripts/stream-reconcile.mjs` exists and exits `0` on the clean fixture.
- The script exits `1` on each of the three failing fixtures, and prints four findings for the 0000006 fixture.
- The script exits `0` with no output when `streams/` is absent.
- `agent-dispatch-standards.md` has a `## Joins and Reconciliation` heading after `## Parallel Streams`, checked by line number.
- That section names the orchestrator as join owner, `Declares`, `Consumes`, `join-{phase}-{nn}.md`, and `stream-reconcile.mjs`.
- That section names `0000006-ADR-003` and states that the script is a verifier called from skill text.
- The orchestrator `## Phase Conventions` section names `stream-reconcile.mjs`.
- Both skeleton prompts in `## Agent Dispatch Template` name `Declares` and `Consumes`.

## Acceptance Criteria

- [ ] The orchestrator owns every join between streams or batches, and it runs a reconciliation step after each join and before the gate check.
- [ ] `stream-reconcile.mjs` reports every declared artifact with no consumer, a self-consumer, or no use in a consumer's changed files. It reports all four faces in the 0000006 fixture.
- [ ] The new suite passes under `run-tests.sh`.

## Dependencies

- req-015 creates `plan/current/streams/`, the stream state template, and its `## Declares` and `## Consumes` sections.
- req-003 sets the gate-loop cap for an `autonomous` fix loop.
- req-016 defines the batches whose joins this requirement owns.
- 0000006-ADR-003 still holds. A P2 ADR records why the reconciliation is a script.
- Backlog 0000082 is the source problem. Backlog 0000105's font-usage gate fixed one instance, and this requirement generalises the check.
