# Build Report (0000032-governance-continuity-and-write-gate-scope, 19 Oct 2026)

Source: `build-log.md` in this archive folder, as read on 2026-10-19. The P8 block in that log is uncommitted at the time of this run. No other artifact was changed.

## Summary

- The run completed P0 to P8 with a continuous-run authorisation from the human at P0. The human stopped the run at the P5 gate and made three decisions there.
- Model routing and parallelism are only partly evidenced. Every phase from P0 to P7 ran on the primary tier, and the cheaper tier appears only in P8.
- Eleven self-corrections and three remediation cycles occurred. Most of them trace to spec gaps and to test or doc drift that earlier checks should have caught.

## Model Usage

| Model tier | Concrete model | Phases used | Agent call count |
|------------|---------------|-------------|-----------------|
| Primary    | claude-opus-5-5 (per log header) | P0, P1, P2, P3, P4, P5, P6, P7 | 18 recorded (undercount, see Build log integrity) |
| Cheaper    | claude-haiku-5-5 (per log header) | P8 | 1 |

The log records the tier per phase, not per agent call. The concrete model for the resumed P7 session (aad05653) is not recorded.

## Skills Invoked

| Phase | Skill | Load pattern |
|-------|-------|-------------|
| P0 | planifest-orchestrator | Session start |
| P1 | planifest-spec-agent | Phase entry |
| P2 | planifest-adr-agent | Phase entry |
| P3 | planifest-codegen-agent | Phase entry |
| P3 | planifest-test-writer | Per requirement, inline |
| P3 | planifest-implementer | Per requirement, inline |
| P3 | planifest-refactor | Per requirement, inline |
| P4 | planifest-validate-agent | Phase entry |
| P5 | planifest-security-agent | Phase entry |
| P6 | planifest-docs-agent | Phase entry |
| P7 | planifest-ship-agent (0.31.0 source copy) | Resumed in a new session |
| P8 | planifest-build-assessment-agent | Phase entry |

The P4 entry does not record a `planifest-verify-by-execution` pass. The validate-agent loads that skill after CI passes, so the pass is not evidenced.

## Subagent Dispatch

| Phase | Agent type | Count | Purpose |
|-------|-----------|-------|---------|
| P0 | Scope-lock draft agent | 4 | One draft per scope-lock item, run in parallel |
| P1 | Spec agent | 3 | Requirements, execution plan, and supporting artifacts |
| P2 | ADR agent | 2 | Run lifecycle stream and write-gate stream |
| P3 | Codegen stream agent | 4 | Streams A, B, B2, and C, split by file ownership |
| P4 | Validate agent | 1 | Semantic coverage check, alongside inline syntax and CI checks |
| P5 | Security review agent | 2 | Hook threat model, then setup, skill, secrets, and risk cross-check |
| P6 | Docs agent | 2 | Living docs and component docs, then recommendations, iteration log, and changelog |
| P7 | None | 0 | Archive run inline |
| P8 | Build assessment agent | 1 | This report |

**Total agents spawned:** 19 recorded. The P3 inline TDD skills and the two P5 fix streams are not counted, so the true count is higher.

## MCP Tool Usage

| Tool | Call count | Purpose |
|------|-----------|---------|
| None recorded | 0 | Every phase logs 0 MCP calls |

## Parallel Task Bursts

| Phase | Batch count | Tasks parallelised |
|-------|------------|-------------------|
| P0 | 1 | Four scope-lock draft agents |
| P1 | 1 | Three spec agents |
| P2 | 1 | Two ADR streams |
| P3 | 2 | Batch 1: streams A and B. Batch 2: streams B2 and C |
| P4 | 1 | Semantic coverage agent, syntax checks, and CI status check |
| P5 | 1 | Two review agents. The two fix streams (hooks and skills) are not logged as a batch |
| P6 | 1 | Two docs agents |
| P7 | 0 | None |
| P8 | 0 | Single task |

**Phases with no parallelism:** P7 (four tasks ran in sequence), P8 (single task, acceptable).

## Self-Corrections

Self-correction here means the agent changed its own output without a new human decision.

| Phase | Count | Summary |
|-------|-------|---------|
| P3 | 3 | Source-text checks in three suites retargeted from `gate-write.mjs` to `path-rules.mjs`. Two suites updated for new marker timing. One wrong assertion in test-0000030 fixed |
| P4 | 3 | Two semantic coverage gaps closed (a `planifest-framework/`-only root fixture, and a P7 range check). One em dash removed |
| P6 | 5 | Documentation drift fixed: glossary, risk register, ADR-004 note, build-log title, and the setup test-coverage line |

**Total self-corrections:** 11

**Remediation cycles and human-directed changes (not counted above):**

| Phase | Count | Summary |
|-------|-------|---------|
| P1 | 2 | Human-approved requirement changes to root lookup (req-003) and literal-prefix judging (req-004) |
| P2 | 1 | Human-approved split of four requirements into twelve after a failed consistency check. Re-run from P1 requirements |
| P4 | 2 | Re-runs of the consistency check and test suites after fixes |
| P5 | 3 | Fix rounds driven by security findings. Re-review 1 found five new Medium findings. Re-review 2 stopped early when a safety classifier halted the reviewer. Re-review 3 found two more Medium findings (G-1 and G-2) |

### Avoidability

