# Build Report (0000039-ravintio-rebrand, 25 Oct 2026)

## Headline

The run took 11 h 22 min 57 s from P0 start to P7 end. P8 was in progress when this report was written, and P9 had not started.

- **Total wall-clock:** 11 h 22 min 57 s, from `2026-10-25T01:58:32Z` to `2026-10-25T13:21:29Z`.
- **Phases:** P0 to P7 complete. P8 in progress. P9 not reached.
- **Agents spawned:** 87 across P0 to P7, and 88 with P8. The P6 breakdown is not recorded.
- **Self-corrections:** 5, all in P4. Review-driven fix loops in other phases are listed separately.
- **Human touchpoints:** 3. None fell outside the exception list.
- **Flags:** See the critical audit. The most serious are a run-mode script that reads `interactive`, two Hard Limit 8 breaches, four avoidable P4 cycles, and a P6 reopen that took about 65 percent of phase time.

## Model usage

| Model tier | Concrete model | Phases used | Agent call count |
|------------|---------------|-------------|-----------------|
| Primary | `claude-opus-5-5` | P3 (rename script author, req-006 implementer), P4 (CI fix agent), P5 (four subagents), P6 (reopened reviews, count not recorded) | 7 recorded, plus P6 not recorded |
| Cheaper | `claude-sonnet-5-5` | P0 (2 surveys, 4 Scope Lock drafts), P1, P2, P3 (17 subagents), P4 (verify-by-execution), P6 (docs and cross-model review, count not recorded) | 51 recorded, plus P6 not recorded |
| Not in header | `claude-haiku-5-5` | P8 (this report) | 1 |

## Skills invoked

P0 to P2 record the pre-rename `planifest-*` skill names. The rename landed at P3.

| Phase | Skill | Load pattern |
|-------|-------|-------------|
| P0 | planifest-orchestrator | Session start |
| P0 | Phase 0 references (`phase-0-assess-and-coach`, `adoption-modes`) | Read at P0 |
| P1 | planifest-spec-agent, planifest-design-critic, planifest-loop-runner | Phase row, no per-load record |
| P2 | planifest-adr-agent, planifest-design-critic | Phase row, no per-load record |
| P3 | planifest-codegen-agent (orchestrator), ravintio-test-writer, ravintio-implementer, ravintio-refactor | Phase row, the last three in subagents |
| P4 | ravintio-validate-agent, ravintio-verify-by-execution | Phase row, verify-by-execution in a subagent |
| P5 | ravintio-security-agent | Phase row, no per-load record |
| P6 | ravintio-docs-agent, ravintio-test-writer, ravintio-implementer, ravintio-refactor, ravintio-security-agent, ravintio-verify-by-execution, ravintio-reversal-assessor, ravintio-loop-runner | Phase row, no per-load record |
| P7 | ravintio-ship-agent | Phase row, no per-load record |
| P8 | ravintio-build-assessment-agent | Session start (this report) |

## Subagent dispatch

| Phase | Agent type | Count | Purpose |
|-------|-----------|-------|---------|
| P0 | Explore | 2 | Repository surveys |
| P0 | Scope Lock draft (type not recorded) | 4 | One draft per Scope Lock path |
| P1 | ravintio-spec-agent (drafters) | 10 | Requirement drafts |
| P1 | ravintio-design-critic | 3 | Critic iterations 1 to 3 |
| P1 | Revision agent (type not recorded) | 1 | Fixes to requirement, risk, and scope files |
| P2 | ravintio-adr-agent | 10 | ADR-001 to ADR-010 |
| P2 | ravintio-design-critic | 3 | Critic iterations 1 to 3 |
| P3 | ravintio-test-writer | 10 | RED tests, 3 in stage 1 and 7 in stage 3 |
| P3 | Rename script author (type not recorded) | 1 | Scripted rename pass |
| P3 | ravintio-implementer | 5 | GREEN |
| P3 | Suite fixer, guard finisher, version implementer (types not recorded) | 3 | Lint fixes, allowlist, version bump |
| P3 | ravintio-refactor | 1 | Refactor pass across stage 3 tracks |
| P4 | ravintio-verify-by-execution | 1 | Behavioural criteria |
| P4 | CI fix agent (type not recorded) | 1 | CI fixes |
| P5 | ravintio-security-agent | 2 | Review of the migration helpers, and of setup, hooks, and secrets |
| P5 | Fix agent (type not recorded) | 1 | Three Mediums and five Lows |
| P5 | ravintio-security-agent (re-reviewer) | 1 | Fresh-context re-review |
| P6 | Mixed (types and counts not recorded) | 29 | Reopened TDD, reviews, and docs |
| P7 | None | 0 | Ship phase ran without spawned agents |

