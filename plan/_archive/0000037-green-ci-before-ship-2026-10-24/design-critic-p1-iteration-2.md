# Design-Critic Verdict (P1, iteration 2)

**Mode:** on (autonomous)
**Mechanical check:** clean (`node planifest-framework/scripts/consistency-check.mjs` printed `consistency-check: clean`, exit 0)
**Overall:** REJECT

**Counts:** 1 critical, 2 major, 5 minor.

Iteration 1 is fixed in substance. Eight of nine majors and all eleven minors are resolved. The rejection rests on one new critical defect and two majors. The critical defect is a sequencing gap between the `pull_request`-only CI trigger and the P3 and P4 gates in req-010 and req-011. Each defect is cheap to fix before the human on the loop sees the artifacts.

## Iteration 1 status

| Finding | Status | Evidence |
|---------|--------|----------|
| M1 req-007 JSON claim | resolved | AC-007.3 as amended asserts stdout contains `Load the planifest-orchestrator skill`. The fixture workspace holds `planifest-framework/` and no sentinel. The hook at `hooks/enforcement/auto-trigger-orchestrator.mjs` prints that text. |
| M2 Git Bash 10-minute cap | partly resolved | R-023, the req-010 fallback, and the design risk now exist. The measurement step they rely on can't happen at P3 (see C1). |
| M3 `Verified by` enum | partly resolved | Every indented `Verified by:` line now uses an enum value. The original inline text in req-001 to req-004 and req-007 to req-011 still holds non-enum values (see J2). |
| M4 req-009 `sed -i` baseline | partly resolved | The count of 10 payload lines is correct and the marker rule is defined. Two `grep -rn` payload lines are still unaccounted for (see J1). |
| M5 `gh` exit codes | resolved | req-001 and req-002 judge from the JSON. Amended lines add the exit-1 stub case. |
| M6 `git commit -- {path}` | resolved | req-003 scans the index blob and the working-tree file for every path in the commit. |
| M7 risk register contradictions | resolved | R-004, R-017, R-018, and R-019 now match req-001, req-008, req-006, and req-005. |
| M8 req-008 positive path | resolved | AC-008.3 is amended to the post-P6 local run. FR-008.8 adds the P3 fixture check. CI skip is tied to 0000199. |
| M9 deferred gaps | resolved | `scope.md`, `design.md`, and the brief list 0000193 and 0000199 under Deferred. |
| m1 to m11 | resolved | Leg count and cost, `--watch` text, versions (0.35.0), link paths, req-011 substring match, template hints, `mergedAt` lookup, poll stop rule, `gh pr ready --undo`, "130" baseline wording, and glossary terms all check out. |

Resolved: 18 of 20 findings fully (M1, M5 to M9, m1 to m11). Partly resolved: 3 (M2, M3, M4). Open: 0.

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | fail | AC-010.2 and AC-011.1 need a CI run that can't exist before P9 (C1). AC-009.3 can't reach 0 findings (J1). |
| 2 Traceability | pass | Each `Source:` field in req-001 to req-011 resolves to US-001 to US-011 in `design.md`. |
| 3 ADRs record real decisions | n/a | No ADRs exist at P1. The P2 critic covers this row. |
| 4 Honest consequences | n/a | Same as row 3. |
| 5 Scope boundaries | pass | Three plausible exclusions. Two deferrals now sit in `scope.md` with backlog IDs. |
| 6 Risks specific and mitigated | fail | R-023 and R-001 mitigate through a P3 CI measurement that can't run (C1). |
| 7 NFRs measurable | pass | NFR-001 to NFR-005 each carry a number or a deterministic check. |
| 8 Internal consistency | fail | The P3 "first CI run" in req-010 contradicts the `pull_request`-only trigger in `design.md` Constraints (C1). Inline `Verified by` text contradicts req-006's rule (J2). |
| 9 Split step | pass | All 11 requirements hold three criteria. Each has a `Split step` note and a matching build-log `Decision (P1)` line, or states "not triggered". |

## Findings (severity-ordered)

### Critical

