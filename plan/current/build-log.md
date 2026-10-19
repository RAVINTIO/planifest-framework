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
| Agents spawned | `4` |
| MCP calls | `0` |
| Parallel task batches | `1` |
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

### P1: Spec

| Field | Value |
|-------|-------|
| Start | `2026-10-19T01:33:46Z` |
| Model tier | primary (orchestrator), cheaper (requirement drafting subagents) |
| Skills loaded | planifest-spec-agent |
| Agents spawned | `7` (plus 4 resumed for fixes) |
| MCP calls | `0` |
| Parallel task batches | `3` |
| Notes | Requirement IDs fixed by the orchestrator before dispatch, so parallel streams can't collide. |
- P1 cross-stream review (fresh-context, REJECT-default, outside the `design_critic` toggle): REJECT with 1 blocker, 6 major, and 12 minor findings. The orchestrator decided fixes F1 to F19 and sent each stream its items.
- Requirement Change (P1, clarifying): the design's clean close-out row gains D-010 and D-011. Intent unchanged. No phase re-run.
- P1 re-review: ACCEPT. All 19 fixes closed. Four minor wording gaps fixed by the orchestrator: approach counter wording now says per loop instance, the back-compat risk cites NFR-003, the back-compat scope lists req-006's every-mode changes, and req-005 names the live build log before Step 6.
- Artifacts: execution plan, 18 requirements (3 acceptance criteria each), scope, risk register, and domain glossary. No OpenAPI spec, operational model, SLO definitions, or cost model, because no trigger applies. `planifest-framework/component.yml` already exists, and P6 updates it.
- `consistency-check.mjs`: 15 hits, all cross-feature ADR references (backlog 0000079 false positive).
- End: `2026-10-19T01:51:00Z`
- Gate passed: P1 (continuous run, no stop)

### P2: ADRs

| Field | Value |
|-------|-------|
| Start | `2026-10-19T01:51:22Z` |
| Model tier | primary (orchestrator and ADR drafting) |
| Skills loaded | planifest-adr-agent |
| Agents spawned | `3` |
| MCP calls | `0` |
| Parallel task batches | `1` |
| Notes | ADR numbers fixed by the orchestrator before dispatch. |
- Artifacts: ADR-001 to ADR-015. Six prior ADRs are amended (0000012-ADR-004, 0000012-ADR-005, 0000004-ADR-003, 0000014-ADR-008, 0000016-ADR-003, 0000016-ADR-005) and one is superseded (0000003-ADR-006). P6 records each in `docs/decisions-index.md`.
- Gap found by the ADR-006 drafter: req-005 lacked D-003 (draft PR while an exception waits). Fixed in req-005.
- `consistency-check.mjs`: clean.
- Design critic: toggle off, not run. The P1 cross-stream review already checked the decisions these ADRs record.
- End: `2026-10-19T01:55:48Z`
- Gate passed: P2 (continuous run, no stop)

### P3: Codegen

