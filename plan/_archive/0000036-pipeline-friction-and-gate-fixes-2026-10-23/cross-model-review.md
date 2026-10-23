---
title: "Cross-model review - pipeline friction and gate fixes"
summary: "Fresh-context review of feature 0000036 on a different model from the implementers."
status: "active"
---
# Cross-model review - 0000036-pipeline-friction-and-gate-fixes

| Field | Value |
|-------|-------|
| Reviewer model | `claude-sonnet-5-5` |
| Implementer model | `claude-opus-5-5` |
| Branch | `feat/0000036-pipeline-friction-and-gate-fixes` at `d68d0a2` |
| Diff reviewed | `git diff main...HEAD`, 145 files |
| Overall verdict | **APPROVE**, with two conditions that must close before P7 (findings M-1 and M-2) |

The code, hooks, scripts, and skill text meet req-001 to req-011. Two items sit outside the diff and block P7 until they close. The first is the missing `applied` record for this repo. The second is the human decision on the 1 MiB `design.md` cap. Neither is a code defect.

## Rubric

| # | Item | Result | Evidence |
|---|------|--------|----------|
| 1 | Every acceptance criterion met by code or text | Pass, except the record clause of AC-001.1 | See the per-requirement table below. `plan/_migrations/migrate-0.34.0-rerun-setup.md` does not exist (`ls plan/_migrations \| grep 0.34` returns nothing), and the req-001 suite prints `SKIP: ... the end-of-P6 setup run hasn't happened yet`. ADR-007 schedules that run after this review, so the gap is sequencing, but it stays open (M-1). |
| 2 | No change outside confirmed scope except recorded deviations | Pass, with one unrecorded tightening | The diff touches only paths named in `scope.md`, plus `plan/` records. Deviations are at `build-log.md:109,117,122,198,252,253,254`. The 1 MiB cap (`:254`) is altering and awaits the human (M-2). The whole-line anchor tightening in `run-mode.mjs:69` has no `Deviation` line (m-2). |
| 3 | Every ADR decision implemented as written | Pass | ADR-001: `grep` of the changed hooks and `skill-drift-check.mjs` finds no `child_process` import except the existing one at `ratchet-check.mjs:53`. ADR-002: `path-rules.mjs` `readDesign` (lstat, `O_NONBLOCK\|O_NOFOLLOW` open, `fstatSync`, 1 MiB cap, `FAIL_OPEN_ERRORS` of `EACCES` and `EPERM`). ADR-003: `isAlwaysPermitted` ends `&& !isEnforcementPath(relPath)`. ADR-004: `shown()` unit loop, `shown(l, 200)` at `ratchet-check.mjs:267`, `shown(relTarget, 200)` at `em-dash-guard.mjs:122`. ADR-005: `skill-drift-check.mjs` header and exit codes, orchestrator step 1b at `SKILL.md:80`. ADR-006/007: `migrate-0.34.0-rerun-setup.md` lists every setup-delivered file in the branch diff (checked against `git diff --name-only main...HEAD`). ADR-008: `run-mode.mjs:69` `ANCHOR_RE`. ADR-009: loop runner `SKILL.md:27,41`, `autonomous-run-standards.md:110`. ADR-010: dispatch template at `agent-dispatch-standards.md:125,128,131`. ADR-011: `Split step:` marker in the spec agent (`:52`), design critic (`:47`), and loop runner (`:77`). ADR-012: ship agent subjects at `SKILL.md:157,244,364`. |
| 4 | Hook constraints kept | Pass | Changed hooks import only `node:` modules, `./path-rules.mjs`, and `./read-stdin.mjs`. No new spawn. `process.exit` values in the changed hooks are 0 and 2 only (`em-dash-guard.mjs:130,133`, `gate-write.mjs:49,52,55`). Fail-open is limited to `EACCES`, `EPERM`, and a failed read, as ADR-002 says. `gate-write.mjs` is unchanged. |
| 5 | Tests are real (mutation check in a `mktemp`-style copy) | Pass, one surviving mutant | 14 mutations, 13 killed. Table below. The survivor is m-1. |
| 6 | Docs and skills match code, no bare citation | Pass | `bash planifest-framework/tests/test-0000036-req-005-hard-limits-cited-by-name.sh` gives `Results: 12 passed, 0 failed`. My own `grep -rnE 'Hard Limits? [0-9]+'` over the repo, minus archive, changelog, tests, and `plan/current`, finds only the bracketed dispatch form (deviation at `build-log.md:198`) and out-of-scope backlog files. `docs/architecture-overview.md:350-355,371` and `docs/decisions-index.md:31,171,315,358-365` match the code. `consistency-check.mjs` prints `clean`. |
| 7 | Full suite passes | Pass | `env -u CLAUDE_PROJECT_DIR bash planifest-framework/tests/run-tests.sh` ends `Feature suites: 97 passed, 0 failed. Regression suite: 33 passed, 0 failed. All tests passed.` |

