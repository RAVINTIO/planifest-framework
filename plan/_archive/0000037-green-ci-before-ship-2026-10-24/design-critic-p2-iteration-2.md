# Design-Critic Verdict (P2, iteration 2, combined P1 and P2 set)

**Feature:** 0000037-green-ci-before-ship
**Mode:** report-only or on (set by the orchestrator)
**Mechanical check:** clean (`node planifest-framework/scripts/consistency-check.mjs` printed `consistency-check: clean`)
**Overall:** REJECT

One major finding blocks approval. Three minor findings follow. All four iteration 1 findings are resolved, but the fix for F-4 creates the new major finding.

## Iteration 1 findings

| ID | Grade | Status | Evidence |
|----|-------|--------|----------|
| F-1 | major | resolved | ADR-014 decision 2 names the `matrix.os` expression and the edit to line 45 of `test-0000031-req-001-003-ci-jobs.sh`. Line 45 still asserts `timeout-minutes:[[:space:]]*10$`, and decision 2 widens it. req-010 carries an `Amended (P2)` line and a corrected FR sentence. |
| F-2 | minor | resolved | ADR-006 and req-005 now write `Exception waiting (P6, 6)`. Item 6 is the exhausted budget in `autonomous-run-standards.md`. |
| F-3 | minor | resolved, with residue | ADR-014 decision 2a sets a 30-minute window in the 20 branch. ADR-002 and req-001 carry it. Other artifacts still say 20 (see F-6). |
| F-4 | minor | resolved, new defect | ADR-008 now states a type method. The method conflicts with the requirements (see F-5). |

Resolved: 4 of 4.

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Each criterion in req-001 to req-011 names an observable outcome and an indented `Verified by:` line. ADR-009 adds a negative fixture. |
| 2 Traceability | pass | Each ADR has a `Governs` or "Requirements governed" section. req-001 to req-011 map to ADR-001 to ADR-014. |
| 3 ADRs record real decisions | pass | Each ADR lists at least four alternatives with rejection reasons. ADR-014 rejects raise-all, raise-unconditionally, shard-now, and defer. |
| 4 Consequences are honest | pass | ADR-003 (a skill rule blocks nothing mechanically), ADR-010 (CI skips the comparison), and ADR-014 (a weaker runaway-job stop) each list a real cost. |
| 5 Scope boundaries | pass | `design.md` Scope Out excludes a `push` trigger, agent merges, and the consumer workflow. |
| 6 Risks specific and mitigated | pass | R-004, R-013, and R-023 name actions and numbers. |
| 7 NFRs measurable | pass | 20-minute poll (30 in the 20 branch), 30-second interval, 10-minute job cap, and 3 fix attempts are numbers. |
| 8 Internal consistency | fail | F-5 (ADR-008 against 14 criteria). F-6 and F-7 are smaller conflicts. |
| 9 Split step | pass | req-010 and req-011 carry `Split step: keep`. req-001, req-009, and the rest hold three criteria or fewer. |

## Findings (severity-ordered)

- [major] F-5, `plan/current/adr/ADR-008-p3-requirement-id-scan-agent-check.md` against req-001 to req-004, req-010, and req-011: the type method fails criteria the requirements label correctly.
  - Evidence: ADR-008 defines `unit` as "the suite reads files or calls one function, with no workspace" and `integration` as "the suite runs a script, hook, or setup in a temporary workspace". It says a mismatch blocks P3. The requirements label shell suites that only read skill, override, standards, or workflow text as `integration`. Examples are req-001 lines 45, 50, 53, req-002 lines 37, 40, 42, req-004 lines 36 and 40, req-003 line 40, req-010 lines 46 and 51, and req-011 lines 41 and 46. Under the ADR-008 method those suites read as `unit`, so about 14 criteria mismatch. req-005 line 55 and req-006 line 50 label the same kind of text test `unit`, so the requirements disagree with each other. `standards/testing-standards.md` line 13 defines unit as pure functions, so it does not settle shell text tests.
  - Fix: add a rule to ADR-008. A shell suite counts as `integration`, whatever it reads, and `unit` covers a suite that calls one exported function. Then relabel req-005 line 55 and req-006 line 50 with an `Amended (P2):` line. Alternatively, drop the content-based test and make the check compare the declared type with the type word in the mapped test's header comment.

