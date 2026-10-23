# Build Report (0000036-pipeline-friction-and-gate-fixes, 23 Oct 2026)

Run mode: `autonomous`, as printed by `run-mode.mjs`. Every figure comes from `build-log.md`. Where the log is silent, this report says "not captured".

## Model usage

| Model tier | Concrete model | Phases used | Agent call count |
|------------|---------------|-------------|-----------------|
| Primary | `claude-opus-5-5` | P0 (orchestrator), P1 to P7 | Not captured per call |
| Cheaper | `claude-sonnet-5-5` | P0, P1 to P4, P6, P8 | Not captured per call |

The log records tiers per phase, not per agent call. The only per-call counts are in P0 notes: 3 Explore agents and 4 scope-lock agents on the cheaper tier, so 7 of 7 P0 agents. No other phase gives a tier split by count.

## Skills invoked

| Phase | Skill | Load pattern |
|-------|-------|-------------|
| P0 | planifest-orchestrator, planifest-migrator | Session start, then migration resume |
| P0 | planifest-scope-lock-agent | 4 instances in one parallel batch |
| P1 | planifest-spec-agent, planifest-loop-runner, planifest-design-critic | One spec agent per stream, critic loop of 3 iterations |
| P2 | planifest-adr-agent, planifest-design-critic, planifest-loop-runner | One ADR agent per stream, critic loop of 3 iterations |
| P3 | planifest-codegen-agent | 8 workers by file ownership |
| P4 | planifest-validate-agent, planifest-verify-by-execution | One batch of 2 |
| P5 | planifest-security-agent | 2 reviewers, then fix and re-review rounds |
| P6 | planifest-docs-agent, planifest-reversal-assessor | Docs agents, deviation review, cross-model review |
| P7 | planifest-ship-agent | Inline, no subagents |
| P8 | planifest-build-assessment-agent | One subagent |

## Subagent dispatch

| Phase | Agent type | Count | Purpose |
|-------|-----------|-------|---------|
| P0 | Explore (3), scope-lock (4) | 7 | Check 11 backlog entries, draft 4 Scope Lock answers |
| P1 | Spec, shared artifacts, critic, fix | 12 | 3 streams, 1 shared-artifact agent, critic rounds, 5 fix agents |
| P2 | ADR, critic, fix | 9 | One ADR agent per stream, critic rounds, 3 fix agents |
| P3 | Codegen workers W1 to W8 | 8 | 11 requirements in 3 batches |
| P4 | Validate, verify by execution | 2 | CI checks and criteria verification |
| P5 | Reviewers and fix agents | 8 | 2 reviewers, 3 fix agents, 3 re-review agents (split inferred from the notes) |
| P6 | Docs, deviation review, cross-model review | 5 | Living docs and review gates |
| P7 | None | 0 | Archive done inline |
| P8 | Build assessment | 1 | This report |

**Total agents spawned:** 52

The P5 split is not stated as a count in the log. The 8 total is the recorded figure.

## Phase timing

Wall-clock is in minutes.

| Phase | Subagents | Parallel batches | Streams | Wall-clock |
|-------|-----------|------------------|---------|------------|
| P0 | 7 | 2 | n/a | 41 |
| P1 | 12 | 3 | 3 | 28 |
| P2 | 9 | 2 | 3 | 20 |
| P3 | 8 | 1 | 3 | 31 |
| P4 | 2 | 1 | 3 (one joined validation) | 12 |
| P5 | 8 | 2 | n/a (joined set) | 45 |
| P6 | 5 | 1 | n/a (joined set) | 21 |
| P7 | 0 | 1 | n/a | 7 |
| P8 | 1 | 0 | n/a | pending |
| Total | 52 | 13 | | 205 (P0 to P7) |

Pipeline start was 2026-10-22T20:52:01Z. P7 ended at 2026-10-23T00:20:19Z, which is 208 minutes elapsed. The 3 minute gap to the 205 minute sum is unlogged time between phases.

P1 to P4 took 91 minutes in the log. The stream state files are not in the log, so the sum of per-stream phase times is not captured. The time saved by `Parallel streams: on` is therefore not evidenced.

## MCP tool usage

