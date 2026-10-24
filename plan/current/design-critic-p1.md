# Design-Critic Verdict (P1, iteration 1)

**Mode:** on (autonomous)
**Mechanical check:** clean (`node planifest-framework/scripts/consistency-check.mjs plan/current` printed `consistency-check: clean`, exit 0)
**Overall:** REJECT

**Counts:** 0 critical, 9 major, 11 minor.

The artifacts trace well. Every story US-001 to US-011 maps to one requirement, and every requirement holds three criteria with a recorded split decision. The rejection rests on nine defects that would fail or mislead P3 and P4 if left in place. Each defect is cheap to fix before the human on the loop sees the artifacts.

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | fail | Most criteria state observable outcomes. Three do not hold. AC-007.3 asserts output the hook never produces (M1). AC-008.3 needs a migration that doesn't exist at P4 (M8). AC-009.3 depends on an undefined payload exemption (M4). |
| 2 Traceability | pass | Each `Source:` field in req-001 to req-011 resolves to US-001 to US-011 in `design.md`. The brief's 11 acceptance criteria map one to one onto the requirements. No orphan stories. |
| 3 ADRs record real decisions | n/a | No ADRs exist at P1. The ADR block IDs are reserved in `build-log.md`. The P2 critic covers this row. |
| 4 Honest consequences | n/a | Same as row 3. |
| 5 Scope boundaries | pass with note | The three Out of Scope items exclude plausible work (`push` trigger, auto-merge, consumer workflow). `scope.md` says "Nothing deferred" while two known gaps exist (M9). |
| 6 Risks specific and mitigated | fail | `risk-register.md` R-017 and R-018 describe behaviour that the requirements contradict (M7). No risk covers the 10-minute job cap on a Windows leg (M2). |
| 7 NFRs measurable | pass | NFR-001 to NFR-005 in `execution-plan.md` each carry a number or a deterministic check. The brief's CI wait row still names `--watch` (m2). |
| 8 Internal consistency | fail | The risk register, the design cost line, and the brief disagree with the requirements (M7, m1, m2). Requirements use "Verified by" values that req-006 does not allow (M3). |
| 9 Split step | pass | All 11 requirements hold exactly three criteria. A `Split step: keep` or `not triggered` note sits in each file, and the build log holds a matching `Decision (P1)` line for req-005 to req-011. |

## Findings (severity-ordered)

### Major

- [major] M1. `plan/current/requirements/req-007-wired-command-test.md` (AC-007.3 and FR-007.4). The criterion says the `auto-trigger-orchestrator` command "exits 0 and prints valid JSON". The hook at `planifest-framework/hooks/enforcement/auto-trigger-orchestrator.mjs` writes a plain-text `SYSTEM INSTRUCTION` line and no JSON. It also prints nothing unless `planifest-framework/` exists in the workspace and `plan/.orchestrator-active` is absent. The hook exits 0 on every internal error, so exit 0 alone proves nothing. Fix: assert that stdout contains `Load the planifest-orchestrator skill`. State that the fixture workspace holds a `planifest-framework/` folder and no sentinel. Keep the negative fixture (bare `.mjs` path or wrong directory exits non-zero).

- [major] M2. `plan/current/requirements/req-010-windows-git-bash-leg.md`, `risk-register.md` (R-001, R-013), `design.md` (Constraints). The leg keeps `timeout-minutes: 10` and must end green. Run 40012567385 shows `Test suite (macos-latest)` at 7 minutes 36 seconds and ubuntu at 3 minutes 28 seconds. Git Bash forks slowly, so a Windows leg with 130 suites likely passes 10 minutes. A timeout reads as `cancel`, which req-001 maps to unknown, so the PR never reads as done. No risk, measurement, or fallback covers this. Fix: add a risk with a measurement step at the start of P3. Name the fallback, such as raising the cap for that leg through an ADR that amends 0000031 ADR-003, or sharding the suite. State that the new suites also add time to the macOS leg.

