---
title: "ADR 013: Parallel streams toggle and state"
summary: "A parallel_streams loop toggle, on by default in autonomous and off otherwise, moves independent requirements through P1 to P4 as separate streams. Each stream keeps a committed state file with a start-commit, and the orchestrator commits stream work with a Stream: trailer. Every phase skill lists its always-parallel units in skill text."
status: "accepted"
version: "0.1.0"
---
# ADR-013 - Parallel streams toggle and state

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Component:** planifest-framework
**Date:** 2026-10-19

## Context

Today a run moves all its requirements through each phase together. A run with many small, independent requirements waits on the slowest one at every phase. Each phase skill also decides for itself whether to split work. Some phases run units in sequence that could run at once.

Backlog 0000101 and 0000103 ask for two things:

- Independent requirements move through the phases as parallel streams.
- Parallel dispatch is the default in every phase, not a per-run choice.

The design sets a scalability target. A run with 10 or more independent requirements uses streams, and P8 reports subagent count and wall-clock time per phase.

Three prior decisions shape the choice:

- 0000006-ADR-003 puts parallelism in skill text, not code or hooks.
- 0000016-ADR-003 puts loop toggles in `planifest-overrides/loop-toggles.yml`, with an absent key reading as `off`.
- ADR-004 of this feature (D-012) makes an absent key read as `on` in `autonomous` for a listed set of keys.

Streams also need resume support. A session can end mid-stream, and resume must know each stream's phase and next step. req-015, req-016, and req-018 hold the detail.

## Decision

- **Toggle:** A new key, `parallel_streams`, joins `loop-toggles.template.yml`. It ships commented out as `# parallel_streams: on`. It resolves in this order:
  1. An explicit `on` or `off` wins in every run mode.
  2. An absent file or key reads as `on` in `autonomous`, under ADR-004's rule. In other modes it reads as `off`, as 0000016-ADR-003 set.
  3. Any other value, `report-only` included, reads as `off` with a one-line warning.
- **Not a loop:** `parallel_streams` is a dispatch setting. It arms no loop-state file and no stop rule.
- **Resolution point:** The orchestrator resolves the toggle at the start of P1. It records the value and its source in the P1 build-log block and in a `Parallel streams` header row (req-018).
- **Forming streams:** If the toggle reads `on`, the orchestrator groups in-scope user stories into streams. Two stories go in separate streams only if they pass the dependency test in `## Parallelism Rules`. Fewer than two streams means one stream with no state files.
- **Scope:** Each stream carries its requirements through P1 to P4. Each P1 to P4 gate runs once over the joined streams. P5 onward runs once over the joined set.
- **Identifier blocks:** Before dispatch, the orchestrator gives each stream its own block of requirement, ADR, and backlog IDs.
- **Commits:** Stream subagents don't commit, because they share one working tree and one git index. The orchestrator commits each stream's work when the stream reports back. Each such commit carries a `Stream: {stream-id}` trailer. This keeps the commit cadence of Hard Limit 7.
- **State files:** Each stream has one file at `plan/current/streams/stream-{nn}-{slug}.md`, from a new `stream-state.template.md`. Front matter holds these fields:
  - `stream-id`
  - `kind`
  - `start-commit`
  - `status`
  - `phase`
  - `requirements`
  - `stories`
  - `id-blocks`
  - `updated`

  Sections hold phase history, files changed, `## Declares`, `## Consumes`, and `## Next step`. The orchestrator writes and commits the file at stream start, at each phase change, and at each join.
- **Resume:** Resume Detection gains step 6b. It resumes each `active` stream at its recorded phase, in one batch. It runs the join when every stream is `at-join`, and treats `blocked` as an escalation. If stream files exist, the run stays in streams even when the toggle now reads `off`.
- **Always-parallel units:** Each phase skill lists its always-parallel units under `**Always parallel:**` in its parallelism section. The phase dispatches every listed unit that applies in one batch. A unit run alone needs a dependency reason in the build-log `Notes` field. The ship skill gains a `## Parallelism Directive` for its two read-only P7 searches.
- **Where the rules live:** Stream mechanics go in a `## Parallel Streams` section of `agent-dispatch-standards.md`. The orchestrator skill links to it (ADR-001). All dispatch rules stay skill and standards text, as 0000006-ADR-003 requires.
- **Measurement:** Each build-log phase block gains `End`, `Wall-clock`, and `Streams`. The P8 report gains a `## Phase Timing` table and flags under-dispatch.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Streams always on, no toggle | No configuration | Changes `interactive` and `continuous` runs without consent, against NFR-003 | Back-compat needs streams off by default outside `autonomous` |
| Streams run P1 to P6 | More time saved | P5 and P6 review the whole system, and per-stream reviews miss cross-stream threats | P5 and P6 need the joined set |
| Stream subagents commit their own work | Commits land sooner | Concurrent commits race on one git index | Shared working tree, and the repo bans worktrees |
| Separate worktree per stream | Isolated index and tree | The repo instruction bans worktrees, and merges add a join step of their own | Ruled out by repo instruction |
| Stream state in the build log only | One file to read | Concurrent writers to one file, and resume must parse prose | Per-stream files give each writer its own file |
| Parallel dispatch enforced by a hook | Deterministic | 0000006-ADR-003 keeps dispatch in skill text, and a hook can't see work units | Contradicts 0000006-ADR-003 |
| Phases decide their own batching, as today | No new text | Leaves phases that run independent units in sequence | Backlog 0000103 asks for a default floor |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | The toggles template and loop-runner Toggle Protocol gain `parallel_streams`. `agent-dispatch-standards.md` gains `## Parallel Streams` and `### Always-parallel work units`. A new stream-state template appears. The orchestrator gains Resume Detection step 6b and two links. Seven phase skills gain `**Always parallel:**` lists. The build-log template and the build-assessment skill gain timing fields. |

## Consequences

**Positive:**
- A run with many independent requirements finishes P1 to P4 sooner.
- Every phase dispatches its independent units in one batch by default.
- A session that ends mid-stream resumes each stream where it stopped.
- P8 shows whether streams saved time, from real timestamps.

**Negative:**
- The orchestrator does more bookkeeping: stream files, ID blocks, and per-stream commits.
- `plan/current/` gains a `streams/` folder that P7 must archive (ADR-010).
- A product that never runs `autonomous` sees streams only if it sets the toggle.

**Risks:**
- Two streams can plan edits to the same file. ADR-014's shared-file rule orders those edits.
- A grouping error can put dependent stories in separate streams. The reconciliation script in ADR-014 catches a declared artifact with no consumer, but not an undeclared dependency.
- A missing `Stream:` trailer hides a commit from reconciliation. The orchestrator writes every stream commit, so one agent owns the trailer.

## Related ADRs

- 0000006-ADR-003 (parallelism as skill instructions) - related-to. This ADR keeps dispatch in skill and standards text.
- 0000016-ADR-003 (loop toggles in `planifest-overrides/loop-toggles.yml`) - extends. It adds a key that is a dispatch setting, not a loop.
- ADR-001 - depends-on. Stream detail goes into a standards file.
- ADR-004 - depends-on. It sets the absent-key default in `autonomous`.
- ADR-014 - related-to. It owns the joins and reconciliation.
- ADR-010 - related-to. The archive script moves `streams/`.
- ADR-015 - related-to. It assigns ownership of `plan/current/streams/`.

## Supersedes

- None

## Superseded By

- None