| Tool | Call count | Purpose |
|------|-----------|---------|
| None | 0 | The log records 0 MCP calls in every phase |

## Parallel task bursts

| Phase | Batch count | Tasks parallelised |
|-------|------------|-------------------|
| P0 | 2 | 3 Explore agents, then 4 scope-lock agents |
| P1 | 3 | 3 stream agents with the shared-artifact agent, critic rounds, fix agents |
| P2 | 2 | 3 ADR agents, then critic and fix rounds |
| P3 | 1 (plus 2 later waves) | W1 to W6 in batch 1, W7 in batch 2, W8 in batch 3 |
| P4 | 1 | Validate with verify by execution |
| P5 | 2 | 2 reviewers, then 3 fix agents |
| P6 | 1 | Docs agents |
| P7 | 1 | See the integrity findings |

**Phases with no parallelism:** P8, which had a single task.

## Self-corrections

| Phase | Count | Summary |
|-------|-------|---------|
| P1 | 2 | Design critic rejected iterations 1 and 2 (1 critical, 2 major, then 1 major). Iteration 3 approved. |
| P2 | 2 | Design critic rejected iterations 1 and 2 (2 major, then 1 major). Iteration 3 approved. |
| P3 | 1 | The orchestrator fixed a `printf` pipe into `grep -q` in W4's suite (`75b49c9`). |
| P4 | 2 | One missing req-006 assertion (`c486e9d`). One wrong 0.34.0 migration file list found by verify by execution (`16df927`). |
| P5 | 2 | Two fix rounds after re-review. Risk fell from High to Low. |
| P6 | 1 | Post-gate fix: the drift suite passed its script path in `process.argv[1]`, so the script ran itself. The path now travels in `DRIFT_MODULE`. |

**Total self-corrections:** 10

## Artefact counts

| Category | Count |
|----------|-------|
| Requirements | 11 (req-001 to req-011, 2 or 3 criteria each) |
| User stories | 11 (US-001 to US-011) |
| ADRs | 12 |
| Streams | 3 |
| Backlog entries pulled in | 11 |
| Backlog entries filed during the run | 16 (0000161, 0000162, 0000164, 0000167, 0000170, 0000177 to 0000182, 0000185 to 0000189) |
| Deviations | 7 (6 additive, 1 altering) |
| Criteria verified by execution | 30 of 31 at P4, the last closed at the end of P6 |
| Feature suites at close | 97 passed |
| Regression suites at close | 33 passed |
| Security findings | Round 1: 1 High, 3 Medium, 3 Low in scripts, plus 2 hook findings. Final rating Low. |

## Efficiency observations

### Model routing audit

- The cheaper tier is evidenced. P0, P1 (shared artifacts, three fix agents), P2 (two fix agents), P3 (W2 and W6), P4 (validate), P6 (docs and cross-model review) and P8 used it.
- P5 ran entirely on the primary tier with 8 agents. The three fix agents applied scoped changes to named files. The log gives no reason they could not run on the cheaper tier. Finding: P5 routing is not justified.
- P7 ran on the primary tier with no subagents. That is the orchestrator itself and is acceptable.
- P3 sent six of eight workers to the primary tier. The log gives no eligibility reasoning. W2 (suite edits) and W6 (skill text) went cheaper, which shows the split was considered. Treat the remaining six as not evidenced.
- Per-call tiers are not recorded. Phases P1 to P8 record only a tier list. This is an accountability gap. The cheaper-tier share by agent count cannot be computed.
- The P0 table says `primary`, but its notes say all 7 subagents ran on the cheaper tier. The two entries disagree.

### Parallelism audit

- Every phase from P0 to P6 recorded at least one parallel batch. P1, P2 and P5 show multiple batches.
- P3 has three batches. Batch 1 ran six workers in one wave. W7 and W8 ran later because they share skill files with batch 1 and with each other. The log names the shared files, so the sequencing is justified.
- P4 ran two independent agents in one batch. Correct.
- P6 recorded one batch for 5 agents. The log does not say whether the reviews that follow the docs agents could have run beside them. Not evidenced either way.
- The run has 11 requirements and `Parallel streams: on`, so the 10-requirement scalability flag does not apply.
- Time saved by streams is not captured. See Phase timing.

