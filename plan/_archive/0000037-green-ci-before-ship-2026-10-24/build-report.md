# Build Report (0000037-green-ci-before-ship, 24 Oct 2026)

## Headline findings

- The run had one human touchpoint, and it falls outside the exception list.
- Hard Limit 8 (Write or Edit only) was breached four times across P2 and P5. One more attempt was blocked in P3.
- The primary tier handled 55 of 67 documented agent calls. The cheaper tier handled 10. Two agent calls have no recorded tier.
- P6 ran on `claude-sonnet-5-5` but logs its tier as primary.
- The Header row `Parallel streams` still reads `pending`. Per-stream time savings are not captured.

## Model usage

The concrete models come from the Header: primary `claude-opus-5-5`, cheaper `claude-sonnet-5-5`. The log records no concrete model per agent call, so the tier is the only routing record.

| Model tier | Concrete model | Phases used | Agent call count |
|------------|---------------|-------------|-----------------|
| Primary | `claude-opus-5-5` per the Header. P6 docs, migration, and fixes ran on `claude-sonnet-5-5` and are logged as primary. | P1, P2, P3, P4 (verify by execution), P5, P6 | 55 |
| Cheaper | `claude-sonnet-5-5` | P0, P1, P4 (semantic coverage), P8 | 10 |
| Not recorded | Not captured | P1 (two fix agents) | 2 |

## Skills invoked

| Phase | Skill | Load pattern |
|-------|-------|-------------|
| P0 | planifest-orchestrator | Session start |
| P1 | planifest-spec-agent, planifest-loop-runner, planifest-design-critic | Not captured |
| P2 | planifest-adr-agent, planifest-loop-runner, planifest-design-critic | Not captured |
| P3 | planifest-codegen-agent, planifest-test-writer, planifest-implementer, planifest-refactor | Not captured |
| P4 | planifest-validate-agent, planifest-verify-by-execution | Not captured. The verify skill loads after CI passes. |
| P5 | planifest-security-agent, planifest-codegen-agent | Not captured |
| P6 | planifest-docs-agent, planifest-reversal-assessor, planifest-loop-runner | Not captured |
| P7 | planifest-ship-agent | Not captured |
| P8 | planifest-build-assessment-agent | Not captured |

## Subagent dispatch

| Phase | Agent type | Count | Purpose |
|-------|-----------|-------|---------|
| P0 | planifest-scope-lock-agent (cheaper tier) | 4 | One Scope Lock draft per item |
| P1 | Spec agents (four streams and one shared-artefact agent) | 5 | Requirements and shared artefacts |
| P1 | Design critic | 4 | Critic iterations |
| P1 | Fix agents | 9 | Findings fixed by file owner |
| P2 | ADR agents | 4 | One per stream |
| P2 | Design critic | 3 | Critic iterations |
| P3 | Codegen stream agents (W1 to W6, with W2b, W4b, and W5a to W5d) | 11 | Build each requirement |
| P4 | Validate agent and verify-by-execution agent | 2 | Coverage and execution checks |
| P5 | Security reviewers | 2 | Credential surface and CI surface |
| P5 | Re-reviewers | 6 | Fresh-context re-reviews |
| P5 | Fix agents | 8 | Review findings |
| P6 | Docs agents | 3 | Living docs, recommendations, and migration |
| P6 | Reversal assessor | 1 | Deviation review |
| P6 | Cross-model reviewers | 2 | Review on `claude-opus-5-5` |
| P6 | Fix agents | 2 | Review findings |
| P7 | None | 0 | Script-driven |
| P8 | Build assessment agent | 1 | This report |

**Total agents spawned:** 67

## Phase timing

| Phase | Subagents | Parallel batches | Streams | Wall-clock (minutes) |
|-------|-----------|------------------|---------|------------|
| P0 | 4 | 1 | n/a | 15 |
| P1 | 18 | 3 | 4 | 45 |
| P2 | 7 | 1 | 4 | 10 |
| P3 | 11 | 3 (see audit) | 4 | 111 |
| P4 | 2 | 1 | n/a (joined) | 25 |
| P5 | 16 | 3 | n/a (joined) | 94 |
| P6 | 8 | 3 | n/a (joined) | 397 (includes a human pause, duration not captured) |
| P7 | 0 | 1 | n/a | 3 |
| P8 | 1 | 0 | n/a | Pending (this report) |
| Total | 67 | 16 | | 700 recorded. The run took 707 minutes from pipeline start to the end of P7. |

