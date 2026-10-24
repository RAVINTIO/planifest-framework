# Build Report (0000038-token-efficiency-windows-shard, 24 Oct 2026)

## Model Usage

| Model tier | Concrete model | Phases used | Agent call count |
|------------|---------------|-------------|-----------------|
| Primary    | Not consistent. Header reads `claude-opus-5-5`. Phase rows read `sonnet` (P1 to P3, P5, P6 docs) or name no model (P0, P4, P7). P6 cross-model review ran on `opus`. | P0 to P7 | 26 |
| Cheaper    | Header reads `claude-sonnet-5-5`. The P8 row reads `haiku`. | P8 (pre-filled row) | 1 (not verified) |

The log does not record a model tier for each agent call. The split of the 26 calls between `sonnet` and `opus` in P6 is not captured.

## Skills Invoked

| Phase | Skill | Load pattern |
|-------|-------|-------------|
| P0    | planifest-orchestrator | Session start |
| P1    | planifest-spec-agent | Not captured |
| P2    | planifest-adr-agent | Not captured |
| P3    | planifest-codegen-agent, planifest-test-writer, planifest-implementer, planifest-refactor | Not captured |
| P4    | planifest-validate-agent, planifest-verify-by-execution | Not captured |
| P5    | planifest-security-agent | Not captured |
| P6    | planifest-docs-agent, planifest-reversal-assessor, planifest-loop-runner | Not captured |
| P7    | planifest-ship-agent | Not captured |
| P8    | planifest-build-assessment-agent | Not captured |

## Subagent Dispatch

| Phase | Agent type | Count | Purpose |
|-------|-----------|-------|---------|
| P0    | Not captured | 4 | Scope lock drafts, decomposition, and design checks |
| P1    | Not captured | 3 | Spec agent and design critic iterations |
| P2    | Not captured | 4 | ADR agent and three design critic iterations |
| P3    | Not captured | 5 | Four stream agents and one further agent |
| P4    | Not captured | 2 | Validation and verify-by-execution |
| P5    | Not captured | 2 | Security review and fresh re-review |
| P6    | Not captured | 6 | Docs, deviation review, reversal assessment, cross-model review, and revalidation |
| P7    | None | 0 | Archive |
| P8    | Not captured | 1 | Pre-filled row, not verified by this run |

**Total agents spawned:** 26 through P7. The P8 row adds 1 and is not verified.

## Phase Timing

| Phase | Subagents | Parallel batches | Streams | Wall-clock |
|-------|-----------|------------------|---------|------------|
| P0    | 4 | 1 | n/a | 451 min |
| P1    | 3 | 0 | 1 | 7 min |
| P2    | 4 | 0 | 1 | 8 min |
| P3    | 5 | 1 | 4 | 22 min |
| P4    | 2 | 1 | 4 (joined) | 37 min |
| P5    | 2 | 0 | n/a | 5 min |
| P6    | 6 | 0 | n/a | 54 min |
| P7    | 0 | 0 | n/a | 6 min |
| P8    | 1 | 0 | n/a | Pending |
| Total | 26 | 3 | | 590 min |

The P0 wall-clock covers the span from pipeline start to the P0 end time. It includes any time the human on the loop took to answer. The total excludes P8.

## MCP Tool Usage

| Tool | Call count | Purpose |
|------|-----------|---------|
| None recorded | 0 | MCP calls read 0 in every phase |

## Parallel Task Bursts

| Phase | Batch count | Tasks parallelised |
|-------|------------|-------------------|
| P0    | 1 | Not named in the log |
| P3    | 1 | Four stream agents: stream-01-orchestrator, stream-02-dispatch, stream-03-tests, stream-04-boot |
| P4    | 1 | Not named in the log |

**Phases with no parallelism:** P1, P2, P5, P6, P7. P1 and P2 are findings. See the parallelism audit below.

## Self-Corrections

