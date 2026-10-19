---
title: "Build Log - 0000033-human-on-the-loop-run-mode"
summary: "Working log file maintained by the orchestrator throughout the pipeline run."
---
# Build Log - 0000033-human-on-the-loop-run-mode

> Created at P0. Appended by the orchestrator at each phase boundary. Survives session changes.

## Header

| Field | Value |
|-------|-------|
| Feature ID | `0000033-human-on-the-loop-run-mode` |
| Pipeline start | `2026-10-19T01:00:25Z` |
| Tool | `claude-code` |
| Primary model | `claude-opus-5-5` |
| Cheaper model | `claude-sonnet-5-5` |

---

## Phase Log

### P0: Assess & Coach

| Field | Value |
|-------|-------|
| Start | `2026-10-19T01:00:25Z` |
| Model tier | primary |
| Skills loaded | planifest-orchestrator |
| Agents spawned | `0` |
| MCP calls | `0` |
| Parallel task batches | `0` |
| Notes | See entries below. |

- Migrations: two files outside `_done/`. Both target downstream projects, and this repo ships them. The human chose to re-run `setup.sh claude-code --strict-orchestrator` and keep both files in place. The shell-write guard is now installed here. The context-mode and telemetry migration doesn't apply, because no stale entries exist.
- Pre-flight: PR #58 (0000031 and 0000032) merged. `main` fast-forwarded to `54aeda8`. Branch `feat/0000033-human-on-the-loop-run-mode` created from `main`.
- Context reset: the session was cleared before this run. Only housekeeping ran since, and the human continued without a second clear.
- Backlog pickup: the human chose 11 entries in one run: 0000076, 0000078, 0000103, 0000104, 0000075, 0000073, 0000086, 0000082, 0000101, 0000059, and 0000062. Every other entry: leave.
- P0 exchange (scope): Q: Core four workflow entries, all 11, or two waves? / A: All 11 in one run. "Be brave."
- Adoption mode: standard-iterative, derived from `plan/_archive/` and `docs/about.md`. Recorded in the design draft for one confirmation, per the human's direction to keep P0 questions to real forks.
- Version: `0.31.0` to `0.32.0` (Feature Pipeline, minor bump). Recorded in the design draft for one confirmation.
- Scope Lock: dispatched four `planifest-scope-lock-agent` instances in parallel, one per scenario path, on `claude-sonnet-5-5`.
- Scope Lock (happy path): You choose `autonomous` at P0 and confirm design, scope answers, and run mode in one turn; the run reaches a raised PR with no gate waiting, ending in one report and a clean tree. [source: agent-draft-accepted]
- Scope Lock (first-run path): An upgraded product sees no change until the human chooses `autonomous`; existing overrides keep working. [source: agent-draft-accepted]
- Scope Lock clarification (first-run): no release setting keeps the three-story rule; an override wins over `autonomous` text; an override never counts as choosing `autonomous`. [source: agent-draft-accepted]
- Scope Lock (error path): A gate the run can't clear gets a changed approach, not a stop; exception-list items wait in the final report after all other work finishes. [source: agent-draft-accepted]
- Scope Lock clarification (error): gross deviation uses the reversal protocol's altering class; an exhausted budget becomes an exception-list item. [source: agent-draft-accepted]
- Scope Lock (cross-session): A resumed run keeps its mode, loop counts, budgets, and stream state, and repeats only unfinished P7 archive steps. [source: agent-draft-accepted]
- Scope Lock clarification (cross-session): amend 0000012-ADR-005 so `autonomous` is recognised; keep every loop cap, with up to 3 approaches per gate before an exception; reversal budget stays at 2; stream state under `plan/current/streams/`. [source: agent-draft-accepted]
- P0 exchange (Scope Lock): Q: accept, edit, or reject each of the four drafts and gap answers? / A: accept all.
- Scope Lock complete. All four scenario paths captured.
- P0 exchange (design and run mode): Q: confirm the design as drafted, and pick continuous or interactive? / A: design as drafted, continuous.
- P0 questions asked: 4 (migration handling, scope bundle, Scope Lock batch, design and run mode). The PR #58 merge wait was a pre-flight step.
- Gate accepted: P0 (2026-10-19T01:33:20Z)