### Phase gate audit

- The run is `autonomous`. The log holds a `Run mode confirmed: autonomous (2026-10-22T21:33:13Z)` line in P0, after the human on the loop answered "3" and then "Yes accept all".
- The design confirmation and the run-mode choice came in one question turn. The orchestrator held the run-mode line back until the design was confirmed. This is correct handling.
- P1 to P7 each have a gate line and a progress line. No gate was skipped.
- The P6 Gate B text reads "continuous run, auto-accepted" although the mode is `autonomous`. The wording is stale but the behaviour fits the mode.
- P6 holds a gross-deviation exception (the 1 MiB `design.md` cap and the closure of backlog 0000178). The log does not record how it was resolved. The P6 gate passed with the exception listed as waiting. Finding: the resolution is missing from the log.
- Process slip in P2: the orchestrator used a shell `perl -pi` command to update three stream files, against the Write-or-Edit rule (Hard Limit 8). The log records it and keeps the content. Violation noted.

### P0 question audit

- P0 questions asked: 5.
- Brief complete: no. Stack unchanged: yes.
- The count is above 3, but `Brief complete` reads `no`, so the NFR-002 flag does not apply.
- All three lines are present.

### Self-correction audit

- P1 and P2 each needed two critic rounds. The rejections found a byte order mark, an unstated `lstat` behaviour and a setup assumption. All three came from facts the P0 design did not check. Avoidable with a pre-design read of setup and the orchestrator skill.
- P4 found a migration file list that the author built by hand. The fix used `git diff --name-only`. Avoidable by building the list from the diff in P3.
- P5 needed two fix rounds. The reviewers raised one High finding (the anchor sat at column 1 in the build-log template). This came from a design choice in P3. The later rounds found Low edge cases, and the orchestrator stopped the loop at Low. The stop rule was applied correctly.
- Three deviations in P5 changed the confirmed design (error handling, the size cap, the template anchor). Two of them trace to a design that did not specify failure behaviour. Ten self-corrections on a feature with 11 well-defined requirements points to spec gaps on failure paths.
- P6 post-gate fix: the suite broke after the setup re-run changed the script's behaviour. The earlier green runs did not cover the new success line.

### Build log integrity

- All phases P0 to P8 are represented.
- Every phase has `Start`, `End`, `Wall-clock`, `Streams`, `Model tier`, `Skills loaded`, `Agents spawned`, `MCP calls` and `Parallel task batches`. P8 `End` and `Wall-clock` read `pending`, which is expected while this report is written.
- Every phase from P0 to P7 has a progress line. P8 has none yet, which is expected until it ends.
- The P7 row records 1 parallel batch with 0 agents spawned. A batch with no agents contradicts the agent count. Finding: the P7 entry is inconsistent.
- The P1 shared-artifact note says no backlog entry was filed and 0000170 stays unused. A later line files 0000170. The log contradicts itself.
- The P3 and P5 agent counts do not list per-agent tiers. Covered in the model routing audit.
- The `Run mode` row reads `autonomous`, and `run-mode.mjs` printed `autonomous` with exit code 0, so the git anchor checks out.

### Human touchpoint audit (autonomous)

- `Human touchpoint` lines in the build log: 0.
- Lines outside the exception list: 0.
- The log records two human exchanges in P0 (backlog and release choices, plus the combined confirmation turn) and the PR #61 merge. They appear as `P0 exchange` lines, not as `Human touchpoint` lines. P0 is outside the autonomous window, which starts at the confirmation. No finding is raised.
- Finding for the log format: the P6 gross-deviation exception waits on a human decision but carries no `Human touchpoint` line. If that wait needed a human, the log should say so with the line the audit counts.

### Summary of findings

- The run held its gates, used parallel batches in every phase and met the touchpoint rule, with a count of zero.
- Model routing is the weakest area. There are no per-call tiers, P5 ran 8 agents on the primary tier without a reason, and the P0 tier row contradicts its notes.
- Ten self-corrections and three altering or additive design deviations point to unspecified failure paths in the spec. The log also lacks the P6 exception resolution and has two internal contradictions (P7 batch count, backlog 0000170).