| Phase | Count | Summary |
|-------|-------|---------|
| P1    | 1 | Critic iteration 1 rejected the ADR-003 bare token and three major findings. The orchestrator reworded the cite. |
| P2    | 2 | Critic iterations 1 and 2 rejected cross-feature ADR tokens and the gate checklist inside the byte-identical block. |
| P3    | 1 | Commit `d9a01e9` added a reference-link rewrite to `setup.sh` and `setup.ps1` after the installed links broke. |
| P4    | 2 | Commit `e8f86fb` fixed a `FAIL: 0` summary line that quiet mode counted as failed. Commit `cf87eed` replaced baseline commit reads that a shallow CI clone could not resolve. |
| P5    | 1 | Commit `2a981af` added `-Encoding UTF8` to the `setup.ps1` reads after a Windows PowerShell 5.1 finding. |
| P6    | 4 | Commit `87481f3` fixed a portability lint false positive. Commits `78430f9` and `4f9347a` fixed cross-model review findings. Commit `2875f40` fixed a CRLF size check on Windows shard 4. |

**Total self-corrections:** 11. This count covers fix batches and review-driven rework. It excludes the initial build.

## Artefact Counts

| Category | Count |
|----------|-------|
| Requirements | 7 (req-001 to req-007) |
| Acceptance criteria | 29 (the design stated 21) |
| ADRs | 7 (ADR-001 to ADR-007) |
| Design critic verdicts | 5 (two for P1, three for P2) |
| Cross-model review iterations | 3 (P6) |
| Security findings | 5 low, 2 informational (risk Low) |
| Verified criteria | 18 verified, 0 failed, 5 not verifiable |
| Test suites | 152 (117 feature, 35 regression) |
| Streams | 4 |
| Migrations | 1 (`migrate-0.36.0-rerun-setup.md`) |
| Backlog entries filed | 5 (0000232, 0000233, 0000234, 0000235, 0000236) |
| Deviations logged | 7 (all additive) |
| Fix commits after P3 | 7 |

## Efficiency Observations

### Process violations

Each item below breaks a Hard Limit or an operational directive. None has an approval on record.

- **P1, commit `0411efd`.** The orchestrator used a Python edit in Bash to change one acceptance criterion in req-005. This breaks boot Hard Limit 8 and bypasses `ratchet-check`. No `.ratchet-approve` line covers it. The P6 exception waiting still asks the human on the loop to approve the change or ask for a revert. The run closed without that decision recorded.
- **P7, `plan/current/build-log.md`.** The ship agent appended the P7 block with shell `printf >>`. This breaks boot Hard Limit 8. The text is log-only.
- **P3, stream-02.** The stream tried `git stash` in the shared tree. The permission system denied it. Hard Limit 8 covers changes made through git, so this attempt counts as a violation attempt.
- **P6, fix agent.** The fix agent stashed `planifest-framework/skills/planifest-orchestrator/SKILL.md` for one run to confirm RED. The stash changed a project file through git. Boot Hard Limit 8 applies.
- **P4, verifier.** The verifier ran `setup.sh claude-code` with this repo as its root. The log shows no skill step that called it. The tracked file was restored by Edit and matches HEAD.

### Model routing audit

- **Primary tier.** P0 to P7 each record the primary tier. The concrete model name differs between the header and the phase rows. The reader cannot tell which model ran most phases.
- **Cheaper tier.** The cheaper tier is used only in the P8 row. Expected use was in P4 CI checks and P7 scripted steps (`archive-current.mjs`, `set-product-release.mjs`, and version edits). Actual use was zero in P0 to P7. This is near-zero cheaper-tier usage, and it is flagged.
- **P6 docs.** The log gives a reason for running the docs agent on `sonnet`. The reason is judgement work. The routing decision is accepted.
- **Per-call records.** The log records one tier per phase. It does not record a tier per agent call. This is an accountability gap.
- **Header conflict.** The header names `claude-sonnet-5-5` as cheaper. The P8 row names `haiku`. The P4 probe reported `claude-haiku-5-5`, so the mismatch is not a missing model.

### Parallelism audit

| Phase | Agents | Batches | Assessment |
|-------|--------|---------|------------|
| P1 | 3 | 0 | Finding. The seven requirement files were written inline. The log gives a reason (shared context), but it gives no measurement. Treat as not applied. |
| P2 | 4 | 0 | Finding. Seven ADRs were written with no recorded batch and no reason. Three of the four agents were critic iterations, which run in sequence by design. |
| P5 | 2 | 0 | Not a finding. The re-review depends on the fix. |
| P6 | 6 | 0 | Finding. The log records no parallel batch and no reason. The docs update and the deviation review could have overlapped, but the log does not show their dependency. Treat as not evidenced. |
| P7 | 0 | 0 | Not a finding. One task. |

