# Build Report (0000031-ci-test-and-powershell-coverage, 16 Oct 2026)

## Model Usage

| Model tier | Concrete model | Phases used | Agent call count |
|------------|---------------|-------------|-----------------|
| Primary    | `claude-opus-5-5` | P0 (orchestration), P1, P2, P3 (orchestration), P4, P5, P6, P7 | 0 |
| Cheaper    | `sonnet` (P3 and summary rows). The log header names `claude-haiku-5-5`. | P0 (Scope Lock drafters, per summary), P3 (TDD agents), P8 (this run) | 7 through P7, plus 1 for P8 |

The concrete cheaper model is inconsistent across the log. See Build log integrity below.

## Skills Invoked

| Phase | Skill | Load pattern |
|-------|-------|-------------|
| P0    | planifest-orchestrator | Session start |
| P0    | planifest-scope-lock-agent (inferred, not named in the log) | Dispatched per Scope Lock item |
| P1    | planifest-spec-agent | Phase start, run inline (0 agents) |
| P2    | planifest-adr-agent | Phase start, run inline (0 agents) |
| P3    | planifest-codegen-agent | Phase start |
| P3    | TDD sub-skills | Not recorded |
| P4    | planifest-validate-agent | Phase start |
| P4    | planifest-verify-by-execution | Phase start |
| P5    | planifest-security-agent | Phase start, run inline (0 agents) |
| P6    | planifest-docs-agent | Phase start, run inline (0 agents) |
| P7    | planifest-ship-agent | Phase start |
| P8    | planifest-build-assessment-agent | Phase start (this run) |

## Subagent Dispatch

| Phase | Agent type | Count | Purpose |
|-------|-----------|-------|---------|
| P0    | Scope Lock drafter | 4 | One suggested answer per Scope Lock item. Recorded in the summary only. The P0 row records 0. |
| P3    | TDD agent (sonnet) | 3 | One agent for REQ-002, one for REQ-004, and one for REQ-001 and REQ-003 in turn. |
| P8    | Build assessment agent | 1 | This report. |

**Total agents spawned:** 8 (7 through P7 per the summary, plus this run)

## MCP Tool Usage

| Tool | Call count | Purpose |
|------|-----------|---------|
| None recorded | 0 | Every phase row records 0 MCP calls. |

The log does not record Bash or `gh` calls. The P4 CI checks are therefore not counted anywhere.

## Parallel Task Bursts

| Phase | Batch count | Tasks parallelised |
|-------|------------|-------------------|
| P0    | 1 (summary only) | Four Scope Lock drafters. The P0 row records 0 batches. |
| P3    | 1 | Three TDD agents: REQ-002 (`run-tests.sh`), REQ-004 (`test_setup.ps1`), and REQ-001 with REQ-003 (`.github/workflows/planifest.yml`). |

**Phases with no parallelism:** P1, P2, P4, P5, P7. P6 records a reason for running inline. The other phases record none.

## Self-Corrections

| Phase | Count | Summary |
|-------|-------|---------|
| P4    | 2 | Cycle 1: CI failed on `test-0000030-req-001-002-removed-files-and-residue.sh`, which expected 0.29.0 after the bump to 0.30.0. Cycle 2: REQ-004 criterion 2 had static coverage only. |

**Total self-corrections:** 2

## Artefact Counts

| Category | Count |
|----------|-------|
| Requirements | 4 |
| Acceptance criteria | 12 (final, per the P4 table) |
| ADRs | 3 |
| Framework component version bumps | 1 (0.30.0) |
| Local test suites at P3 | 47 feature, 14 regression (baseline 44 and 14) |
| CI runs | 2 (`38944104004` red, `38944916328` green) |
| CI jobs in the final run | 3 (Linux, macOS, Windows) |
| Commits recorded at P3 | 3 |
| Docs files updated at P6 | 4, plus `iteration-log.md` and the `src/setup-hook-integration` docs and `component.yml` |
| Backlog entries filed | 3 (0000092 to 0000094) |
| Backlog entries picked up | 2 (0000091, 0000050) |
| Security findings | 5 low, 0 medium or higher |