**Total agents spawned:** 87 across P0 to P7, and 88 with P8. The P3 items total 20, but the log records 19. The P6 sub-counts for reopened work total 15, and the log does not say whether they sit inside the 29.

## Phase timing

| Phase | Subagents | Parallel batches | Streams | Wall-clock |
|-------|-----------|------------------|---------|------------|
| P0 | 6 | 2 | n/a | 14 min |
| P1 | 14 | 1 | 1 | 16 min |
| P2 | 13 | 1 | 1 | 8 min |
| P3 | 19 (20 by item count) | 3 | 1 | 79 min |
| P4 | 2 | 1 | 1 | 61 min |
| P5 | 4 | 1 | 1 | 44 min |
| P6 | 29 | 11 | 1 | 7 h 18 min 45 s (438 min) |
| P7 | 0 | 1 | 1 | 13 min |
| P8 | 1 | 0 | 1 | Pending |
| Total | 87 (P0 to P7) | 21 | | 11 h 13 min by phase sum, and 11 h 22 min 57 s from start to end |

The phase times sum to 673 min. The remaining 10 min fall between phases.

## MCP tool usage

| Tool | Call count | Purpose |
|------|-----------|---------|
| None recorded | 0 | Every phase row records 0 MCP calls |

## Parallel task bursts

| Phase | Batch count | Tasks parallelised |
|-------|------------|-------------------|
| P0 | 2 | 2 Explore surveys, and 4 Scope Lock drafts |
| P1 | 1 | 10 spec drafters |
| P2 | 1 | 10 ADR drafters |
| P3 | 3 | Stage 1: 3 test-writers and the rename script author. Stage 3: 7 test-writers, then 5 implementers |
| P4 | 1 | CI with verify-by-execution |
| P5 | 1 | Two fresh-context reviewers |
| P6 | 11 | Three docs subagents, the reopened req-002 and req-006 streams, the cross-model fixes, and the N-004 review with CI |
| P7 | 1 | Cross-reference search and regression-candidate scan |
| P8 | 0 | Single task |

**Phases with no parallelism:** P8 only. It runs one task, so this is acceptable.

## Self-corrections

| Phase | Count | Summary |
|-------|-------|---------|
| P4 | 5 | Cycle 1: merge conflict after PR #70 merged mid-run. Cycle 2: clean-clone failure from held-back files. Cycle 3: Windows CI portability, six root causes. Cycle 4: CRLF blob comparison on a Windows shard. Cycle 5: portability lint failure after a push that skipped lint |

**Total self-corrections:** 5, as recorded in the log.

The log does not label these review-driven fix loops as self-corrections:

| Phase | Loops | Summary |
|-------|-------|---------|
| P1 | 3 critic iterations | Iteration 1 rejected with 1 critical, 9 major, and 4 minor findings |
| P2 | 2 rejected critic iterations | Design conflicts on marker handling, and stale marker wording |
| P5 | Initial review and 4 rounds | Mediums, then a rerun with four High and Medium findings, then two further rounds |
| P6 | 2 cross-model cycles | Cycle 1 rejected with a High finding, X-001, because PowerShell 5.1 never ran. Defects D-1 and D-2 came from verify and review |