| Phase | Assessment |
|-------|-----------|
| P3 | Partly avoidable. The retargets followed from moving rules into `path-rules.mjs`, which the spec did not name as a test target. The `test-0000030` assertion was a plain error and was avoidable |
| P4 | Avoidable. The test-writer did not cover the `planifest-framework/`-only root case or the full P7 range. The em dash broke a style rule already in the project instructions |
| P5 | Partly avoidable. The first threat model did not cover `cd` forms. The reviewer found them in later rounds |
| P6 | Avoidable. The docs drift should have been caught by a consistency check before P6 closed |

## Artefact Counts

| Category | Count |
|----------|-------|
| Brief acceptance criteria (AC-1 to AC-11) | 11 |
| User stories | 4 |
| Requirements (4 at P1, 12 after the P2 split) | 12 |
| Requirement-level acceptance criteria | 36 |
| ADRs (ADR-001 to ADR-006) | 6 |
| Execution plan defaults (A-003 to A-008) | 6 |
| Scope-lock flags raised | 14 |
| Test suites (59 feature, 14 regression) | 73 |
| Regression pack tests (10 promoted from this feature) | 24 |
| Security findings at P5 (initial review) | 5 Medium, 17 Low |
| Migrations (0.31.0, req-011) | 1 |
| Backlog items filed by this run | 22 (0000095 to 0000098, 0000102 to 0000119) |

Backlog 0000099 to 0000101 are not counted. They come from other sessions.

## Efficiency Observations

### Model routing audit

- **Primary tier, phases P0 to P7.** No phase records a routing decision. The log does not show that any task was sent to the cheaper tier.
- **Cheaper-tier eligible tasks on the primary tier.** The P4 semantic coverage agent and the P6 recommendations, iteration log, and changelog work fit the cheaper-tier criteria in this skill. Both ran on the primary tier. The P0 scope-lock drafts are borderline, because they call for judgement.
- **Cheaper tier usage.** Zero phases before P8. Expected: some share in P4 and P6. Actual: none. This is a finding.
- **Accountability.** The log records a tier per phase, not per agent call. The model for each call cannot be checked from the log. This is a finding.

### Parallelism audit

- **Recorded batches.** P0 to P6 each record at least one parallel batch. The batch counts are consistent with the agent counts in those phases.
- **Message-level evidence.** The log does not record whether the Agent calls in a batch shared one message. Treat parallelism as evidenced by the batch count only.
- **P7 (zero batches, four tasks).** The cross-reference check, regression confirmation, test report, and archive move are not recorded as parallel. The cross-reference check and test report were independent. This is a finding, rated Low.
- **P3 stream order.** Requirements within one stream ran in sequence. The log says those requirements shared files, so sequential runs were justified.

### Phase gate audit

- **P0.** The human confirmed the design and set the run to continuous. This is the pre-authorisation for later transitions.
- **P1 to P4 and P6.** Transitions ran without a recorded gate line. The continuous-run authorisation covers them. This is acceptable.
- **P5.** The gate held. The human made three decisions, and the log records each one.
- **P6 Gate B.** The docs update assessment was auto-accepted under the continuous run. This is within the authorisation, but it sits at the edge of it. Rated Low.
- **Design decisions A-007 and A-008 (P1).** The orchestrator applied these on its own recommendation during the continuous run. The log does not record human confirmation for either decision. This is a finding.
- **A-003 reconfirmation.** The P5 round 2 wording change is flagged for reconfirmation at P9. The log does not record that reconfirmation. This is an open item.
- **P7 session break.** P7 resumed in a new session. The log does not record the model for the resumed session. The ship-agent ran from the 0.31.0 source copy because the installed copy is 0.30.0. That deviation is logged.

### Self-correction audit

- Eleven self-corrections and three remediation cycles occurred. The P5 cycles were the largest, with three fix rounds and two partial re-reviews.
- The P2 requirement split is the largest structural rework. The spec produced requirements above the criteria limit, and the consistency check caught it at P2.
- The P5 reviewer stopped mid-search, and the team verified the remaining items by scripted exit-code checks. Coverage of those items rests on the scripts.

### Build log integrity

- **Phases represented.** P0 to P8 are present. P9 is absent, as expected, because P8 runs before P9.
- **Fields populated.** Every phase from P0 to P8 has a tier, skill list, agent count, MCP count, and batch count.
- **Undercounted agents.** The P5 agent count excludes the two fix streams. The P3 count excludes the inline TDD skills. The P5 batch count excludes the fix streams.
- **Timestamps.** The P7 end and P8 start entries use dates without times.
- **Gate records.** Only P0 and P6 have explicit gate lines. P1 to P5 rely on the continuous-run note.
- **Header.** The feature ID still reads "slug pending" in the header, although the archive folder carries the slug.
- **Uncommitted state.** The build log has uncommitted edits in the working tree. These include the P8 block.

### What went well

- P3 ran four file-owned streams with no conflicts. Each requirement reached RED then GREEN on the first attempt, except where recorded.
- P4 validation ran three checks in parallel and found real gaps.
- P5 found Medium issues that a later round then closed. Scripted checks verified the final state.
- The regression pack passed in full at P7.

### Recommended follow-up

- Record the tier and model for each agent call.
- Add a consistency check before P6 so docs drift is caught earlier.
- Require a spec test list for every file the spec names as a rule owner.
- Log subagents launched by fix streams and inline skills.
- Record the human confirmation for A-007 and A-008, and reconfirm A-003 at P9.