### Acceptance criteria by requirement

| Req | Evidence |
|-----|----------|
| 001 | Migration file has the header lines and five sections, Target names the framework source, `framework-update-policy.md` holds the required sentence (mutation M10 fails the suite when removed). The `applied` record is absent (M-1). |
| 002 | Script exits 1 with `stale:` lines on this repo (11 skills, 0.05 s). Orchestrator step 1b names both source-copy states and loads nothing otherwise. 88 suite checks pass. |
| 003 | Three ship subjects carry the ID in a second `-m`. Mutation M6 fails the suite. |
| 004 | `node planifest-framework/scripts/run-mode.mjs` prints `autonomous` for this run's real anchor at `build-log.md:67`. 101 checks pass. Template deviation is recorded at `build-log.md:252`. |
| 005 | Suite passes and fails on a planted bare citation (M9). Both dispatch prompts and the self-contained rule carry the sentence. |
| 006 | Loop runner, template, orchestrator, standards, and both docs state `report-only`. Mutation M12 fails the gates-as-loops suite. |
| 007 | One `Split step:` marker per skill. M7 fails the suite. |
| 008 | `readDesign` as above. M13 (cap raised) fails the suite. See m-1 for the lstat pre-check. |
| 009 | M2 (drop the enforcement condition) fails 3+ checks across both hooks. |
| 010 | `run-tests.sh:9` unsets the variable. M8 (delete an unset line) fails the rule check. |
| 011 | M3, M3b, and M3c each fail the req-011 suite. |

### Mutation results

| Mutation | Suite | Result |
|----------|-------|--------|
| M1 delete the `lstat` `isFile` pre-check | req-008 | **Survived** (m-1) |
| M2 drop `!isEnforcementPath` from `isAlwaysPermitted` | req-009 | Killed |
| M3 `shown()` keeps the unit that crosses the cap | req-011 | Killed |
| M3b `em-dash-guard` prints the raw target | req-011 | Killed |
| M3c `ratchet-check` prints the raw criterion | req-011 | Killed |
| M4 anchor regex loses `(- )?` | 0000033 req-001 | Killed |
| M6 P9 subject gains `{feature-id}` | req-003 | Killed |
| M7 rename the `Split step:` marker | req-007 | Killed |
| M8 remove an `unset` from the em dash suite | req-010 | Killed |
| M9 plant a bare citation in `docs/about.md` | req-005 | Killed |
| M10 remove the policy sentence | req-001 | Killed |
| M11 break one setup rewrite pair in the drift script | req-002 | Killed |
| M12 change `report-only` to `off` in the loop runner | 0000033 req-003 | Killed |
| M13 raise the design size cap | req-008 | Killed |

## Findings

### Critical

None.

### Major