- [major] M3. `req-001` to `req-004` and `req-007` to `req-011` (every `Verified by` value). req-006 defines six allowed values: unit, integration, contract, e2e, execution, and manual. req-001 to req-004 use free text such as "shell test over the ship skill text, plus verify-by-execution with a stub `gh`". req-007 to req-011 use "shell suite" and "static workflow-text test" inside parentheses. Only req-005 and req-006 comply. The feature breaks its own new rule, and the P3 scan (req-006) can't match a test type to these values. Fix: write `Verified by: {enum value}` with an optional detail after a dash. For example, use `integration - shell suite over the ship skill text` and `execution - stub gh`. Use one punctuation form in every file.

- [major] M4. `plan/current/requirements/req-009-portable-suites-and-lint.md` (baseline table, FR-009.4, AC-009.3). The table says `sed -i` matches "3 in payload strings". A search of `planifest-framework/tests/` finds 10 non-comment lines with `sed -i` and no attached suffix. They sit in `test-0000032-req-008-shell-writer-detection.sh` (4), `test-0000032-req-009-shell-guard-path-parity.sh` (1), and the `regression/` copies of both (5). The total of 19 lines excludes them. FR-009.4 says payloads "sit in a quoted payload array the lint recognises", which defines no rule. AC-009.3 ("0 findings") can't be decided. Fix: recount, then choose one rule. Either add `# portable-ok: payload string` to each line, or define the exemption exactly, for example a line where `sed -i` sits inside a double-quoted or single-quoted argument to `run_guard`. State the final count in the table.

- [major] M5. `req-001-p9-ci-check.md` (Step 10c, unreadable status) and `req-002-gutd-ci-check.md` (step 5). Both say a "failing command" means the status can't be read. `gh pr checks` itself exits non-zero when a check fails (exit 1) or is pending (exit 8), and it still prints the data. An implementation that follows the text reads every red PR as "could not be read". The stub-`gh` tests would encode the same error. Fix: state that the result comes from the JSON, not the exit status. Reserve "could not be read" for a missing `gh`, an auth failure, or output that is not valid JSON. Add a stub case that exits 1 with valid JSON containing a `fail` bucket and expect `red`.

- [major] M6. `req-003-pre-commit-credential-scan.md` (`git show :path` and the build-log Decision on staged content). The decision says the scan "checks what gets committed". The framework's own commit form is `git commit -m ... -- {path}`, as in ship Steps 10b and 11. With `--` and paths, git commits the working-tree content of those paths and ignores the index. A credential added to the file after `git add` is committed without a scan. Fix: scan both the index blob and the working-tree file for every path in the commit. Alternatively, require `git add` and the scan immediately before the commit with no other write between them. State the chosen rule in FR and in the standing rule text.

- [major] M7. `risk-register.md` (R-017, R-018, R-019, R-004). R-017 says "The suite fails when the base ref is absent. The CI checkout fetches the base ref (req-008)". req-008 FR-008.5 says the opposite: a missing tag prints `SKIP` and exits 0, and backlog 0000199 records that CI fetches no tags. R-018 says the P3 scan "reads the Verified by field only", but req-006 maps IDs for every requirement and skips only the type check when the field is absent. R-019 says "Rerun the full P4 check set", but req-005 runs the product's doc-check command first. R-004 names `gh pr checks --watch`, but the recorded decision polls every 30 seconds. Fix: rewrite each mitigation to match the requirement. For R-017, state that the check skips in CI and that 0000199 tracks it.

- [major] M8. `req-008-migration-branch-diff-test.md` (AC-008.3 and Dependencies). The criterion cites "verify-by-execution at P4". `migrate-0.35.0-rerun-setup.md` doesn't exist until the end of P6. P4 and P5 run before it. The only run that sees the file is the post-P6 revalidation, and that rerun excludes step 6 (verify by execution), per req-005. In CI the check skips because no tags exist. So the positive path has no verified run in the pipeline as written. Fix: change the verifier to "post-P6 revalidation (local run with tags present)". Add a P3 fixture check that proves the comparison works before the real file exists. State that CI skips until 0000199 lands.

