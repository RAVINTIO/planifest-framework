---
title: "ADR 014: Orchestrator owns joins and a reconcile script"
summary: "The orchestrator owns every join between streams or batches. After each join and before the gate check, it runs scripts/stream-reconcile.mjs, a deterministic verifier that reports declared artifacts with no consumer that uses them. A finding blocks the gate and enters a fix loop capped at 3."
status: "accepted"
version: "0.1.0"
---
# ADR-014 - Orchestrator owns joins and a reconcile script

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Component:** planifest-framework
**Date:** 2026-10-19

## Context

Parallel streams and batches (ADR-013) create seams. One unit produces an artifact for another unit to use. If no agent owns the join, the artifact can go unused, and no reviewer notices.

Backlog 0000082 records this. In 0000006, one stream built four masthead faces for a rules stream to apply. The rules stream never named them. Model review missed it three times. A human found it by opening a browser. Backlog 0000105's font-usage gate fixed that one instance, but not the class.

The design gives every join one owner and a reconciliation step after it. P1 left open where the reconciliation runs. D-007 settled it as a script, because the check is deterministic. 0000016-ADR-007 sets that a deterministic check runs in control flow, not in skill prose alone.

0000006-ADR-003 puts parallelism in skill text, not hooks. The reconciliation must fit that rule. req-017 holds the detail.

## Decision

- **Join owner:** The orchestrator owns every join. A join happens when a parallel batch returns, and when streams meet at a P1 to P4 gate. The owner is the agent that placed the dispatch, never a dispatched subagent.
- **Declarations:** Every dispatch prompt asks the subagent to report two lists with its result:
  - `Declares`: each artifact it made for another unit, with an artifact ID, the defining file, and the intended consumer.
  - `Consumes`: each artifact from another unit that it used, by ID.

  Both `Agent(...)` skeletons in `## Agent Dispatch Template` end with this request.
- **Where declarations live:** For a stream, the orchestrator writes them to the stream state file (ADR-013). For a batch outside streams, it writes a join record at `plan/current/streams/join-{phase}-{nn}.md`, with `kind: join`.
- **Shared files:** Before P3 dispatch, the orchestrator compares the files each stream plans to change. If two streams plan to change one file, the orchestrator orders those edits.
- **Reconciliation script:** A new `scripts/stream-reconcile.mjs` runs after every join and before the gate check. It is dependency-free Node, in the style of `scripts/consistency-check.mjs`. It reads every `*.md` file under `{planCurrentDir}/streams/` and reports each declared artifact that fails any of these checks:
  1. The row names a consumer.
  2. The consumer differs from the producer.
  3. The consumer's `## Consumes` section lists the artifact, or the consumer requirement's file names it.
  4. The artifact ID appears in a changed file of the consumer, other than its defining file.
- **Changed files:** For a stream, the script reads `git log --name-only --format= --grep "Stream: {stream-id}" {start-commit}..HEAD`. For a join record, it reads the record's `## Files changed` section.
- **Exit codes:** `0` when clean, `1` with findings on stdout. An absent `streams/` folder exits `0` with no output.
- **Findings:** A finding blocks the gate. The orchestrator assigns the fix to one stream or takes it itself, then reruns the script. The fix runs as a loop under `planifest-loop-runner` with a cap of 3 in every run mode. At the cap, `autonomous` follows ADR-005. In `interactive` and `continuous`, the orchestrator lists the open finding in the gate summary. No new stop point appears.
- **Fit with 0000006-ADR-003:** The script is a verifier, not dispatch control. It reads files after a join and decides nothing about dispatch. Skill text calls it, and no hook runs it.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| A model reviewer checks each join | No new script, and it reads intent | Model review missed this seam three times in backlog 0000082 | Not deterministic, so it gives different answers on reruns |
| A hook runs reconciliation on commit | Runs without skill text calling it | Breaks 0000006-ADR-003, and a commit isn't the same event as a join | Wrong trigger and against a standing ADR |
| Each subagent owns its own join | No orchestrator bookkeeping | A subagent can't see sibling output, so the seam stays unowned | Leaves the gap the design names |
| Check declared consumers only, not changed files | Simpler script | A consumer can list an artifact in `Consumes` and still never use it | Misses the 0000006 case |
| Fix loop with the default cap and no listing outside `autonomous` | Less text | A stuck finding stops a non-autonomous run with no gate entry | The gate summary must show open findings |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | `agent-dispatch-standards.md` gains `## Joins and Reconciliation` and `Declares` and `Consumes` lines in both skeleton prompts. A new `scripts/stream-reconcile.mjs` appears with a fixture-based suite. The orchestrator's `## Phase Conventions` and `## Agent Dispatch Standards` name the script and the section. |

## Consequences

**Positive:**
- Every seam between streams or batches has one owner.
- An unused declared artifact blocks the gate on every run, with the same answer each time.
- The script reports all four faces in a reproduction of 0000006.
- Dispatch stays in skill text, so 0000006-ADR-003 still holds.

**Negative:**
- Every dispatch prompt grows by two report lists.
- The check depends on producers declaring their artifacts. An undeclared artifact passes.
- Check 4 matches on artifact ID text. A consumer that uses an artifact under another name reads as a finding.

**Risks:**
- A short or common artifact ID can match by chance and hide a real gap. The dispatch standards should ask for distinctive IDs.
- A rewritten history or a lost `Stream:` trailer hides a stream's commits from check 4. That produces false findings, not false passes.
- A stuck finding at the cap in `autonomous` becomes an exception through ADR-005, which delays the PR.

## Related ADRs

- 0000006-ADR-003 (parallelism as skill instructions) - related-to. The script is a verifier that skill text calls, so dispatch stays in skill text.
- 0000016-ADR-007 (deterministic caps and enforcement) - depends-on. It sets the precedent for deterministic checks in control flow.
- ADR-013 - depends-on. It defines streams, state files, `start-commit`, and the `Stream:` trailer.
- ADR-005 - depends-on. It governs the cap in `autonomous`.

## Supersedes

- None

## Superseded By

- None