- **M-1. The `applied` record for this repo is absent, and the installed copies are stale.**
  - Files: `plan/_migrations/migrate-0.34.0-rerun-setup.md` (missing), `.claude/skills/` and `.claude/hooks/enforcement/` (stale).
  - Evidence: `node planifest-framework/scripts/skill-drift-check.mjs` exits 1 and lists 11 stale skills. The req-001 suite prints a `SKIP` for the record.
  - Action: after this review, repeat the FR-001.3 diff check, run `planifest-framework/setup.sh claude-code --strict-orchestrator` with the flags in `.claude/.planifest-setup-flags`, confirm the drift check exits 0, then write the record through **Write** and commit it with `planifest-overrides/setup-config/claude-code.md`. Re-run the req-001 suite and confirm it prints no `SKIP`. Do not start P7 before this.

- **M-2. The altering deviation for the 1 MiB `design.md` cap has no human decision.**
  - Files: `planifest-framework/hooks/enforcement/path-rules.mjs` (`DESIGN_MAX_BYTES`), `plan/current/build-log.md:254,282`, `plan/current/deviation-review.md` row 7.
  - Evidence: `build-log.md:282` records an open exception: accept the cap and the closure of backlog 0000178, or split it out. The cap is not in `scope.md`, and the deviation review classes it as altering.
  - Action: the human on the loop records accept or split in the build log before P7. If they choose split, revert `ae3f552` and re-file 0000178.

### Minor

- **m-1. No test detects removal of the `lstat` pre-check.** File: `planifest-framework/tests/test-0000036-req-008-non-regular-design-md.sh`. Mutation M1 deleted `if (!stats.isFile()) return { kind: "non-regular" }` in `readDesign` and all 66 checks still passed. The `O_NONBLOCK` open plus `fstatSync` produces the same verdicts for a folder, FIFO, and link, so req-008 FR "`lstatSync` runs before any open" is untested. A device file would be opened with no guard if the pre-check regressed. Add a source-order assertion that `lstatSync` precedes `openSync` in `readDesign`, or a swap-harness case that records the call order.
- **m-2. The anchor tightening has no `Deviation` line.** Files: `planifest-framework/scripts/run-mode.mjs:69-76`, `plan/current/build-log.md`. The script now needs the whole line with a real UTC timestamp to the second. Before, a line starting `Run mode confirmed: autonomous` counted. `scope.md` says the other anchor rules "stay unchanged". The change is recorded as security fixes S-1 and S-2 (`build-log.md:240,246`) and in req-004 and ADR-008, but no `Deviation` line exists. Add one, class additive. I checked `plan/_archive` and `plan/changelog` and found no anchor in another format, so no existing run regresses.
- **m-3. The req-005 suite checks shape only.** File: `planifest-framework/tests/test-0000036-req-005-hard-limits-cited-by-name.sh:30-35`. `SOURCE='[a-z]+( [a-z]+)?'` and `NAME` accept any words, so `the foo rule (bar Hard Limit 8)` passes. Check each `{source}` against the set of real list owners, and each name against the table in req-005.
- **m-4. Two citation forms for the Write-or-Edit rule.** File: `planifest-framework/standards/agent-dispatch-standards.md:125,128,131`. Already tracked as backlog 0000189. No new entry.
- **m-5. Acceptance-criteria boxes are unticked.** Files: `plan/current/requirements/req-001-*.md` to `req-011-*.md`. Every `- [ ]` line is still open and each file still has `status: "draft"`. Tick the criteria that the evidence above meets, after M-1 and M-2 close, so the archive shows the state shipped.
- **m-6. `em-dash-guard.mjs` now has a static import that can end the process with exit 1.** File: `planifest-framework/hooks/enforcement/em-dash-guard.mjs:43`. If an install ever holds `em-dash-guard.mjs` without `path-rules.mjs`, Node exits 1 on import, outside the try block. `gate-write.mjs` already has the same exposure and setup copies every `*.mjs`, so the risk is low. A one-line mention in `src/setup-hook-integration/docs/interface-contract.md` that the two files install together would document it.

## Backlog

No out-of-scope pre-existing bug found, so I filed no `0000190` entry. All defects above sit in code or text this feature changed.

## Scope of this review

I wrote only this file. I did not commit, and I did not write `plan/.run-mode`, a `Run mode` row, a `Run mode confirmed:` line, or a Toggle record. Mutation copies lived under the session scratchpad and are not part of the repo.
