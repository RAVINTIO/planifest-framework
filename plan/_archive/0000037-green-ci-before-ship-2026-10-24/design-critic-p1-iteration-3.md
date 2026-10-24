# Design-Critic Verdict (P1, iteration 3)

**Mode:** on (autonomous)
**Mechanical check:** clean (`node planifest-framework/scripts/consistency-check.mjs plan/current` printed `consistency-check: clean`, exit 0)
**Overall:** REJECT

**Counts:** 0 critical, 2 major, 2 minor.

The iteration 2 critical defect is fixed in substance. The two iteration 2 majors are fixed and their numbers check out against the code. The rejection rests on two new majors. Both come from the draft PR decision that fixed the critical defect.

## Iteration 2 status

| Finding | Status | Evidence |
|---------|--------|----------|
| C1 no CI run before P9 | partly resolved | `design.md` "CI before P4" and req-010, req-011, R-001, R-023 now verify the Windows legs on a draft PR. The draft PR itself has no owner, no criterion, and no scan (see M1). |
| J1 req-009 lint counts | resolved | I reran the command-position patterns over the real suites. I got 2 `grep -r` lines (`test-0000032-req-009-shell-guard-path-parity.sh:109` and its `regression/` copy), 10 `sed -i` lines, 11 `shasum` lines, and 0 GNU-tool lines. 97 `test-*.sh` and 33 `regression/` files match the stated 130. FR-009.3 skips its own file by name. FR-009.4 covers all 12 payload lines. |
| J2 two `Verified by` forms | resolved | req-006 now says the indented line governs and non-enum inline text is ignored. AC-006.2 adds a fixture case for it. |
| m1 Step 10c log lines uncommitted | resolved | req-001 commits the Step 10c lines by explicit path before Step 11. |
| m2 tag names a red head | resolved | req-001 pushes the tag after Step 10c and recreates it locally at the final head. No force push. |
| m3 inline `Verified by` bracket form | resolved | The J2 rule covers it. The indented line governs. |
| m4 stale "nothing deferred" | partly resolved | `scope.md` and `feature-brief.md` are fixed. `design.md` line 66 still says "Deferred: nothing deferred" before the amendment (see m2 below). |
| m5 lint marker against skip guard | resolved | req-009 FR-009.4a and the req-010 dependency name which mechanism applies. |

Resolved: 6 of 8. Partly resolved: 2 (C1, m4). Open: 0.

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | fail | The draft PR step has no criterion (M1). Every other criterion states an observable outcome with an enum `Verified by` line. |
| 2 Traceability | pass | Each `Source:` field in req-001 to req-011 resolves to US-001 to US-011 in `design.md`. |
| 3 ADRs record real decisions | n/a | No ADRs exist at P1. The P2 critic covers this row. |
| 4 Honest consequences | n/a | Same as row 3. |
| 5 Scope boundaries | pass | `scope.md` Out and Deferred list plausible exclusions. Deferrals carry backlog IDs 0000193 and 0000199. |
| 6 Risks specific and mitigated | pass | R-001, R-023, and R-024 name actions. R-024 promises a body text that no requirement writes (see M1). |
| 7 NFRs measurable | pass | NFR-001 to NFR-005 each carry a number or a deterministic check. |
| 8 Internal consistency | fail | req-001 `gh pr ready` contradicts the existing ship rule on draft PRs (M2). |
| 9 Split step | pass | All 11 requirements hold three criteria and carry a `Split step` note. |

## Findings (severity-ordered)

### Major

- [major] M1. `design.md` (Architecture, "CI before P4"), `requirements/req-010-windows-git-bash-leg.md` (Measurement and fallback), `req-011-windows-powershell-coverage.md`, `req-004-pr-body-scan.md`, `risk-register.md` (R-024). Evidence: `grep -rn -i draft plan/current` finds the orchestrator's P3 draft PR only in prose. No requirement names the skill that raises it, the commands, or the build-log record. No criterion tests it. req-004 scans the title and body only "before `gh pr create`" in ship Step 10, so the P3 `gh pr create` runs with no credential scan. That breaks the accepted Scope Lock happy answer ("The PR body passes a credential scan before `gh pr create`"). R-024 promises a body that says "P3 to P9 are in progress", and nothing writes it. No text says who polls the draft PR's checks at P3 and P4, or reuses the req-001 bucket mapping there. Both Windows criteria (AC-010.2, AC-011.1) depend on this step, yet only a prose sentence supports it. Fix: add one functional requirement and one amended criterion, in req-001 or req-010. State the owner skill (the orchestrator or the codegen agent). State that after the first P3 code commit the owner pushes, writes the title and body to files, runs `credential-scan.mjs --file`, then runs `gh pr create --draft --body-file`, and records `PR: #{n}` in the build log. State the body text. State that P3 and P4 read `gh pr checks {n} --json name,bucket,link` with the req-001 mapping and wait for the P4 head commit's run. Add a `Verified by: integration` line for a text test over that skill.

- [major] M2. `requirements/req-001-p9-ci-check.md` (second functional requirement, existing-PR path). Evidence: `planifest-framework/skills/planifest-ship-agent/SKILL.md` Step 10 ("Draft PR while an exception waits (0000033 D-003)") says the PR stays draft while any `Exception waiting` line exists and lists every waiting exception in the description. req-001 says that if a PR exists, Step 10 "then runs `gh pr ready`". The draft PR from P3 always exists, so P9 marks it ready even when an exception waits. Fix: add "Step 10 runs `gh pr ready` only when the build log holds no `Exception waiting` line. Otherwise the PR stays draft and the body lists each waiting exception by item number and path". Add a stub case for it to the amended criterion 1.

### Minor

- [minor] m1. `requirements/req-010-windows-git-bash-leg.md` (Measurement), `risk-register.md` (R-001, R-023). Evidence: P3 measures "the draft PR's first CI run", but the draft PR opens after P3's first code commit, and that commit may land before the workflow edit that adds `windows-latest`. The first run then has no Windows leg. Fix: say the measurement uses the first run that holds the `Test suite (windows-latest)` check, and that the workflow edit lands in or before the commit that opens the PR.

- [minor] m2. `design.md` (Scope, Deferred line 66) and `build-log.md`. Evidence: line 66 still says "nothing deferred" above the amendment. The "CI before P4" text was also added to `design.md` after the confirmation time (24 Oct 2026 @ 12:46 AM BST), and the build log records it as a `Decision (P1)` and not as a deviation. A visible draft PR from P3 to P9 is a behaviour change that the human on the loop confirmed nowhere. Fix: delete the stale sentence, and add a `Deviation (P1)` line for the draft PR decision so the confirm step shows it.

## Declares / Consumes

Declares: none. Consumes: none.

## Next step

Revise for M1 and M2 and the two minors, then spawn a fresh critic for the P1 gate. Loop state is `design_critic-p1`, iteration 3 of cap 3. If this fails the cap, the orchestrator escalates under `planifest-loop-runner`.
