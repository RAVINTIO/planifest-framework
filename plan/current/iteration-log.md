---
title: "Iteration Log - 0000035-write-gate-scope-and-path-hardening"
summary: "Execution log for the agent session."
status: "active"
version: "0.1.0"
---
# Iteration Log - 0000035-write-gate-scope-and-path-hardening

> **Audience:** Build-assessment-agent (P8) and post-run technical review. This is NOT the PR changelog: the PR changelog (written by ship-agent Step 1) is the human-readable audit trail for PR reviewers.

**Skill:** [docs-agent](../../planifest-framework/skills/planifest-docs-agent/SKILL.md)
**Date:** 2026-10-22
**Wave:** 1 (single wave, by the choice of the human on the loop)

**Feature:** Write gate scope and path hardening, version `0.32.0` to `0.33.0`
**Pipeline run:** Feature Pipeline in `autonomous` mode. P0 to P6 are complete. P7 to P9 run in the ship agent's close-out.

## What Was Built

The run folds in ten backlog entries: 0000062, 0000081, 0000106, 0000107, 0000109, 0000114, 0000117, 0000124, 0000125, and 0000126. It delivers ten requirements in three streams:

- `stream-01-gate-rules`: req-001 (Fast Path scope record), req-003 (links judged by real target), req-004 (root when the cwd is deleted), req-005 (ratchet uses the shared rules), req-006 (no planted root marker), and req-009 (Fast Path enforcement paths).
- `stream-02-release-manifest`: req-002 (`product.yml` set in P7) and req-008 (Hard Limit 8 sanctioned scripts).
- `stream-03-migration-state`: req-007 (per-project migration records) and req-010 (migration records for this repo).

## Iteration Steps Completed

| Phase | Status | Gate Result | Notes |
|-------|--------|-------------|-------|
| 0 - Assess & Coach | pass | Design confirmed: yes | 7 questions asked. 4 Scope Lock agents in one batch. Run mode `autonomous`. |
| 1 - Specification | pass | All artifacts produced: yes | 3 streams, 13 agents. Critic approved on approach 2 after 3 rejections. |
| 2 - ADRs | pass | 16 ADRs generated | 3 requirement splits. Critic approved on iteration 2. |
| 3 - Code Generation | pass | Implementation complete: yes | 16 deviations. 88 feature and 31 regression suites pass. |
| 4 - Validation | pass | CI clean: yes | 1 self-correct cycle. 69 of 71 criteria covered, 2 deferred. |
| 5 - Security | pass | Critical findings: 0 | 2 High closed. 19 findings fixed in two batches. Risk Medium. |
| 6 - Docs | pass | All docs synced: yes | Three docs agents. Deviation review: 34 additive, 5 altering. Cross-model approved on iteration 2. |
| 7 - Archive | pending | | |
| 8 - Build assessment | pending | | |
| 9 - Ship | pending | | |

## Phase Detail

### P0: Assess and coach

- The human on the loop picked the write-gate batch, then added six entries and backlog 0000126. They chose one wave over the three-story split.
- Four `planifest-scope-lock-agent` instances drafted the Scope Lock items in one batch on the cheaper tier. The human on the loop accepted all four.
- Commit `38541a5` wrote the run-mode line as a list item, and `run-mode.mjs` ignored it. A second commit re-recorded the anchor, and backlog 0000127 records the gap.

### P1: Specification

Toggles: `design_critic`, `verify_by_execution`, `cross_model_review`, `reversal_protocol`, and `parallel_streams` on. `p0_completeness` off.

| Loop | Iteration | Verdict | Findings |
|------|-----------|---------|----------|
| P1 critic, approach 1 | 1 | REJECT | 1 critical, 4 major, 9 minor |
| P1 critic, approach 1 | 2 | REJECT | 0 critical, 2 major, 5 minor |
| P1 critic, approach 1 | 3 | REJECT | 0 critical, 2 major, 3 minor. Cap of 3 reached |
| P1 critic, approach 2 | 1 | APPROVE | 5 minor, fixed by the orchestrator |

Approach 2 made the script carve-out a standing rule. The boot templates name the sanctioned scripts, and req-008 validates every script argument.

### P2: ADRs