- [minor] F-6, stale 20-minute statements after ADR-014 decision 2a: `plan/current/design.md` (Latency target, line 31, and step 6 of "CI before P4"), `plan/current/execution-plan.md` NFR-001 (line 39), `plan/current/feature-brief.md` (line 105), `plan/current/domain-glossary.md` (Pending check, line 22), `plan/current/risk-register.md` R-004 (line 23), `plan/current/requirements/req-001-p9-ci-check.md` (line 24, "when the 20 minutes pass"), and `plan/current/adr/ADR-002-p9-polls-pr-checks-and-fixes-red.md` (Consequences line 62, Risks lines 67 and 68).
  - Evidence: ADR-014 decision 2a and the build-log Deviation (P2) set a 30-minute window in the 20 branch. These lines state 20 with no qualifier. ADR-002 Risks still says the window "needs review", which decision 2a now settles. Hard Limit 7 requires the artifacts to match.
  - Fix: add an indented `Amended (P2):` line under each, saying the window is 30 minutes in ADR-014's 20 branch. In ADR-002 Risks, replace "needs review" with a pointer to ADR-014 decision 2a.

- [minor] F-7, `plan/current/adr/ADR-014-git-bash-leg-conditional-20-minute-cap.md` decision 5 and `plan/current/requirements/req-010-windows-git-bash-leg.md`: the 20 branch has two statements of what the test expects.
  - Evidence: decision 5 says the test "expects 20 for the `windows-latest` leg only". Decision 2 and the `Amended (P2)` line in req-010 say it expects the expression `${{ matrix.os == 'windows-latest' && 20 || 10 }}`. The `Amended (P1)` line also says 20. A test cannot match both. The Negative consequences omit the cost of editing the 0000031 suite.
  - Fix: reword decision 5 to name the expression. Add a negative consequence: P3 edits a passing 0000031 assertion in the 20 branch, and a reviewer must confirm it widens and does not remove the check.

- [minor] F-8, `plan/current/adr/ADR-010-migration-diff-targets-untagged-migration.md` decisions 3 and 7, and req-008 FR-008.3 and FR-008.5: the base tag has no name when CI fetches no tags.
  - Evidence: decision 3 defines the base as "the highest `v*` tag below the target's version". CI fetches no tags, so no tag exists to name. Decision 2 passes vacuously, since the target exceeds every tag, and decision 7 then has no `{base}` to verify or print. R-017 says the skip line "names the tag". The check can fail or print an empty name in CI, which turns every PR red.
  - Fix: add a decision. When no `v*` tag exists, the check prints `SKIP: no v* tags fetched (backlog 0000199)` and exits 0. Add a fixture case to AC-008.2 with an `Amended (P2):` line.

## Checked against the code without finding

- ADR-002 bucket values (`pass`, `fail`, `pending`, `skipping`, `cancel`) and `gh pr ready --undo` match the `gh` interface. The ship skill Step 10 pushes the tag today (line 304), so moving it after Step 10c is a real change.
- ADR-003 and ADR-004 exception item 7, and ADR-002 item 6, match `autonomous-run-standards.md`.
- ADR-006 matches the current `## Post-P6 revalidation` section (5-cycle cap, skip case) and the archived 0000033 ADR-012.
- ADR-012 matches 0000036 ADR-005 (5.1 reads a BOM-less file in the ANSI code page) and Q-005 and Q-014 in `quirks.md`.
- The existing `setup-powershell` job and its assertions stay untouched by the new `setup-powershell-51` job.

## Out-of-scope bugs

None filed.

## Declares / Consumes

None.
