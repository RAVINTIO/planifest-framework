# Design-Critic Verdict (P2, combined P1 and P2 set)

**Feature:** 0000037-green-ci-before-ship
**Mode:** report-only or on (set by the orchestrator)
**Mechanical check:** clean (`node planifest-framework/scripts/consistency-check.mjs` printed `consistency-check: clean`)
**Overall:** REJECT

One major finding blocks approval. Three minor findings follow. The P1 artifacts keep their earlier pass. This review focuses on ADR-001 to ADR-014 and how they fit the requirements and the real code.

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Every criterion in req-001, req-003, req-005, req-009, req-010, and req-011 names an observable outcome and an indented `Verified by:` line. ADR-009 adds a negative fixture so the wired-command test can fail. |
| 2 Traceability | pass | Each ADR carries a `Governs` section. req-001 to req-011 map to ADR-001 to ADR-014. Only FR-009.1 and FR-009.2 (working-directory fixes) have no governing ADR. They are mechanical, so this is not a defect. |
| 3 ADRs record real decisions | pass | Each ADR lists at least three alternatives with rejection reasons. ADR-014 is conditional, but its rejected alternatives (raise all jobs, raise unconditionally) are genuine. |
| 4 Consequences are honest | pass | Each ADR lists a negative that hurts. Examples are ADR-003 (a rule in skill text blocks nothing mechanically) and ADR-010 (CI skips the real comparison). |
| 5 Scope boundaries | pass | `design.md` Scope Out excludes a `push` trigger and the consumer workflow, which people might plausibly change. |
| 6 Risks specific and mitigated | pass | R-010 to R-024 name actions. R-023 names the measurement and fallback. |
| 7 NFRs measurable | pass | 20-minute poll, 30-second interval, 10-minute job cap, and 3 fix attempts are all numbers. |
| 8 Internal consistency | fail | F-1: ADR-014 and req-010 contradict the existing 0000031 CI test and the matrix mechanics. F-2 and F-3 are smaller conflicts. |
| 9 Split step | pass | req-010 and req-011 each carry a `Split step: keep` note. req-009 has three criteria. req-001 has three. |

## Findings (severity-ordered)

- [major] `plan/current/adr/ADR-014-git-bash-leg-conditional-20-minute-cap.md` and `plan/current/requirements/req-010-windows-git-bash-leg.md`: the 20-minute branch cannot be built as written, and it breaks an existing test.
  - Evidence: `.github/workflows/planifest.yml` defines `timeout-minutes: 10` once on the `test-suite` job, and `windows-latest` is a leg of its matrix. A job-level value applies to every leg. ADR-014 decision 2 says P3 "raises that leg's `timeout-minutes` to 20" and names no mechanism. A per-leg value needs an expression such as `${{ matrix.os == 'windows-latest' && 20 || 10 }}`, or a `matrix.include` entry. `planifest-framework/tests/test-0000031-req-001-003-ci-jobs.sh` line 45 asserts `timeout-minutes:[[:space:]]*10$` on the `test-suite` block. Either mechanism makes that assertion fail. req-010 states "the existing 0000031 test keeps passing", which is true only for the 10-minute branch. ADR-014 decision 5 amends only the new req-010 test.
  - Fix: in ADR-014 decision 2, name the mechanism (the `matrix.os` expression). Add a decision that P3 edits line 45 of `test-0000031-req-001-003-ci-jobs.sh` to accept that expression, with the 10 default kept for the ubuntu and macOS legs. Name the owning stream. Correct the req-010 sentence "keeps passing" with an indented `Amended (P2):` line. Add the test edit to ADR-014 Consequences as a negative.

- [minor] `plan/current/adr/ADR-006-post-p6-revalidation-loop-cap.md` and `plan/current/requirements/req-005-post-p6-revalidation.md`: the exception line `Exception waiting (P6, revalidation)` breaks the log format.
  - Evidence: `planifest-framework/standards/autonomous-run-standards.md` defines `Exception waiting (P{N}, {item})`, where `{item}` is one of seven numbered items (line 33 onward). An exhausted budget is item 6. ADR-002 correctly writes `(P9, 6)`, and ADR-003 and ADR-004 write `(P{N}, 7)`.
  - Fix: write `Exception waiting (P6, 6)` in both files, and state that item 6 is the exhausted approach budget. Any test that greps for the line should match this form.

- [minor] `plan/current/adr/ADR-002-p9-polls-pr-checks-and-fixes-red.md` and `plan/current/adr/ADR-014-git-bash-leg-conditional-20-minute-cap.md`: the two ADRs can contradict each other on timing.
  - Evidence: ADR-014 may raise the Windows leg to a 20-minute cap. The Step 10c poll and the P3 and P4 poll in `design.md` both cap at 20 minutes. A leg that runs 15 to 20 minutes after a queue delay leaves the poll in `pending`, so P9 writes `P9 blocked`. ADR-002 Risks only says the window "needs review" and records no decision.
  - Fix: add a decision to ADR-014. When the cap becomes 20, the poll window becomes 30 minutes (or state that 20 stays and a pending result is the accepted outcome). Add the matching `Amended (P2):` line to req-001 and `design.md` Latency target is left for the orchestrator to amend.

- [minor] `plan/current/adr/ADR-008-p3-requirement-id-scan-agent-check.md`: the type check has no stated method.
  - Evidence: the Decision says the agent checks that "a test of the type in its `Verified by` field exists". Neither ADR-007 nor ADR-008 says how the agent tells a `unit` test from an `integration` test. P4 step 1 maps IDs only, so "the same match as P4" does not cover types. Two agents can reach different results.
  - Fix: add one rule to ADR-008. For example, the type comes from a `Test type:` comment or a test-folder convention, and an unknown type reads as `unspecified` and skips the check.

## Alternatives considered and checked without finding

- ADR-010 against the repository: `migrate-0.34.0-rerun-setup.md` is the highest migration today, and `v0.34.0` is the highest tag, so the frozen-skip path holds.
- ADR-009 against `setup.sh`: the `gate_cmd`, `shell_guard_cmd`, and `trigger_cmd` variables exist, and the trigger prints `Load the planifest-orchestrator skill`.
- ADR-012 against 0000031 ADR 001: it records the 5.1 exclusion, so the amendment is accurate. `job_block` matches ids exactly, so the new job does not disturb the `setup-powershell` assertions.
- ADR-011 counts (2, 10, 11, 8, and 31 in total) match req-009.

## Out-of-scope bugs

None filed.

## Declares / Consumes

None.