| Loop | Iteration | Verdict | Findings |
|------|-----------|---------|----------|
| P1 critic, rerun after the req-002 split | 1 | APPROVE | 5 minor |
| P2 critic | 1 | REJECT | 1 major, 8 minor. M1: the criteria-limit change had no ADR, so ADR-012 was added |
| P2 critic | 2 | APPROVE | 3 minor, fixed by the orchestrator |

The gate passed with ten requirements of 3 criteria each and 16 ADRs. `consistency-check.mjs` reported clean, and `stream-reconcile.mjs` exited 0.

### P3: Code generation

One codegen agent per stream ran in one parallel batch. Each requirement went RED first, then GREEN.

| Stream | Requirements and commits |
|--------|--------------------------|
| 01 | req-006 `cdc1a9d`, req-004 `cf05b31`, req-003 `cbdaba4`, req-005 `67315b8`, req-001 `76eead2`, req-009 `745961f` |
| 02 | req-002 `61dd3cd`, req-008 `b019664` |
| 03 | req-007 `b056396`, `_done/` returned `c9c45e7`, req-010 records `afd2378` |

At the join, `planifest-framework/component.yml` moved to `0.33.0`. `run-tests.sh` exited 0 with 88 feature suites and 31 regression suites.

### P4: Validation

- Semantic coverage: 69 of 71 criteria covered (`96b34d4`). New tests closed 19 gaps, and no production code changed.
- Verify by execution: 35 passed, 0 failed, 2 deferred (`788fdde`). req-002 AC-3 waits for P7, and req-010 AC-010.1 waits for the human on the loop.
- PowerShell isn't installed locally, so `test_setup.ps1` runs on CI only. No stream changed a PowerShell file.

### P5: Security

Two reviewers ran in parallel, one for the gates and one for the scripts. Overall risk before fixes was High.

| Batch | Findings fixed | Commits |
|-------|----------------|---------|
| 1, gates | G-S01, G-S02, G-S03, G-S11 | `5a5ad24`, `f82f12d`, `3d8cb71`, `f535ff2` |
| 1, scripts | P-S03 to P-S08, P-S09, P-S10 | `a6b1cd1`, `eb09fc8`, `02ca3c2` |
| 2, gates | G-N1, G-N2, G-N3 | `98cdb6b`, `62936f9`, `06c53a8` |
| 2, scripts | P-N1, P-N2, P-N3, P-N4 | `9d15070`, `ed7bfe4`, `7bce6e9`, `157e760` |

- G-S01 was a High regression from `main`. `resolveTarget` resolved `..` physically, while the **Write** tool collapses it as text. `docs/L/../../src/a.js` passed `gate-write` and the ratchet.
- G-S02 was High. APFS folds `ſ` to `s`, so a scope record admitted `.claude/ſettings.json`.
- Re-review round 1 confirmed batch 1 and found seven new Low or informational items, fixed in batch 2. Round 2 confirmed batch 2 and found seven Low items in older code. Those went to backlog, and the review rounds stopped there.
- Open Medium items after fixes: G-S04, G-S05, G-S08, G-S12, and P-S13. G-S08 and P-S13 rest on accepted risk.

### P6: Docs

- Gate A passed, and Gate B auto-accepted updates to the living docs, the framework reference docs, and `src/setup-hook-integration/docs/`.
- Three docs agents ran in one batch: living docs and drift checks, reference docs and spec sync, and recommendations. The drift checks found three low domain-term items, which the orchestrator fixed.
- The post-P6 revalidation passed: 88 feature and 31 regression suites, self-description, and consistency.
- Deviation review: 39 rows, 34 additive, 5 altering, 1 schema, and 2 destructive. Eight items became exceptions.
- Cross-model review (`claude-sonnet-5-5` reviewing `claude-opus-5-5`): iteration 1 REJECT with 8 minor findings, iteration 2 APPROVE with 2 minor findings. All were fixed or deferred to backlog 0000159.

## Requirement Changes During Run

