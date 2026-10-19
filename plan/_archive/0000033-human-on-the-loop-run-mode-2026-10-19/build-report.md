# Build Report (0000033-human-on-the-loop-run-mode, 19 Oct 2026)

## Summary

The run reached P7 with 42 subagent dispatches. The cheaper tier handled 19 of them. The run mode is `continuous`, which the human chose at P0, so no touchpoint audit applies.

The log has one process violation, several record gaps, and a P8 model entry that does not name the model that ran this assessment. The findings below are ordered by severity.

## Findings

1. **Framework directive violated in P3.** WP4 rewrote `planifest-orchestrator/SKILL.md` with `sed -i` during wave 1. Hard Limit 8 of the project `CLAUDE.md` requires Write or Edit for every project file change, and it names `sed -i`. The log records the command but does not flag it as a deviation. Every wave 1 suite passed afterwards.
2. **P8 model entry does not match this run.** The P8 row records the cheaper tier without a concrete model. The header names `claude-sonnet-5-5` as the cheaper model. This assessment runs on `claude-haiku-5-5`, per the session environment. The log should name the concrete model for each tier entry.
3. **Header lacks two rows the audit needs.** The header has no `Run mode` row and no `Parallel streams` row. The run-mode checker read the mode from `plan/.run-mode`. The parallel-streams check cannot run, and this run has 18 requirements.
4. **Per-phase fields missing.** No phase records `Wall-clock` or `Streams`. P0 and P8 have no `End` field. P0 uses its gate timestamp as its end.
5. **P0 question lines missing.** The `Brief complete` and `Stack unchanged` lines are absent. The count of four questions cannot be checked against NFR-002.
6. **Batch counts are inconsistent.** P7 records one parallel batch with zero agents. P4 records one batch with one agent.
7. **Model routing gaps.** P4 validation ran on the primary tier. The req-007 sweep, a discovery task, ran inside a primary-tier work package. The log does not say whether the sweep used a separate agent.
8. **Self-corrections undercounted.** The log records one self-correction, in P4. The P3 narrative records a second, a retired word in the req-018 suite. The log does not count it.
9. **Unexplained time gap before P8.** P8 started 1 h 51 min 24 s after P7 ended. The log does not give a reason.

## Model Usage

| Model tier | Concrete model | Phases used | Agent call count |
|------------|---------------|-------------|-----------------|
| Primary    | `claude-opus-5-5` | P0 to P7 for orchestration, and agents in P2, P3, P4, P5 | 23 |
| Cheaper    | `claude-sonnet-5-5` (per header) | P0, P1, P6 | 18 |
| Cheaper    | `claude-haiku-5-5` (this assessment, per session environment) | P8 | 1 |

The log records the cheaper tier for P8 without a model name, so the last row comes from the session environment.

## Skills Invoked

| Phase | Skill | Load pattern |
|-------|-------|-------------|
| P0 | planifest-orchestrator | Session start |
| P1 | planifest-spec-agent | Not recorded |
| P2 | planifest-adr-agent | Not recorded |
| P3 | planifest-codegen-agent | Not recorded |
| P4 | planifest-validate-agent | Not recorded |
| P5 | planifest-security-agent | Not recorded |
| P6 | planifest-docs-agent | Not recorded |
| P7 | planifest-ship-agent | Not recorded |
| P8 | planifest-build-assessment-agent | Not recorded |

## Subagent Dispatch

| Phase | Agent type | Count | Purpose |
|-------|-----------|-------|---------|
| P0 | planifest-scope-lock-agent | 4 | One Scope Lock draft per scenario path |
| P1 | Requirement drafting subagents (type not recorded) | 7, plus 4 resumed | Requirement drafting and fixes |
| P2 | planifest-adr-agent drafters | 3 | ADR drafting |
| P3 | Work-package agents (type not recorded) | 7 | Codegen: five in wave 1, two in wave 2 |
| P4 | planifest-validate-agent | 1 | CI and semantic checks |
| P5 | Security reviewers and fix agents (type not recorded) | 12 | Two reviewers, then fixes across three cycles |
| P6 | Living-doc subagents (type not recorded) | 3 | Documentation updates |
| P7 | None | 0 | Archive run by the ship agent |
| P8 | Build-assessment subagent | 1 | This report |

