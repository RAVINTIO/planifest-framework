# Build report (0000035-write-gate-scope-and-path-hardening, 22 Oct 2026)

## Headline figures

- Subagents spawned in P0 to P6: 49. P7 is pending in the log.
- Parallel task batches in P0 to P6: 12. Every phase from P0 to P6 recorded parallel work.
- Self-corrections: 1 (P4). Review-driven rework rounds: 7 (P1, P2, P5, P6).
- Recorded wall-clock for P0 to P6: 35,033 seconds (9 hours, 43 minutes, 53 seconds). The P0 value does not match its own start and end times.
- Exceptions waiting for the human on the loop: 11.
- Human touchpoints: 2. One sits outside the exception list.
- Run mode: `autonomous`, confirmed by `run-mode.mjs`.
- Build log integrity: several fields need correcting, listed below. Two need a human check.

## Model usage

| Model tier | Concrete model | Phases used | Agent call count |
|------------|---------------|-------------|-----------------|
| Primary | claude-opus-5-5 | P0, P1 (stream 01), P2 to P7 | 43 at most |
| Cheaper | claude-sonnet-5-5 | P0 (scope-lock drafts), P1 (streams 02 and 03), P6 (cross-model review) | At least 6 |
| Cheaper (this phase) | claude-haiku-5-5 | P8 | 1 (this call, not in the P0 to P6 total) |

The log records the model tier once per phase, not per agent call. The primary count is an upper bound. The cheaper-tier calls in P1 are not counted.

## Skills invoked

| Phase | Skill | Load pattern |
|-------|-------|-------------|
| P0 | planifest-orchestrator | Session start |
| P1 | planifest-spec-agent, planifest-loop-runner | Phase entry and loop entry |
| P2 | planifest-adr-agent, planifest-loop-runner | Phase entry and loop entry |
| P3 | planifest-codegen-agent | Phase entry |
| P4 | planifest-validate-agent, planifest-verify-by-execution | Phase entry |
| P5 | planifest-security-agent | Phase entry |
| P6 | planifest-docs-agent, planifest-reversal-assessor, planifest-loop-runner | Phase entry and loop entry |
| P7 | planifest-ship-agent | Phase entry |
| P8 | planifest-build-assessment-agent | Phase entry |

The log records skills per phase, not per load. The load patterns above are inferred from the phase entries.

## Subagent dispatch

| Phase | Agent type | Count | Purpose |
|-------|-----------|-------|---------|
| P0 | planifest-scope-lock-agent | 4 | One Scope Lock draft per item, in one parallel batch |
| P1 | Spec, shared-artifact, critic and fix agents | 13 | Three stream spec agents, one shared-artifact agent, design critic rounds, fix agents |
| P2 | ADR, critic and fix agents | 9 | One ADR agent per stream, critic rounds, fix agent |
| P3 | planifest-codegen-agent | 3 | One codegen agent per stream |
| P4 | planifest-validate-agent, planifest-verify-by-execution | 2 | Semantic coverage and verification by execution |
| P5 | Security reviewers, fix agents, re-reviewers | 11 | Two reviewers, fix batches, re-review rounds |
| P6 | planifest-docs-agent, cross-model reviewer, reversal assessor | 7 | Three docs agents, cross-model review on two iterations, deviation review |
| P7 | planifest-ship-agent | Pending | Not recorded |

**Total agents spawned:** 49 (P0 to P6). The log does not itemise agent types for P1, P2, P5 and P6.

## Phase timing

| Phase | Subagents | Parallel batches | Streams | Wall-clock (seconds) |
|-------|-----------|------------------|---------|------------|
| P0 | 4 | 1 | n/a | 1448 (does not match start and end, see integrity) |
| P1 | 13 | 2 | 3 | 22200 |
| P2 | 9 | 1 | 3 | 1567 |
| P3 | 3 | 1 | 3 | 1813 |
| P4 | 2 | 1 | n/a | 858 |
| P5 | 11 | 5 | n/a | 4056 |
| P6 | 7 | 1 | n/a | 3091 |
| P7 | Pending | Pending | n/a | Pending (the progress line implies about 371 seconds) |
| Total | 49 | 12 | | 35033 (P0 to P6, as recorded) |

P1 accounts for 63 percent of the recorded P0 to P6 time.

## MCP tool usage

| Tool | Call count | Purpose |
|------|-----------|---------|
| None recorded | 0 | The log records zero MCP calls in P0 to P6. P7 is pending. |

## Parallel task bursts

| Phase | Batch count | Tasks parallelised |
|-------|------------|-------------------|
| P0 | 1 | Four Scope Lock drafts |
| P1 | 2 | Three stream spec agents and one shared-artifact agent, then fix agents split by file ownership |
| P2 | 1 | Three ADR agents, one per stream |
| P3 | 1 | Three codegen agents, one per stream |
| P4 | 1 | Semantic coverage and verification by execution |
| P5 | 5 | Two reviewers, fix agents, second-batch fix agents, re-review agents |
| P6 | 1 | Three docs agents |

**Phases with no parallelism:** none in P0 to P6. P7 is not recorded.

## Self-corrections

| Phase | Count | Summary |
|-------|-------|---------|
| P4 | 1 | Validate-agent cycle 1 of 5. A test bug let a non-string stdin cwd fall back to `process.cwd()`. |

**Total self-corrections:** 1

### Review-driven rework