| Change | Phase Active | Classification | Action Taken |
|--------|-------------|----------------|-------------|
| `consistency-check.mjs` allows up to 10 criteria per requirement, and the brief template still asks for 3 | 1 | additive | Directed by the human on the loop. Commit `c7e7642`. ADR-012 added at P2. |
| A warning prints for 4 to 10 criteria, and the check still exits 0 | 2 | additive | Directed by the human on the loop. Commit `bb2d692`. Both governance suite copies pass. |
| Split req-002: the P7 update stays, and req-008 (US-008) takes the sanctioned-scripts rule | 2 | additive | Directed by the human on the loop. P1 critic reran over the P1 artifacts. |
| Split req-001: the scope record stays, and req-009 (US-009) takes the enforcement list | 2 | additive | Named by the critic. req-009 joined stream 01. |
| Split req-007: run-state behaviour stays, and req-010 (US-010) takes the one-off run in this repo | 2 | additive | Named by the critic. req-010 joined stream 03. |
| `./README.md` added to the `design.md` Component Paths | 3 | altering (deviation review) | `gate-write` blocked the FR-007.10 edit. The P3 decision added the path. It waits for the human on the loop. |

## Deviations

The build log records 31 deviations: 4 at P1, 16 at P3, 10 at P5, and 1 at P6. The P6 deviation review classed 3 of them altering. These deviations carry the most weight:

- P1 (altering): the scope record never enters a commit, where the brief says the Fast Path commit deletes it.
- P1 (altering): a fix agent wrote four shared artifacts through a Python script, which breaks Hard Limit 8. The orchestrator checked the diff by hand, and no In Scope or criteria line changed.
- P1: a missing cwd now blocks a write into `src/`. This supersedes the 0000032 req-006 assertion at lines 364 to 366.
- P3 (altering): `resolveRoot` also returns `null` when the cwd walk stops at a `realpathSync` failure with no `CLAUDE_PROJECT_DIR`. The gate then fails open.
- P3: the ratchet suites and their regression copies gained `unset CLAUDE_PROJECT_DIR`, outside the req-005 file list.
- P5: `promote-to-regression.sh` writes through a temp file and a Node `renameSync`, beyond the refusal checks.

## Exceptions Waiting for the Human on the Loop

Eleven exceptions wait. Three come from the P3 migration scans:

| Migration | Scan result |
|-----------|-------------|
| `0001-date-format.md` | About 506 dates outside `DD MMM YYYY` in 283 files. The target clashes with the house `YYYY-MM-DD` rule. |
| `0002-british-english.md` | About 870 American spellings in 307 files. |
| `retroactive-release-tags.md` | v0.14.0 at `6c145b5` and v0.15.0 at `928f1d4` have no tag. |

Eight come from the P6 deviation review: build-log lines L111, L116, L189, L190, L191, L201, L205, and L277. `deviation-review.md` gives each one.

Five migrations have records in `plan/_migrations/`. Three are `applied` with no findings, and two are `not applicable`. Backlog 0000153 tracks the three migration exceptions.

## Self-Correct Log

- P1: approach 1 reached its cap of 3 critic iterations. Approach 2 then passed on its first iteration.
- P4 cycle 1 of 5: the req-004 suite expected exit 0 for a cwd of `42`, `""`, and `null`, and got 2. The test was wrong, because a non-string cwd falls back to `process.cwd()`. A `resolveRoot` unit check and a shell-guard case replaced it, and the suite passed.
- P5: two fix batches and two fresh-context re-review rounds. Every new case went RED first, then GREEN. `run-tests.sh` exited 0 after each batch.
- P6: the cross-model loop took two iterations. Iteration 1 fixes passed every check.

## Backlog Filed

| Phase | Entries |
|-------|---------|
| P0 | 0000126 (pulled into this run), 0000127 |
| P1 | 0000128, 0000129, 0000136, 0000137 |
| P2 | 0000130, 0000139 |
| P4 | 0000140 |
| P5 | 0000141 to 0000146, 0000147 (closed in this run by P-N3), 0000148 to 0000151 |
| P6 | 0000152 to 0000157 (from `recommendations.md`), 0000158, 0000159 |

## Quirks

- Live hooks run from the git-ignored copies under `.claude/hooks/`, so source edits can't block this session.
- The installed `.claude/skills/planifest-ship-agent/SKILL.md` has no Step 5b. A P4 decision has P7 read the source ship skill instead.
- Three agents shared one working tree at P3. Each committed only its own paths and retried on a git index lock. The orchestrator wrote every build-log line.
- The P6 docs agent wrote this log at the ship agent's changelog path. P7 moved it here.

## Recommended Improvements

See `plan/current/recommendations.md`. The human on the loop should look at these before the PR:

- REC-002: G-S01 passed P3 and P4, because the spec assumed shell path semantics.
- REC-004: the three migration exceptions above.
- REC-005: the accepted Medium risks G-S08 and P-S13.
