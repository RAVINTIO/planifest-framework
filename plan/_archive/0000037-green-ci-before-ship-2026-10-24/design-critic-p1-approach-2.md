# Design-Critic Verdict (P1, approach 2, iteration 1)

**Mode:** on (autonomous)
**Mechanical check:** clean (`node planifest-framework/scripts/consistency-check.mjs` printed `consistency-check: clean`, exit 0)
**Overall:** APPROVE

**Counts:** 0 critical, 0 major, 3 minor.

The two iteration 3 majors are fixed in the text. The "CI before P4" step in `design.md` is now complete enough to execute and verify. The three minors do not block the gate.

## Iteration 3 status

| Finding | Status | Evidence |
|---------|--------|----------|
| M1 draft PR has no owner, steps, or scan | resolved | `design.md` "CI before P4" names the orchestrator as owner and lists 7 steps. It orders req-003 first, scans both files with `credential-scan.mjs --file`, runs `gh pr create --draft --body-file`, and writes `Draft PR (P3): #{n} {url}`. It gives the body text and the check read with the req-001 bucket rules. req-004 extends the scan rule to the P3 PR. The `Deviation (P1)` line in `build-log.md` records it. |
| M2 `gh pr ready` ignores waiting exceptions | resolved | req-001 second functional requirement and the `Amended (P1)` line under criterion 1 gate `gh pr ready` on no `Exception waiting` line. This matches `planifest-ship-agent/SKILL.md` Step 10 ("Draft PR while an exception waits"). req-001 also runs `gh pr ready --undo` after the third failed fix. |
| m1 first run may lack the Windows leg | resolved | req-010 measures the first run that holds `windows-latest`. `design.md` step 2 pushes only after the req-010 and req-011 workflow edits. |
| m2 stale "nothing deferred" and unrecorded deviation | resolved | The `Deviation (P1, unclassified)` line for the draft PR sits in `build-log.md`. The "nothing deferred" line stays because the armed ratchet blocks removing it. A `Decision (P1)` line records that, and the amended deferred items sit under it. |

Resolved: 4 of 4.

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Every criterion in req-001 to req-011 has an indented `Verified by:` line with an enum type. The draft PR is covered through AC-010.2 and AC-011.1, which read `gh pr checks` for the P4 head. |
| 2 Traceability | pass | Each `Source:` field resolves to US-001 to US-011 in `design.md`. |
| 3 ADRs record real decisions | n/a | No ADRs exist at P1. The P2 critic covers this row. |
| 4 Honest consequences | n/a | Same as row 3. |
| 5 Scope boundaries | pass | `scope.md` and `design.md` Out list plausible builds. Deferred items carry backlog 0000193 and 0000199. |
| 6 Risks specific and mitigated | pass | R-001, R-023, and R-024 name actions and match the design text. |
| 7 NFRs measurable | pass | NFR-001 to NFR-005 carry numbers or deterministic checks. |
| 8 Internal consistency | pass | req-001 now matches ship Step 10. Exception item 6 (exhausted budget) and item 7 (credential sighting) match `autonomous-run-standards.md` lines 33 to 42. req-004 and the design agree on the scan before every `gh pr create`. |
| 9 Split step | pass | Each requirement holds three criteria and carries a `Split step` note. |

## Findings (severity-ordered)

### Minor

- [minor] m1. `plan/current/execution-plan.md` (Component Interactions and stream table). Evidence: `grep -n -i draft execution-plan.md` finds nothing. The plan does not state that stream 01 builds req-003 before the first push, or that stream 04 must land its workflow edits before the draft PR opens. The ordering sits only in `design.md` step 1 and step 2. Fix: add one sentence under the stream table: "The orchestrator raises the draft PR after req-003 and the req-010 and req-011 workflow edits land (see `design.md`, CI before P4)". Add `Orch -->|gh pr create --draft| GH` to the diagram.

- [minor] m2. `plan/current/design.md` ("CI before P4", step 6). Evidence: step 6 says P3 and P4 "read the checks for their head" but names no wait bound and no red-check action. req-001 holds the 20-minute poll for P9 only. A reader cannot tell how long P4 waits for the P4 head's run, or what a red Windows leg at P3 triggers. req-010 and req-011 give the fix-or-skip rule, but not the wait. Fix: add "P3 and P4 poll with the Step 10c rules (30 seconds, 20 minutes). A red or unknown check at P3 goes to the req-010 or req-011 fix rule, and P4 starts only when the legs for its head are green."

- [minor] m3. `plan/current/design.md` ("CI before P4", step 3). Evidence: a scan match or exit 2 "stops the step, under exception item 7". Nothing says what happens to req-010 AC-010.2 and req-011 AC-011.1, which need the draft PR. With no PR the Windows legs never run before P4. Fix: add "If the step stops, the Windows legs stay unverified, the orchestrator records `Exception waiting (P3, 7)`, and P9 verifies them on the PR it raises, with a red leg then handled by the req-001 fix loop".

## Declares / Consumes

Declares: none. Consumes: none.

## Next step

Present the P1 gate to the human on the loop. The orchestrator may fold the three minors into the next commit that touches those files. Loop state: approach 2, iteration 1.