## MCP tool usage

| Tool | Call count | Purpose |
|------|-----------|---------|
| None recorded | 0 | Every phase block records `MCP calls: 0`. |

## Parallel task bursts

| Phase | Batch count | Tasks parallelised |
|-------|------------|-------------------|
| P0 | 1 | Four Scope Lock drafts |
| P1 | 3 | Four stream spec agents and one shared-artefact agent in one batch. Fix agents in later batches, by file owner. |
| P2 | 1 | Four ADR stream agents |
| P3 | 3 recorded, at least 4 described | Batch 1: W1 to W4. Batch 2: W2b and the Git Bash fixes. Batch 3: W4b. Batch 4: W5a to W5d. W6 follows. |
| P4 | 1 | Validate agent and verify agent, run in sequence by design |
| P5 | 3 | Two reviewers, then fix batches. Re-reviews run in sequence as the loop requires. |
| P6 | 3 | Deviation review and cross-model review, then three docs agents, then fix agents |
| P7 | 1 | None. Script-driven. |

**Phases with no parallelism:** P4 (verify runs after validate by design) and P7 (no subagents). P8 has one agent, so parallelism does not apply.

## Self-corrections

| Phase | Count | Summary |
|-------|-------|---------|
| P4 | 2 | Cycle 1: three uncovered criteria. No suite asserted the held-back clean-tree listing. Cycle 2: the real `gh pr checks` prints no JSON when no checks register. The P3 stub returned JSON. |
| P6 | 1 | Revalidation cycle 1: the new `quirks.md` text named a retired flag. |

**Total self-corrections:** 3

Review rejections are separate from self-corrections. Reviewers rejected drafts ten times: P1 three, P2 two, P5 four, and P6 one.

## Artefact counts

| Category | Count |
|----------|-------|
| Requirements | 11 (req-001 to req-011) |
| User stories | 11 |
| ADRs | 14 |
| Acceptance criteria | 33 |
| Risks | 24 (P1 gate summary). The shared-artefact return named 22. |
| Glossary terms | 31 |
| In-scope items | 11 |
| Backlog entries recorded as filed | 25 (two of them, 0000193 and 0000199, deferred) |
| Test suites at close | 142 |
| CI checks at close | 13 |
| Migrations | 1 (`migrate-0.35.0-rerun-setup.md`) |
| Recommendations | 12 (REC-001 to REC-012) |
| Archived items | 37 |

## Critical audit

### Model routing audit

- The primary tier took 55 of 67 documented calls. Those calls covered the spec, critics, codegen, security, and reviews, which fits the work.
- Mechanical, file-owned edits ran on the primary tier. These are the P5 fix agents (8) and the P3 fix agents W5a to W5d. The log records no reason for the primary tier on these calls.
- The cheaper tier was used. It handled 10 documented calls, about 15 percent. That is not near zero, so no zero-usage flag applies.
- P6 is mislabelled. Its docs, migration, and fixes ran on `claude-sonnet-5-5`, the cheaper concrete model, but the phase logs `primary`. Treat the tier as not evidenced for P6.
- P0 logs `primary`, yet its four agents are cheaper tier.
- P1 records 18 agents, but its tier breakdown accounts for 16.
- This report runs on `claude-haiku-5-5`. The Header lists neither model, so the P8 row cannot be checked against it.
- Tier decisions are not recorded per agent call. This is an accountability gap.

### Parallelism audit

- No phase records zero batches. P4 and P7 have no parallel units by design.
- P0, P1, P2, P3, P5, and P6 each record a batch with several agents in one message.
- P3 records 3 batches. The log describes at least four, plus W6. The count is an undercount.
- The Header row `Parallel streams` reads `pending`. The P1 Toggle record reads `on`, but the Header was never updated. This is a finding.
- The run had 11 requirements, above the 10-requirement threshold. The Header does not read `off`, so the scalability flag does not fire. Four streams ran.
- Time saved is not captured. Each stream state file lists the shared phase windows, with the same start and end for every stream. Per-stream time cannot be separated from those windows.
- The P1 to P4 wall-clock is 191 minutes (45, 10, 111, and 25). The stream subagent counts reconcile with P3's 11 (1, 2, 1, and 7).