- **Parallel streams.** The header reads `on`. The 10-requirement scalability check does not apply. The run had seven requirements.
- **Stream time saved.** The four stream state files record 15.7, 7.7, 9.7, and 5.7 minutes for P3. Together, they total 38.9 minutes. P3 ran in 22.9 minutes of wall-clock. The streams saved about 16 minutes. Streams formed at P3, so the P1 to P4 comparison covers only P3. P1 to P4 wall-clock totals 74 minutes.

### Phase gate audit

- **Autonomous run mode.** The human chose `autonomous` at P0. This pre-authorises the autonomous run.
- **Gates P1 to P6.** Each phase has a `Gate (Px): passed` line.
- **Gate P0.** No `Gate (P0)` line exists. The run mode and design confirmations stand in for it. This is a log gap.
- **Gate P7.** No `Gate (P7)` line exists. This is a log gap.
- **P6 Gate B.** The log records auto-acceptance under `autonomous`. This follows from the P0 choice.

### P0 question audit

- **Count.** `P0 questions asked` reads 4.
- **Flag.** No flag. `Brief complete` reads `no`, so the count rule does not apply.
- **Required lines.** All three lines are present.

### Self-correction audit

- **P1 (1).** Avoidable. The ADR cite pointed to an ADR that did not exist yet at P1.
- **P2 (2).** Avoidable. The mechanical check reads an `ADR-NNN` token as a local file. The spec did not account for this.
- **P3 (1).** Avoidable. The design assumed the setup rewrite would cover `references/` files. It did not.
- **P4, `e8f86fb` (1).** Avoidable. Stream-03 reported that no suite printed `FAIL:` on a pass, and missed the `test-0000010` summary line.
- **P4, `cf87eed` (1).** Avoidable. The tests assumed a full clone, but the CI clone is shallow. The fix replaced commit reads with hashes.
- **P5 (1).** Partly avoidable. `setup.ps1` had the encoding bug before this feature. The new reads reached the same bug.
- **P6, `87481f3` (1).** Avoidable. The P5 fix did not run the portability lint, so the lint caught it later.
- **P6, `78430f9` and `4f9347a` (2).** Partly avoidable. The moved block and the pointer section conflicted on after-P0 rules. The design did not name this conflict.
- **P6, `2875f40` (1).** Avoidable. The size check assumed LF line endings. Git for Windows checks files out with CRLF.

Most of the 11 corrections trace to assumptions the spec or the test design did not check. The CI and lint runs caught them late. P4 and P6 together took 91 minutes.

### Build log integrity

- **Phases present.** P0 to P7 each have a full phase block with `End`, `Wall-clock`, and `Streams`.
- **Progress lines.** P0 to P7 each have a progress line. P8 has none yet. The orchestrator writes it after this report. P9 has not started.
- **Concrete models.** P0, P4, and P7 name no concrete model. This is a gap.
- **Per-call fields.** Agent types and per-call model tiers are not recorded for any phase.
- **Pre-filled P8 row.** The row reads `End` as `PENDING_P8_END` and `Agents spawned` as 1. This run did not verify the count.
- **Open deviations.** Seven deviations are logged as additive. Each has a reason. The P1 Bash edit and the P7 shell write are the two that break Hard Limit 8.

### Human touchpoint audit

- **Count.** The log holds no `Human touchpoint` lines.
- **Open decision.** The log holds one `Exception waiting` line at P6 for the P1 `0411efd` edit. That line asks the human on the loop to approve or revert. It is not labelled as a touchpoint, and the run closed without a recorded answer.
- **Exception list.** The skill text does not define the exception list. This audit cannot classify touchpoints against it.

### Scope and efficiency

- **Scope growth.** Acceptance criteria rose from 21 to 29. The P3 fix changed `setup.sh` and `setup.ps1`, which were outside the confirmed scope. The log records both changes as additive deviations.
- **Serial phases.** P6 took 54 minutes across six agents with no parallel batch. P4 took 37 minutes, most of it in CI round trips after two fix batches.
- **Backlog load.** The run filed five backlog entries. Four of them cover gaps this run found in the framework.
