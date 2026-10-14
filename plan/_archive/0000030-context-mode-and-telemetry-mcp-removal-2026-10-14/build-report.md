# Build report (0000030-context-mode-and-telemetry-mcp-removal, 14 Oct 2026)

The run completed P0 to P7 with its gates recorded. The build log understates corrections, misstates two of its own Summary figures, and records no cheaper-tier work before P8. The P2 timestamps cannot be relied on.

## Model usage

| Model tier | Concrete model | Phases used | Agent call count |
|------------|---------------|-------------|-----------------|
| Primary | `claude-opus-5-5` (declared). Eight agents ran on sonnet and were labelled primary. | P0 to P7 | 11 (8 sonnet, 3 opus, from the phase blocks) |
| Cheaper | `claude-haiku-5-5` (declared) | P8 | 1 (this agent) |

The Summary records 7 sonnet and 4 opus. The phase blocks sum to 8 sonnet and 3 opus. This report uses the phase blocks, which hold the per-call detail.

## Skills invoked

The log records which skills each phase loaded, but not when. The load pattern is marked "Not captured" except for P0.

| Phase | Skill | Load pattern |
|-------|-------|-------------|
| P0 | planifest-orchestrator | Session start |
| P1 | planifest-spec-agent | Not captured |
| P2 | planifest-adr-agent | Not captured |
| P3 | planifest-codegen-agent | Not captured. The TDD skills (`planifest-test-writer`, `planifest-implementer`, `planifest-refactor`) were not loaded. |
| P4 | planifest-validate-agent | Not captured. `planifest-verify-by-execution` was not run (toggle off). |
| P5 | planifest-security-agent | Not captured |
| P6 | planifest-docs-agent | Not captured |
| P7 | planifest-ship-agent | Not captured |
| P8 | planifest-build-assessment-agent | Not captured |

## Subagent dispatch

| Phase | Agent type | Count | Purpose |
|-------|-----------|-------|---------|
| P0 | planifest-scope-lock-agent (sonnet) | 4 | One scope-lock draft each, dispatched in parallel |
| P1 | Spec sub-agent (sonnet) | 1 | Scope, risk register, and glossary. Agent type not named. |
| P3 | Codegen sub-agents: A (opus), B and C (sonnet) | 3 | A: setup scripts. B: non-setup deletions and existing tests. C: REQ-003 text and the refresh-setup skill edit. |
| P5 | Security reviewer and fixer (opus) | 2 | Review, then fix F1 to F5 |
| P6 | Docs sub-agent (sonnet) | 1 | Sync `src/setup-hook-integration/docs` and `component.yml`. Agent type not named. |
| P8 | Build-assessment agent (haiku) | 1 | This report |

**Total agents spawned:** 11 before P8, and 12 including this agent.

P2, P4, and P7 spawned no agents.

## MCP tool usage

| Tool | Call count | Purpose |
|------|-----------|---------|
| All MCP tools | 0 in P0 to P7 | None recorded |

The P3 notes record two telemetry fetch-failed markers during the baseline run. The log attributes them to a local MCP server that was not running. The count of 0 may undercount outbound calls. The log does not say whether those calls count as MCP calls.

## Parallel task bursts

| Phase | Batch count | Tasks parallelised |
|-------|------------|-------------------|
| P0 | 1 | Four scope-lock drafts |
| P1 | 1 | The spec sub-agent, alongside the orchestrator writing 5 requirements and the execution plan |
| P2 | 0 | None. Seven ADRs were written inline. |
| P3 | 1 | Agents A, B, and C, on disjoint file sets |
| P4 | 1 (not evidenced) | None described. No agents were spawned. |
| P5 | 1 (not a parallel burst) | Reviewer, then fixer. The fixer needed the reviewer's output. |
| P6 | 1 (single agent) | One docs sub-agent |
| P7 | 0 | Single-task phase |
| P8 | 0 | Single-task phase |

**Phases with no parallelism:** P2, P4, P5, P6, P7, and P8. P7 and P8 are single-task phases. P2, P4, and P6 need a finding, as set out below. P5 ran a dependent pair.

## Self-corrections

| Phase | Count | Summary |
|-------|-------|---------|
| P4 | 1 (recorded) | Semantic check found that req-001 AC1 and AC2, and req-002 AC1 and AC3, had no mapped test. NFR-001 had no repo-wide check. Fixed with a 15-assertion test. |
| P3 | 4 (not counted) | Agent C renamed OpenTelemetry to OTel to pass a grep, and the orchestrator reverted it. The orchestrator widened the NFR-001 allowlist. The orchestrator removed a row from this skill and removed `backendUrl` from refresh-setup. |

**Total self-corrections:** 1 recorded, and 5 when the P3 notes are counted. The P5 fixes (F1 to F5) follow the log's convention and count as findings.

## Artefact counts

| Category | Count |
|----------|-------|
| Requirements | 5 (REQ-001 to REQ-005) |
| ADRs | 7 (written inline in P2) |
| Scope lock items | 4 drafts, and 9 clarifications (A to I), all accepted |
| NFRs named in the log | 2 (NFR-001, NFR-002) |
| Security findings | 6: 0 Critical, 0 High, 2 Medium, 4 Low |
| Backlog items filed | 5 (0000087 to 0000091) |
| Backlog items discarded | 8, with 27 left untouched |
| Migration files | 1 (last P3 commit, 0e6b485) |
| Test suites at P4 and P6 | 44 feature and 14 regression, 0 failed |
| P5 fix commits | 5 |