| Field | Value |
|-------|-------|
| Start | `2026-10-19T01:59:49Z` |
| Model tier | primary (orchestrator and work-package agents) |
| Skills loaded | planifest-codegen-agent |
| Agents spawned | `7` |
| MCP calls | `0` |
| Parallel task batches | `2` |
| Notes | Baseline before P3: 59 feature and 24 regression suites pass. |
- Dispatch plan: requirements grouped into six work packages by the files they change. Wave 1 runs five packages in parallel. Wave 2 runs req-015 to req-017, because they edit every phase skill that wave 1 also edits.
- Deviation: each work-package agent runs the red, green, and refactor steps itself, rather than spawning three subagents per requirement. The tests are Bash text assertions, so a nested spawn per step costs more than it gains. Each agent still confirms RED before GREEN.
- Shared files: wave 1 packages share `planifest-orchestrator/SKILL.md`, the build-log template, and the build-assessment skill. Agents edit them with targeted edits only, never a whole-file rewrite, and the orchestrator commits after each package reports.
- Wave 1: five packages, all GREEN. WP1 req-001 and req-002. WP2 req-003 and req-004. WP3 req-012, req-013, req-005, and req-007. WP4 req-008 to req-011. WP5 req-006, req-018, and req-014. Every new suite confirmed RED before GREEN.
- Existing suites edited, as listed exceptions: `test-0000025-req-002` (req-012) and `test-0000032-req-001` (req-007). Deviation: WP3 made the same one-line edit to the regression copy `tests/regression/test-0000032-req-001...`, which would otherwise fail.
- req-007 sweep result: only the ship skill and the orchestrator held prompts that needed a change. The other phase skills and `workflows/` needed none.
- Concurrency: WP4 rewrote the orchestrator once with `sed -i` during the wave. Every wave 1 suite passed afterwards, so no concurrent edit was lost.
- Full suite after wave 1: 73 of 74 feature suites passed. The 0000030 residue check flagged the retired integration word inside the new req-018 suite. Fixed by splitting the word. Both suites pass.
- Wave 2: WP6a req-015 and req-017, WP6b req-016. All GREEN. Deviation: the `parallel_streams` template line reads `# parallel_streams: off` with an `autonomous` default of `on` in its comment, matching the four checker keys. req-015 updated to match.
- `planifest-framework/component.yml`: 0.31.0 to 0.32.0, feature set to 0000033.
- Full suite after P3: 77 feature and 24 regression suites pass.
- NFR-005: the orchestrator skill grew from 9,276 to 10,314 words (11 percent). Most new detail sits in four new standards files.
- Changes against `main`: 54 framework files, 3,005 insertions, 86 deletions. No added line holds an em dash.
- End: `2026-10-19T02:25:20Z`
- Gate passed: P3 (continuous run, no stop)

### P4: Validate

| Field | Value |
|-------|-------|
| Start | `2026-10-19T02:25:36Z` |
| Model tier | primary |
| Skills loaded | planifest-validate-agent |
| Agents spawned | `1` |
| MCP calls | `0` |
| Parallel task batches | `1` |
| Notes | none |
- Library audit: pass. The two new scripts import only Node built-ins.
- Lint and type-check equivalents: `node --check` on both new scripts and `bash -n` on all 18 new suites pass. `self-description-check.mjs` passes. Branch parity: no `src/` change.
- Semantic correctness: 18 requirements, 54 acceptance criteria. First pass found 52 covered.
- Cycle 1: Check: semantic. Error: req-010 AC-2 and AC-3 had no assertion, and req-009 AC-2 lacked its impact check. Root cause: suites asserted term presence, not the stated behaviour. Fix: five assertions over `release-sizing.md`, step 3c, and the design template. Result: pass. All 54 covered.
- Full suite: 77 feature and 24 regression suites pass.
- Not run locally: `test_setup.ps1`, because `pwsh` isn't installed. This feature doesn't change `setup.ps1`. CI runs it on the PR.
- Verify by execution: toggle off, not run. `archive-current.mjs` and `stream-reconcile.mjs` run against temporary git repos inside their suites.
- Self-corrections: 1.
- End: `2026-10-19T02:32:59Z`
- Gate passed: P4 (continuous run, no stop)

### P5: Security

| Field | Value |
|-------|-------|
| Start | `2026-10-19T02:33:15Z` |
| Model tier | primary |
| Skills loaded | planifest-security-agent |
| Agents spawned | `pending` |
| MCP calls | `0` |
| Parallel task batches | `pending` |
| Notes | Two fresh-context reviewers in parallel: the two new scripts, and the governance surface of the skill text. |
- Script review: REJECT. Two High (symbolic-link archive dir moves files into `src/`, symbolic-link `plan/current` deletes files in `src/`), two Medium, four Low. Reviewer reproduced findings 1 to 5 in scratch repos.
- Governance review: REJECT, overall High. Three High (explicit `off` removes checkers, override precedence unstated, push from the default branch), four Medium, five Low.
- Decisions (continuous run, orchestrator): fix every finding. Script fixes S1 to S8 go to one agent. Governance fixes G1 to G12 go to two agents with disjoint files. G12 narrows req-011: Fast Path never admits `hooks/`, `scripts/`, or setup changes. G11 adds a seventh exception item for a credential sighting. All fixes strengthen the rules.