## Artefact counts

| Category | Count |
|----------|-------|
| Requirements | 10, with 32 criteria |
| User stories | 4 |
| ADRs | 10 (ADR-001 to ADR-010) |
| Critic iterations | P1: 3. P2: 3 |
| Test suites at P7 | 163 recorded, with 126 feature and 36 regression passing. The parts sum to 162 |
| Backlog entries filed | 19 recorded, 0000250 to 0000273 with gaps |
| Labelled deviation lines | 16 |
| Credential sightings held back | 4, across 3 files, all cleared by the human on the loop |

## Critical audit

### Model routing audit

- **Primary tier.** Recorded primary calls are the rename script author, the req-006 implementer, the CI fix agent, and the P5 reviewers. These are judgement or code-change tasks, so the tier is defensible.
- **Cheaper-eligible work on primary.** The P7 ship phase ran archiving, changelog edits, promotion, and the credential scan on the primary-tier session. These steps are mechanical. The log records the P7 tier as primary (line 344). This is a finding.
- **Cheaper tier.** The cheaper tier handled 51 recorded calls across P0 to P4 and P6. It was not near zero, so no absence flag applies.
- **Per-call tiers.** The log records tiers per phase, not per agent call. The P6 call count and tier split are not recorded. This is an accountability gap.
- **P8 tier mismatch.** The header names `claude-sonnet-5-5` as the cheaper model. The P8 row names haiku. This is a finding.
- **P6 wording.** The P6 row says "full model" without naming a model. This is a finding.

### Parallelism audit

- **Zero-batch phases.** Only P8 records zero batches, and it is a single task.
- **Multi-agent dispatch.** The log records batches for P0 to P3, P5, P6, and P7. It does not record message boundaries, so the batches are taken as recorded.
- **Always-parallel units.** P5 ran two reviewers and recorded four agents. No phase has a parallel-unit shortfall.
- **Parallel streams.** The header still reads `pending`. The P1 toggle record sets `parallel_streams` to on, and P1 chose one stream. This is a finding, because the header was not updated.
- **Independent requirements.** The header does not read `off`, so the 10-requirement flag does not apply. The requirements depended on the one rename pass, so they were not independent.
- **Stream time comparison.** Not applicable. No stream state files exist.

### Phase gate audit

- **P0.** The human on the loop confirmed the design and chose run mode 3, autonomous. The choice is pre-authorised.
- **P1 to P7.** The orchestrator recorded each gate as passed. The human on the loop acted only at the three touchpoints, which the exception list allows.
- **Skipped gates.** None. The log records no skipped phase and no `.skips` file.

### P0 question audit

- **Count.** The log records 3 P0 questions. `Brief complete` reads `no`, and `Stack unchanged` reads `yes`. The NFR-002 flag needs both to read `yes`, so no flag applies.
- **Count gap.** The log lists four P0 exchanges with a question: backlog pickup, bulk rename method, combined confirmation, and script approval. The count may be low. This is a finding.
- **Gate contradiction.** The P0 to P1 gate check says every checklist item passes, while `Brief complete` reads `no`. This is a finding for the orchestrator to reconcile.

### Self-correction audit

| Cycle | Cause | Avoidable? |
|-------|-------|-----------|
| 1 | PR #70 merged into `main` mid-run, so the draft PR conflicted | External event. Not avoidable from the spec |
| 2 | Held-back files stayed tracked at old paths, and local runs hid them | Avoidable. A clean-clone check at the P3 gate would have caught it |
| 3 | Windows CI failures from six root causes | Partly avoidable. `pwsh` was not installed locally, and Windows ran only in CI |
| 4 | Byte-identity check failed on CRLF checkouts | Avoidable. The check assumed LF blobs |
| 5 | Portability lint failed after a push that skipped lint | Avoidable. The push skipped the lint suites |

