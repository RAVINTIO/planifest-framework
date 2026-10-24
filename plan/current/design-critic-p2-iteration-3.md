# Design-Critic Verdict (P2, iteration 3, combined P1 and P2 set)

**Feature:** 0000037-green-ci-before-ship
**Mode:** report-only or on (set by the orchestrator)
**Mechanical check:** clean (`node planifest-framework/scripts/consistency-check.mjs` printed `consistency-check: clean`)
**Overall:** APPROVE

No critical or major finding remains. Three minor findings follow. None blocks the human's gate. P3 or the orchestrator can fix them with an `Amended (P2):` line.

## Iteration 2 findings

| ID | Grade | Status | Evidence |
|----|-------|--------|----------|
| F-5 | major | resolved | ADR-008 Type check now compares the declared type with a `# Verified by: {type}` header in the mapped suite. It no longer judges what the test does. req-006 (lines 37 and 38) states the same method. The `unit` versus `integration` conflict in req-001 to req-006 no longer affects the check. The build-log Decision (P2) records the change. |
| F-6 | minor | resolved | `design.md` line 32 carries an `Amended (P2):` line that covers every 20-minute figure. req-001 lines 24 and 45, ADR-002 lines 29, 62, and 68, execution-plan NFR-001, feature-brief line 105, domain-glossary Pending check, and risk-register R-004 all state "20 minutes, or 30 in ADR-014's 20 branch". ADR-002 Risks now points to ADR-014 decision 2a. |
| F-7 | minor | resolved | ADR-014 decision 5 names the expression `${{ matrix.os == 'windows-latest' && 20 || 10 }}`. Negative consequences now list the edit to the 0000031 suite and the longer poll window. Line 45 of `test-0000031-req-001-003-ci-jobs.sh` still asserts `timeout-minutes:[[:space:]]*10$`, as decision 2 says. |
| F-8 | minor | resolved | ADR-010 decision 7 and req-008 FR-008.5a print `SKIP: no v* tags fetched` and exit 0 when no `v*` tag exists. FR-008.5a requires a fixture with no tags. The ADR-010 summary and the Alternatives table agree. |

Resolved: 4 of 4.

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Each criterion in req-001 to req-011 names an observable outcome and an indented `Verified by:` line. AC-008.1 uses a fixture repository. |
| 2 Traceability | pass | Each ADR has a `Governs` or "Requirements governed" section. ADR-001 to ADR-014 cover req-001 to req-011. |
| 3 ADRs record real decisions | pass | Each ADR lists at least four alternatives with rejection reasons. ADR-010 and ADR-014 reject real options such as failing on a missing tag and raising every cap. |
| 4 Consequences are honest | pass | ADR-010 (CI skips the comparison), ADR-014 (a weaker runaway-job stop and a 0000031 suite edit), and ADR-003 each list a real cost. See F-9 for one missing cost. |
| 5 Scope boundaries | pass | `design.md` Scope Out excludes a `push` trigger, agent merges, and the consumer workflow. |
| 6 Risks specific and mitigated | pass | R-004, R-013, R-017, and R-023 name actions and numbers. See F-10 for one stale mitigation. |
| 7 NFRs measurable | pass | NFR-001 gives 20 or 30 minutes and a 30-second interval. Job caps are 10 minutes. Fix attempts are 3. |
| 8 Internal consistency | pass | The iteration 2 conflicts are gone. F-10 and F-11 are small residues. |
| 9 Split step | pass | req-010 and req-011 carry `Split step: keep`. req-008 carries one too. The other requirements hold three criteria or fewer. |

## Findings (severity-ordered)

- [minor] F-9, `plan/current/adr/ADR-008-p3-requirement-id-scan-agent-check.md`: the header method has an unrecorded cost, and the rejected content-based method sits outside the Alternatives table.
  - Evidence: The header is a claim by the suite author. The check confirms the claim exists and does not confirm the suite tests that type. Negative consequences list only agent determinism and two files. The "Rejected: telling types apart by what the test does" line sits inside the Decision section, and the table omits it.
  - Fix: add a Negative consequence: "A header can name a type the suite does not test, so the check catches a missing type and not a wrong label." Add the content-based method as a row in the Alternatives table.

- [minor] F-10, `plan/current/adr/ADR-010-migration-diff-targets-untagged-migration.md` Risks and `plan/current/risk-register.md` R-017: the mitigation says the skip line "names the tag", which is false for the no-tags skip.
  - Evidence: ADR-010 Risks says "the skip line names the tag". Decision 7 prints `SKIP: no v* tags fetched`, which names no tag. R-017 says the test prints `SKIP` when the base tag is absent and does not mention the no-tags line.
  - Fix: reword both to "the skip line states its reason, and names the tag where one exists". Keep the local post-P6 run as the real mitigation.

- [minor] F-11, `plan/current/requirements/req-008-migration-branch-diff-test.md` AC-008.2: the criterion does not cover the no-tags case that FR-008.5a requires.
  - Evidence: AC-008.2 names "a fixture where the base tag is absent" and "a target whose release tag exists". FR-008.5a requires a fixture repository with no tags at all, and iteration 2 asked for an `Amended (P2):` line. None exists. FR-008.5a also sits before FR-008.5 in the list.
  - Fix: add an indented `Amended (P2):` line under AC-008.2. It says the criterion also covers a fixture with no `v*` tag, which prints `SKIP: no v* tags fetched` and exits 0 (FR-008.5a).

## Checked against the code without finding

- Line 45 of `planifest-framework/tests/test-0000031-req-001-003-ci-jobs.sh` asserts `timeout-minutes:[[:space:]]*10$`, which matches ADR-014 decision 2.
- The validate-agent skill step 1 produces a coverage table `REQ-ID | AC | Covered by test | Pass/Fail`. ADR-008 describes it correctly as an ID match.
- Backlog 0000199 exists at `plan/backlog/0000199-ci-checkout-fetches-no-release-tags/entry.md`, as ADR-010 and req-008 cite.
- The build-log Decision (P2) that says the type check "tells types apart by what the mapped test does" is superseded by a later Decision line. The later line governs.

## Out-of-scope bugs

None filed.

## Declares / Consumes

None.