- [major] M9. `scope.md` (Deferred), `design.md` (Scope, Deferred), `feature-brief.md` (Business Goal), `req-001-p9-ci-check.md`. The Step 11 push of `final-report.md` starts a CI run on a head that Step 10c never read. The build log records this as backlog 0000193. The brief's goal says "every PR the ship agent raises has green checks, or a reported failure, before the final report". The shipped head can still be red and unread. `scope.md` says "Nothing deferred", so the gap sits nowhere in the artifacts the human confirms. Fix: either move the final-report commit before Step 10c's last read, or add a final re-read after the last push. Otherwise list the gap under Deferred in `scope.md` with 0000193 and narrow the goal sentence to "the head that P9 read". Do the same for 0000199.

### Minor

- [minor] m1. `design.md` (Cost boundary) and `risk-register.md` (R-013). Both say "three new Windows legs" and "30 minutes per PR". The design adds two: `windows-latest` in the `test-suite` matrix and the `setup-powershell-51` job. The existing `setup-powershell` job doesn't change. Fix: write two legs and 20 minutes.

- [minor] m2. `feature-brief.md` (NFR CI wait) and `design.md` (Risks, fourth bullet). Both name `gh pr checks --watch`. The recorded decision polls `gh pr checks --json` every 30 seconds because macOS has no `timeout`. Fix: replace `--watch` with the polling text from `execution-plan.md` NFR-001.

- [minor] m3. `scope.md`, `risk-register.md`, `domain-glossary.md` carry `Version: 0.34.0`. `execution-plan.md` carries 0.35.0, and the design suggests 0.35.0. Fix: align the three to the feature version, or state that the field records the base version.

- [minor] m4. `req-001`, `req-002`, `req-003`, `req-004`, `req-007` to `req-011` link the spec-agent skill with `../skills/planifest-spec-agent/SKILL.md`. From `plan/current/requirements/` that path resolves to a folder that doesn't exist. req-005 and req-006 use the correct `../../../planifest-framework/skills/...`. Fix: use the req-005 form. Also set `status` consistently, since req-005 to req-011 say `draft` and req-001 to req-004 say `active`.

- [minor] m5. `req-011-windows-powershell-coverage.md` (assertions). It expects "exactly one line `--context-mode-mcp was removed in 0.29.0 and has no effect`". The real line in `setup.ps1` is `  ! --context-mode-mcp was removed in 0.29.0 and has no effect.` with a prefix and a full stop. An exact-line match fails. Fix: assert that exactly one output line contains that substring. Also delete the stray sentence "No new requirement ID is free anyway", which explains nothing.

- [minor] m6. `req-010` and `req-011` (User Story section). Both keep the template hint `> One requirement doc = one user story.` as body text. Fix: delete the hint.

- [minor] m7. `req-002-gutd-ci-check.md` (step 5 lookup). `gh pr list --state merged --limit 1` sorts by creation date, not merge date. An older PR merged later is missed. Fix: request `--limit 10 --json number,url,title,mergedAt` and pick the newest `mergedAt`. Also note that the repository's generated `CLAUDE.md` copies the override text. A setup re-run refreshes it, and the criterion should say so.

- [minor] m8. `req-001-p9-ci-check.md` (Step 10c). It gives no stop rule for the poll. State that polling ends when no check is pending and the list is non-empty. Add a minimum of one 30-second re-read after the first non-empty list, so a late-registering job doesn't read as "all passed".

- [minor] m9. `req-001-p9-ci-check.md` and ship Step 10 (draft rule). Step 10 raises a ready PR when no exception waits. A later `Exception waiting (P9, 6)` leaves a ready PR in place. Fix: add `gh pr ready --undo {n}` to the exhausted-budget branch, or state that the PR body already lists the exception.

- [minor] m10. `req-009` (AC-009.1, NFR-005 in `execution-plan.md`). Both count "130 suites". This feature adds five suites (req-007 to req-011), so P4 runs 135. Fix: write "every suite" and give the count as the baseline only.

- [minor] m11. `domain-glossary.md`. "Held-back push" says "The run stops at the match", but req-003 says the run finishes other work. "Unknown check status" cites `cancelled`, but the requirements use the `cancel` bucket. "Exception-list item" covers only the red-check case, though req-003, req-004, and req-005 also raise items. Fix: align the three definitions.

## Declares / Consumes

Declares: none. Consumes: none.

## Next step

Revise the artifacts for M1 to M9, then spawn a fresh critic for iteration 2. Loop state is `design_critic-p1`, iteration 1 of cap 3.