Four of the five cycles were avoidable, or partly avoidable. The P1 and P2 critic findings point to spec ambiguity. The P6 finding that the design named one marker file, not two, also points to spec ambiguity.

### Build log integrity

- **Phase coverage.** P0 to P8 have rows. P9 has no row, as expected.
- **Progress lines.** P0 to P7 have progress lines. P8 and P9 do not. This is a finding.
- **Per-phase fields.** P0 to P7 record model tier, agent count, MCP calls, batches, and wall-clock. Streams are recorded for each phase. P0 reads `n/a`.
- **Unit format.** The P6 wall-clock uses hours and minutes, while the other phases use minutes. This is a minor finding.
- **P7 agent count.** P7 records 0 spawned agents, but its tier reads "primary (ship agent)". It is unclear whether a ship agent ran. This is a finding.
- **P3 count.** The P3 items total 20, but the row records 19. This is a finding.
- **P6 breakdown.** The 29-agent count has no breakdown. This is a finding.
- **P7 suite arithmetic.** 126 feature and 36 regression suites sum to 162. The row records 163. This is a finding.
- **Backlog gaps.** The log does not mention 0000263, 0000265, 0000268, 0000269, or 0000271. Confirm whether they were reserved for this run.
- **Run mode.** The header reads `autonomous`. `run-mode.mjs` printed `interactive` on stdout for this run, and printed to stderr that the anchor is ambiguous. The cause is merge commit `1fffd812`, which changed `plan/current/build-log.md`. P7 recorded the same result. Backlog 0000273 tracks the defect. This is a finding.

### Human touchpoint audit

The run-mode script printed `interactive` for this run. This audit applied because the P0 record is `autonomous`.

| Log line | Phase | Exception item | Within list |
|----------|-------|----------------|-------------|
| 233 | P4 | Item 7, credential sighting. The human on the loop asked about the held-back file | Yes |
| 236 | P4 | Item 7, credential sighting. The human on the loop cleared the held-back files | Yes |
| 300 | P6 | Item 1, destructive change to setup marker files. The human on the loop directed a design change | Yes |

Touchpoints outside the exception list: 0.

The P6 rename also meets item 2, a gross deviation. The deviation review classes it as altering and destructive (row 12), so it stays on the list.

### Directive violations

- **Hard Limit 8, P1.** The critic revision agent edited nine `plan/current/` files with a Python one-liner. The ratchet check never ran. The orchestrator read the diff instead, which is not the same control. Backlog 0000238 tracks the case.
- **Hard Limit 8, P5.** The third re-review agent changed one line with `sed -i`. The agent reported the slip. Backlog 0000238 cites it.
- **Approved exception.** The P3 scripted rename pass ran outside the sanctioned script list. The human on the loop approved it at P0, and ADR-008 records it. This is logged and approved, so it is not a violation.

## Efficiency observations

1. **The P6 reopen took about 65 percent of phase time.** The P6 row covers 438 of 673 min. The reopen traced to a confirmed design that named one marker file, not two (lines 299 and 301). A P1 or P2 check on marker ownership would have caught it.
2. **Security review ran five passes after the initial review.** The P5 loop closed after four rounds, per the loop rules. Each round found new issues, so later rounds were smaller.
3. **Windows and PowerShell checks ran only in CI.** `pwsh` was absent locally. CI produced four fix cycles, and cross-model review then found that PowerShell 5.1 never ran (X-001). Opening the draft PR earlier would have surfaced these failures sooner.
4. **Gate-write blocked two test-writers.** The design's Scope section named paths, so the gate read them as writes. P3 added a Component Paths section as a deviation. The design template should name these paths in a section the gate does not read.
5. **Run-mode anchor.** A merge from `origin/main` into the feature branch un-anchored the autonomous run mode. Backlog 0000273 tracks the defect. Until it is fixed, merge-free branch updates avoid the problem.