## Efficiency Observations

### Phase timings

| Phase | Duration | Notes |
|-------|----------|-------|
| P0 | Not measured | Human-paced, from 2026-10-14T23:21:04Z to 2026-10-16T17:52:23Z. Excluded from agent efficiency. |
| P1 | 1m 44s | |
| P2 | 41s | |
| P3 | 5m 46s | |
| P4 | 11m 26s | Largest recorded phase. CI wait is included, and the log does not split it out. |
| P5 | 24s | No agent call. The log does not list what the review covered. |
| P6 | 2m 09s | |
| P7 | 13s to P8 start | No end timestamp recorded. |

### Model routing audit

- Primary tier ran P0, P1, P2, P4, P5, P6, and P7 with zero agent calls. The log records no cheaper-tier use for those phases.
- P7 is archive work. It is cheaper-tier eligible, and the log does not explain why primary tier ran it.
- P4 mixes CI status reads, which are cheaper-tier eligible, with the semantic coverage fix, which is not. The log does not separate them.
- P1, P2, P5, and P6 involve judgement. Primary tier is defensible for those phases.
- Cheaper tier was used at P3 and, per the summary, for the P0 drafters. Use is not zero.
- Model tier is recorded per phase, not per agent call. The log is sparse here. This is an accountability gap.

### Parallelism audit

- P2 produced three ADRs with zero parallel batches. Each ADR is a separate decision. The log does not show that parallel dispatch was considered. This is a finding.
- P1 produced four requirements and several artefacts inline with zero batches. The log does not state whether those units were independent. This is a lower-severity finding.
- P0 shows parallel dispatch in the summary but zero batches in the P0 row. See Build log integrity.
- P3 is the only phase with a recorded parallel batch. It grouped REQ-001 and REQ-003 into one agent because both edit the same workflow file. That grouping is sound.

### Phase gate audit

- The human set continuous run at P0. The log records that answer, so the pre-authorisation is evidenced. Gates from P1 to P7 are honoured under it.
- The human confirmed the design at P0 end, at 2026-10-16T17:52:23Z.
- The P5 result says "The P5 exception applies." The log does not define that exception. This report did not check the orchestrator skill for it. The gate passed on an undefined basis.
- P6 Gate B was auto-accepted under continuous run. The log does not state whether continuous run covers auto-accepting documentation changes. This is a low-severity finding.
- CI was red twice at P4. Both failures were fixed, and the final run passed. No gate was skipped.

### Self-correction audit

- Cycle 1 was avoidable. The P3 agents ran the suite before the version bump, so the final state was not tested locally. The 0000030 test also hard-coded the version. Running the suite after the bump would have caught it.
- Cycle 2 was avoidable. REQ-004 criterion 2 requires broken markers to be rejected, which is a behaviour. The red phase wrote static tests only. The log records no check that the test type matched the criterion.
- The local PowerShell gap explains why cycle 2 surfaced late. It does not explain why the gap occurred.

### Build log integrity

- P0 row: `Agents spawned` is 0 and `Parallel task batches` is 0. The summary records four Scope Lock drafters and parallel dispatch. Correct the P0 row.
- P0 drafters: the skill name and model tier are not recorded.
- Cheaper model: the header names `claude-haiku-5-5`. The P3 row and the summary name `sonnet`. The log does not show which model ran.
- Acceptance criteria: P1 records 12. P2 merges two of REQ-001's four criteria, which gives 11. The P4 table lists 12, with REQ-001 at 3. The log does not reconcile the pre-merge total.
- P5: the exception is undefined, and the review scope is not listed.
- P7: the start is recorded, and the end timestamp is missing.
- Per-agent model tiers are not recorded.
- Every phase from P0 to P8 is represented. All fields are populated except the P7 end time.

**Open at P8:** NFR-002 (two consecutive green runs) is planned as a re-run on the final commit before P9. The log does not record it as done.