### Phase gate audit

- Each phase transition from P1 to P7 has a Progress line and a gate summary.
- `continuous_run` was pre-authorised. At P0 the human chose run mode 3, `autonomous`, and the log records `Run mode confirmed: autonomous`.
- Process violation: at P6 the run paused and waited for the human on the loop. The log records a "Go" to resume. The standard limits waiting to the seven exception-list items, so this pause is outside the list.
- P6 Gate B is labelled "continuous run, auto-accepted" in an `autonomous` run. The label is wrong.

### P0 question audit

- P0 questions asked: 4.
- `Brief complete` reads `no`, and `Stack unchanged` reads `yes`. The NFR-002 flag needs both to read `yes`, so no flag applies.
- All three lines are present.
- The log holds six lines headed "P0 exchange". The count of 4 does not match. Record the count the run used.

### Self-correction audit

- All three self-corrections were avoidable.
- P4 cycle 1 was a gap between spec and tests. P3 wrote no suite for the held-back clean-tree listing, and the shard split renamed a check.
- P4 cycle 2 came from a wrong assumption. The P3 execution tests used a stub `gh`, so the stub hid the real no-checks output.
- P6 revalidation cycle 1 came from a docs wording error. The docs used a term that a suite already banned.
- Ten reviewer rejections cover 3 P1 iterations and 2 P2 iterations, 4 P5 re-reviews, and 1 P6 review. Each rejection found real defects. The P1 rejections point to a draft spec and ADR text that were unclear at first.

### Build log integrity

- Every phase from P0 to P7 has its phase block and Progress line.
- The P8 block exists with `pending` in the End and Wall-clock fields. The P8 Progress line and the P9 block follow this report and are not gaps yet.
- Every per-phase field from P0 to P7 is populated: start, end, wall-clock, streams, model tier, skills, agents, MCP calls, and batches.
- Discrepancies to fix:
  - P0 tier label does not match its agents.
  - P1 tier breakdown sums to 16 of 18.
  - P3 batch count is 3, but the log describes at least four.
  - The P0 question count is 4, but the log has six exchange lines.
  - The Header `Parallel streams` row was never resolved.
  - P6 Gate B says "continuous run" in an `autonomous` run.
  - The P1 risk count reads 22 in one line and 24 in the gate summary.
  - P6 wall-clock includes a human pause, and the pause length is not captured.
- Write-or-Edit breaches (Hard Limit 8):
  - P2: the orchestrator ran `sed -i` on four stream files. It reverted with `git checkout` and redid the edit through Edit.
  - P3: W5c tried a `python3` heredoc edit. The permission check blocked it, and W5c used Edit.
  - P5: the held-back text fix agent appended text with a shell `printf >>`. The orchestrator checked the content and committed it.
  - P5: the fix 3 agent ran `git stash push` and `pop` on two edited files to prove RED.
  - P5: the iteration 2 fix agent ran `sed -i` on a test file and removed the `.bak` it left.

### Human touchpoint audit

- `Human touchpoint` lines: 1.
- Outside the exception list: 1.
- Finding, P6: "the human on the loop paused the run and resumed it with 'Go'". The standard names seven exception-list items, and a pause for "Go" matches none of them. The run logged the line as outside the list, but it still waited.
- The three `Exception waiting` lines at P6 are exception-list items. They are not touchpoints under the standard.

## Efficiency observations

- P6 was the longest phase at 397 minutes, 57 percent of the recorded total. The log does not separate the human pause from active work.
- P3 and P5 together spent 205 minutes on 27 agents. P5's cost came mainly from the re-review loop, with six re-reviews across two approaches.
- P3 changed the Windows Git Bash leg from one entry to seven shards, after the 10-minute and 20-minute caps both fell short. CI jobs per PR rose from 10 to 13. The log records this as a deviation, but the CI cost is not measured.
- P1 needed three rejected critic iterations. Iteration 1 found nine major issues. A tighter first spec would cut that cost.
- To make the next audit score routing and parallelism, the log should record the concrete model per agent call, resolve the `Parallel streams` row, and record per-stream phase times.