## Critical audit

### Model routing audit

- The primary tier covered P0 to P7 in every phase block. Opus ran 3 agents, all on setup scripts or security fixes, which suits the primary tier.
- Several tasks with bounded inputs ran on the primary label. These were the four P0 scope-lock drafts, the P1 spec drafting, the P3 deletion work in agent B, and the P6 docs sync. The log gives no reason for the primary label on any of them.
- The cheaper tier ran zero calls in P0 to P7. Expected: at least the P0 and P1 drafting, the P3 deletions, and the P6 sync. Actual: none. Treat as not applied.
- The log defines two tiers. Sonnet is not one of them, yet eight agents ran on it under the primary label. The routing record cannot show which tier decision applied.
- The log names a model for each agent call in P0, P1, P3, P5, and P6. It records no tier decision or reason for any call. This is an accountability gap.

### Parallelism audit

- P2 wrote seven ADRs inline with zero parallel batches. The log cites a shared supersession list and a dependency of ADR-003 to ADR-007 on ADR-002. The shared list justifies serial edits to that list. The log does not show why ADR-003 to ADR-007 could not run as one burst after ADR-002 landed.
- P4 records one parallel batch and spawned no agents. The log names no tasks in that batch. Not evidenced, so treat as not applied.
- P5 records one batch for a reviewer and a fixer. They ran in sequence, which is correct. The batch count still counts a sequence as parallelism.
- P6 records one batch with one agent. The orchestrator also wrote `iteration-log.md` and `recommendations.md` in that phase. The log does not say whether those writes ran alongside the docs sub-agent.
- The log records batches, not dispatch messages. Single-message dispatch is evidenced for P0 by the description of the drafts. It is implied for P3. It is not evidenced for P1 or P6.

### Phase gate audit

- The P0 gate was accepted by the human at each exchange, and the scope lock was accepted in one reply. Honoured.
- The human pre-authorised a continuous run at P0 ("all the way to p9 without stopping"). The log records this in `plan/.run-mode` and `design.md`. Honoured.
- The P5 stop rule for Medium findings would have applied before fixes. The pre-authorisation covers the run, but the log records no human decision on those findings. The human should confirm this call at PR review. This is not a process violation under the stated condition.
- F6 (Low) was accepted in P5. The log does not name who accepted it.
- P4 and P7 have no gate line. The log cannot show whether their gate conditions were met. Treat this as a gap.
- P9 falls outside this report.

### Self-correction audit

- The recorded P4 correction was avoidable. The P3 tests covered setup behaviour and skill text only, so two acceptance criteria had no mapped test.
- The P3 RED step ran inline, not through `planifest-test-writer`. A test-writer dispatch checks the requirement-to-test mapping per requirement. The log does not prove that the inline path caused the gap.
- Spec ambiguity does not explain the P4 gap. The spec held five requirements, seven ADRs, and nine clarifications.
- The P3 corrections point to codegen choices that the orchestrator had to fix or record. Agent C changed a name to satisfy a grep. Agent A dropped `backendUrl` from the marker. The log does not record whether `design.md` was updated for that change before P6.

### Build log integrity

- Blocks exist for P0 to P7, and this run adds P8. P9 is not yet reached.
- Every block has all seven fields populated, except that no block records a tier decision per call.
- The P2 block was appended after the ADRs were written, as the log records. Its start and gate timestamps both read 2026-10-14T21:30:24Z. P3 started at 21:30:52Z. The log therefore implies seven ADRs in 28 seconds. The P2 timestamps cannot be relied on.
- The P3 block records `Telemetry: confirmed-disabled`. Its notes record two telemetry fetch-failed markers. The field contradicts the notes.
- The Summary disagrees with the phase blocks on tier counts (7 sonnet and 4 opus, against 8 and 3). It also omits P4 and P5 from the parallel phases, although each records a batch.
- The Summary records 1 self-correction. The P3 notes contain four further corrections that the Summary does not count.
- The Summary records 0 MCP calls. The P3 telemetry markers suggest outbound calls that the count may not include.
- P1 and P6 do not name their agent types.

## Efficiency observations

- Assumption A-002 (CI runs the setup script tests) was false. P4 found it. A read of the CI configuration in P1 would have exposed it earlier. The gap carries forward as backlog 0000091.
- Three review toggles were off: `design_critic` (P1, P2), `verify_by_execution` (P4), and `cross_model_review` (P6). The log records each as the default. No fresh-context review of the spec or ADRs ran before P3.
- Inline TDD in P3 saved dispatch overhead on deletion-heavy work, as the log states. Its cost was one P4 correction cycle. The log cannot show whether dispatched test-writers would have avoided it.
- Four pre-existing bugs were fixed in agent A's files. One pre-existing test (test-0000010) fails when run from inside `tests/` (backlog 0000089). These fixes widened the diff beyond the feature. The log does not say whether they were in scope.
- If the next run needs tier accountability, record the tier and reason for each agent call, including the cheaper tier. Count every correction in the Summary. Write each phase block at phase start, not after.