| Phase | Rounds | Summary |
|-------|--------|---------|
| P1 | 3 | The design critic rejected approach 1 on iterations 1 to 3. Iteration 1 found 1 critical and 4 major findings. Approach 2 then passed. |
| P2 | 1 | The design critic rejected iteration 1 (1 major, 8 minor). The major finding was a criteria-limit change with no ADR. |
| P5 | 2 | Two fix batches followed the security review. The log counts 19 findings fixed across both batches. |
| P6 | 1 | The cross-model reviewer rejected iteration 1 (8 minor). |

**Total review-driven rework rounds:** 7

## Artefact counts

| Category | Count |
|----------|-------|
| Requirements | 10 |
| User stories | 10 |
| Architecture decision records | 16 |
| Streams | 3 |
| Backlog entries filed during the run | 27 (counted from the phase entries, including 0000147, which a later fix closed and removed) |
| Exceptions waiting for the human on the loop | 11 (3 from P3, 8 from P6) |
| Migrations in scope | 8 (5 outcome records written) |

## Efficiency observations

- P1 took 22,200 seconds, or 63 percent of the recorded P0 to P6 time. Three rejected rounds on approach 1 drove most of the rework. The log does not time each round.
- P5 found two High bypasses in the gate code (G-S01 and G-S02) after the P3 suites passed. The P1 criteria did not name the path forms behind them. A path-form case list at P1 would have caught both.
- Several rework items trace to spec gaps: a missing `README.md` path in `design.md` (P3), criteria over the template limit (P1), a missing story split (P2), and a missing ADR (P2).
- Three streams ran in parallel in P1 to P3. The stream state files hold phase history. The header row still reads `pending`, so the parallel wall-clock comparison did not run.
- Cheaper-tier routing covered scope-lock drafts, shared artifacts and cross-model review. Validation work in P4 and the mechanical archive steps in P7 ran on the primary tier. These are candidates for the cheaper tier.

## Critical audit

### Model routing audit

- Primary tier: P0 orchestrator, P1 stream 01, P2 to P5, P6 docs agents, and P7.
- Cheaper-eligible work on the primary tier: P4 validation and semantic coverage, P6 documentation drift checks, and P7 archive steps.
- Cheaper tier: P0 (four drafts), P1 streams 02 and 03, and P6 cross-model review. The cheaper tier was not unused, so no zero-usage flag applies.
- Accountability gap: the model tier is recorded per phase, not per agent call. For 49 spawned agents, the per-call tier is absent. Flagged.
- P8 records `claude-haiku-5-5` as the cheaper tier. The header names `claude-sonnet-5-5`. The header or the P8 entry needs aligning.

### Parallelism audit

- Phases with zero parallel batches: none in P0 to P6.
- Every phase with multiple tasks recorded them in a batch. No phase with two or more always-parallel units recorded fewer than two subagents.
- The run has 10 requirements. The rule for 10 or more independent requirements applies only when the header reads `off`. The header reads `pending`, so no flag applies. Resolve the header row.

### Phase gate audit

- The human chose autonomous mode at P0. That choice pre-authorised the run.
- The gates from P1 to P7 passed without a human confirmation, as autonomous mode allows.
- The P6 gate line reads "continuous run, auto-accepted", while the header reads `autonomous`. Correct the label.
- Process violation: at P1, a fix agent wrote four plan artefacts through a Python script. That breaks Hard Limit 8. The orchestrator checked the diff by hand. The log records the breach as a deviation. No further action is recorded.

### P0 question audit

- P0 questions asked: 7.
- Brief complete: `no`. Stack unchanged: `yes`.
- No flag. The count above 3 applies only when `Brief complete` reads `yes`.

### Self-correction audit

- P4 self-correction: avoidable. The fault sat in the test, not the code.
- The seven rework rounds carry three causes in the log: spec and ADR gaps (P1 and P2), a gate criteria set that missed path forms (P5), and a documentation mismatch (P6). The log does not name the causes of the P1 rejections in detail.

### Build log integrity

- All phases P0 to P7 have entries and progress lines. P8 is in progress and P9 has not run, so their progress lines are not yet due.
- P0 wall-clock is 1448. The start (2026-10-20T23:28:28Z) and end (2026-10-21T23:37:01Z) span 86,913 seconds. The log does not say whether the field counts active time. Confirm which.
- P7 `End`, `Wall-clock`, `Agents spawned` and `Parallel task batches` still read `pending`. The P7 progress line gives 2026-10-22T09:20:11Z, so `End` can be filled in.
- The header `Parallel streams` row reads `pending`. The P1 toggle record reads `on`.
- The P3 skills field lists only `planifest-codegen-agent`. The RED and GREEN results for each requirement are recorded, but the TDD skills that produced them are not.
- The deviation counts in the P6 entry total 42 (34 additive, 5 altering, 1 schema, 2 destructive). The entry states 39 rows. Check the counts against `deviation-review.md`.
- P0 and P6 refer to eight migrations and eight records. P3 records five outcomes. The log does not record outcomes for the other three.

### Human touchpoint audit (autonomous)

- Run mode confirmed as `autonomous`. This audit applies.
- Two `Human touchpoint` lines exist (build log lines 122 and 126).
- Line 122 is tagged `[outside list]`. It asks for a `.ratchet-approve` line to fold req-002 back to three criteria. Flagged.
- Line 126 records the resolution of the same touchpoint. It carries no tag. The exception list is not in the log, so the line cannot be classed. Flagged for the human to check.