The log does not say whether the P1 cross-stream review is in the count of 7.

**Total agents spawned:** 38, plus 4 resumed, for 42 dispatches.

## Phase Timing

Wall-clock values are derived from the recorded `Start` and `End` timestamps. The log does not record them.

| Phase | Subagents | Parallel batches | Streams | Wall-clock |
|-------|-----------|------------------|---------|------------|
| P0 | 4 | 1 | not captured | 00:32:55 (includes pre-flight, including the PR #58 merge) |
| P1 | 11 | 3 | not captured | 00:17:14 |
| P2 | 3 | 1 | not captured | 00:04:26 |
| P3 | 7 | 2 | not captured | 00:25:31 |
| P4 | 1 | 1 | not captured | 00:07:23 |
| P5 | 12 | 4 | not captured | 00:41:53 |
| P6 | 3 | 1 | not captured | 00:05:47 |
| P7 | 0 | 1 | not captured | 00:17:57 |
| P8 | 1 | 0 | not captured | not captured (no `End`) |
| Total | 42 | 14 | | 02:33:06 for P0 to P7 phase time |

The gaps between phases total 00:06:29. The longest gap is 00:04:01, between P2 and P3. The pipeline ran 02:39:35 from start to P7 end.

## MCP Tool Usage

| Tool | Call count | Purpose |
|------|-----------|---------|
| None recorded | 0 | Every phase records zero MCP calls. |

## Parallel Task Bursts

| Phase | Batch count | Tasks parallelised |
|-------|------------|-------------------|
| P0 | 1 | Four scope-lock agents |
| P1 | 3 | Seven drafting agents and four resumed fix agents. The log does not map agents to batches. |
| P2 | 1 | Three ADR drafters |
| P3 | 2 | Wave 1: five work packages (WP1 to WP5). Wave 2: two packages (WP6a, WP6b). |
| P4 | 1 | One validate agent. A batch of one is not parallel. |
| P5 | 4 | Two reviewers at the start, then fix agents. The log does not map agents to batches. |
| P6 | 1 | Three living-doc subagents |
| P7 | 1 | None. Zero agents are recorded. |
| P8 | 0 | One task |

**Phases with no parallelism:** P4 (one task), P8 (one task). P7 records a batch with no agents, which is finding 6.

## Self-Corrections

| Phase | Count | Summary |
|-------|-------|---------|
| P3 | 1 | The retired integration word appeared in the new req-018 suite. The residue check caught it after wave 1. Not recorded as a self-correction. Avoidable on the evidence: the check ran only after the wave. |
| P4 | 1 | Cycle 1: req-010 AC-2 and AC-3 had no assertion, and req-009 AC-2 lacked its impact check. The suites tested term presence, not the stated behaviour. Avoidable: the acceptance criteria stated the behaviour. |

**Total self-corrections:** 2 (1 recorded in P4, 1 found in the P3 narrative).

Review-driven rework is listed under Efficiency Observations, not here. It covers the P1 review, the P2 gap, and the three P5 cycles.

## Artefact Counts

| Category | Count |
|----------|-------|
| Requirements | 18 (54 acceptance criteria) |
| New ADRs | 15 (ADR-001 to ADR-015) |
| Prior ADRs amended | 6 |
| Prior ADRs superseded | 1 (0000003-ADR-006) |
| Feature test suites at P7 | 78 |
| Regression suites at P7 | 31 (24 before P7, 7 promoted) |
| Framework files changed against `main` | 54 (3,005 insertions, 86 deletions, per P3) |
| Backlog entries picked | 11 |
| Backlog entries filed | 4 (0000120, 0000121, 0000122, 0000123) |
| Initial security findings | Script review: 2 High, 2 Medium, 4 Low. Governance review: 3 High, 4 Medium, 5 Low. |
| Security outcome at P5 exit | Overall Low, with no open Critical, High, or Medium finding |

## Efficiency Observations

- P5 is the longest phase at 00:41:53. That is about 27 percent of phase time. Three review cycles drove most of it. The first review rejected both new scripts, after P4 validation passed them.
- The log does not say whether the spec covered symbolic links or git configuration trust. Check the risk register before rating the P5 findings as avoidable.
- P1 needed a review round. The cross-stream review rejected the draft with 1 blocker, 6 major, and 12 minor findings. Four resumed agents applied the fixes.
- A P2 drafter then found that req-005 lacked D-003. The P1 review did not catch it. This gap was avoidable at P1.
- The cheaper tier handled 19 of 42 dispatches, which is 45 percent. Cheaper use was not near zero.
- The P3 deviation, in which each work-package agent ran the red, green, and refactor steps itself, has a recorded reason. The tests are Bash text assertions. Each agent still confirmed RED before GREEN.

## Critical Audit

**Model routing audit**

- The primary tier ran 23 dispatches in P2, P3, P4, and P5. P4 validation and the req-007 discovery sweep are cheaper-eligible under this audit, yet both ran on primary. Expected tier: cheaper. Actual tier: primary.
- The cheaper tier ran 19 dispatches in P0, P1, P6, and P8. Usage is not near zero, so no zero-usage flag applies.
- Tier decisions are recorded per phase, not per agent call. P0 records `primary`, yet its four scope-lock agents ran on `claude-sonnet-5-5`. This is an accountability gap.

**Parallelism audit**

- P8 is the only phase with zero batches. Its single build-assessment task needed no parallelism. This is acceptable.
- P0, P1, P2, P3, P5, and P6 record batches for multi-task work. The log does not record message boundaries, so the batch counts cannot be checked against the transcript.
- P0 recorded four agents for its four always-parallel scenario paths. P5 recorded 12 agents for two parallel reviewers and their fixes. Neither triggers a flag.
- The header has no `Parallel streams` row. The scalability check for 10 or more requirements cannot be evaluated, and the time saved by streams cannot be reported.

**Phase gate audit**

- The human chose `continuous` at P0 ("design as drafted, continuous"). That is a pre-authorisation, so gates P1 to P6 passed without stops. This is permitted.
- The human honoured the P0 gate. At P7 step 4, the human on the loop confirmed seven test candidates.
- No gate passed without its condition recorded. P5 passed with Low risk and no open Critical, High, or Medium finding.

**P0 question audit**

- P0 questions asked: 4.
- The `Brief complete` and `Stack unchanged` lines are missing. This is a build-log gap.
- The NFR-002 flag needs both lines to read `yes`. The log does not show that, so the count carries no flag.

**Self-correction audit**

- Two self-corrections occurred, and both were avoidable. P4 tested term presence where the criteria stated behaviour. P3 shipped a suite with a retired word that a later check caught.
- The three P5 cycles were review-driven fixes, not self-corrections. They appear under Efficiency Observations.

**Build log integrity**

- Every phase from P0 to P8 has an entry. P9 has no entry. P9 runs after this report, so the absence is expected. Confirm the P9 entry once the ship agent finishes.
- Model tier, agent count, MCP calls, and parallel batches are present for every phase.
- Missing fields: `Wall-clock` and `Streams` in every phase, the `Run mode` and `Parallel streams` header rows, the `End` field for P0 and P8, and the two P0 lines named in finding 5.

**Human touchpoint audit**

Not applied. The run mode is `continuous`, as `scripts/run-mode.mjs` reports for this archive.