- [critical] C1. `plan/current/requirements/req-010-windows-git-bash-leg.md` (measurement, skip rule, AC-010.2), `req-011-windows-powershell-coverage.md` (AC-011.1), `risk-register.md` (R-001, R-023), `design.md` (Constraints, Risks). Evidence: `.github/workflows/planifest.yml` triggers on `pull_request` only, and `design.md` Constraints forbid a `push` trigger. The only step that raises a PR is ship Step 10, at P9. So no CI run exists at P3 or P4. req-010 says "P3 measures the Git Bash leg's run time on its first CI run", "The leg must end green before P4", and "A new ADR from stream 04's P2 block" records a cap raise that the P3 measurement would trigger. P2 ends before P3 starts. None of this can happen. The first Windows run is the P9 run. There the fix loop allows 3 attempts at up to 20 minutes each, and R-001 expects many failing suites. A timeout reads as `cancel`, and the PR never reads as done. Fix: choose one path and write it into req-010, req-011, R-001, R-023, and `design.md`. Option A: P3 pushes the branch and raises a draft PR once the workflow edits land, as `custom-001` already permits. Step 10 then reuses that PR number from the build log and runs `gh pr ready`, not a second `gh pr create`. This amends req-001's resume rule and needs the human on the loop to confirm it. Option B: state that the leg's first run is at P9. Drop "green before P4", and make AC-010.2 and AC-011.1 P9 outcomes. Pre-decide the 20-minute cap in the P2 ADR as a conditional, so no P3 measurement gates it.

### Major

- [major] J1. `plan/current/requirements/req-009-portable-suites-and-lint.md` (baseline table, FR-009.3, FR-009.4, AC-009.3). Evidence: `test-0000032-req-009-shell-guard-path-parity.sh:109` and its `regression/` copy hold `"grep -rn 'foo' src/"`. The `grep -r` rule matches both lines, since neither uses `-H`, `-l`, `-L`, or `-c`. The table counts 0 for this rule and calls them "payload strings, not commands". The marker step covers only the 10 `sed -i` lines. After P3 the lint still reports 2 findings, so AC-009.3 ("0 findings") fails. A second gap: FR-009.3 scans `test-*.sh`, and the new lint suite holds its fixture lines in a heredoc inside the same file. It would flag itself. The GNU-tool rule also needs a command-position match, or `timeout-minutes:` in `test-0000031-req-001-003-ci-jobs.sh` lines 45 and 66 would match `timeout`. Fix: add the 2 `grep -rn` payload lines to the table with the `# portable-ok: payload string` marker, giving 31 lines today. Define each rule as a command-position pattern. State that the lint skips its own file, or that fixture lines carry the marker.

- [major] J2. `plan/current/requirements/req-006-verified-by-and-p3-scan.md` (rule for two forms) against `req-001` to `req-004` and `req-007` to `req-011` (inline `Verified by`). Evidence: req-006 says "If a criterion carries both forms, both must name the same type" and "The P3 and P4 scans read either form". The original criterion lines still hold inline text such as `Verified by: shell test over the ship skill text` and `(Verified by: shell suite)`. The indented lines say `integration`. A P3 scan that follows req-006 to the letter finds two forms with different values in 9 of 11 files of this feature, and `plan/current/requirements/` is the scan's own input. The ratchet blocks editing the inline text. Fix: add a rule to req-006 and to the P3 scan text. Where an indented `Verified by:` line exists, it governs, and inline text after `Verified by:` that is not an enum value is ignored. Add a fixture case for it to AC-006.2.

### Minor

- [minor] m1. `req-001-p9-ci-check.md` (Step 10c). Step 10c writes `CI checks (P9)`, the progress line, and each fix attempt into `{archive-dir}/build-log.md` after Step 10b. Step 11 commits `final-report.md` only. Those lines stay as uncommitted leftovers, and a session loss drops them. Fix: add a commit of the build log by explicit path at the end of Step 10c, or widen the Step 11 commit. Note that the push starts a CI run, which 0000193 already covers.
- [minor] m2. `req-001-p9-ci-check.md` (fix loop). A fix commit lands after the `v{version}` tag, which Step 10 already pushed. The tag then names a red head. Fix: state that the tag does not move (no force), and that the final report names the fix commits.
- [minor] m3. `req-005-post-p6-revalidation.md` and `req-006-verified-by-and-p3-scan.md`. The inline form `Verified by: integration (a fixture repo ...)` is neither defined form, because the detail follows a bracket and not ` - `. Fix: write `Verified by: integration - a fixture repo ...`, or allow a parenthesised detail in req-006.
- [minor] m4. `scope.md` (Deferred) and `design.md` (Scope). Each still says "nothing deferred" and then amends it two lines later. Fix: if the artifacts are editable at the confirm step, delete the stale sentence.
- [minor] m5. `req-010-windows-git-bash-leg.md` (Dependencies). It says req-009's lint marker may be used "only with a recorded reason", but the two skip mechanisms differ. A `# portable-ok` marker silences the lint. A `SKIP (windows)` guard skips a suite. State which one a Git Bash failure uses, so P3 does not mix them.

## Declares / Consumes

Declares: none. Consumes: none.

## Next step

Revise for C1, J1, and J2, then spawn a fresh critic for iteration 3. Loop state is `design_critic-p1`, iteration 2 of cap 3. C1 needs a decision from the human on the loop, because Option A changes the shape of Step 10.
