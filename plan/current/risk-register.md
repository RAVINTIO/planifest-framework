---
title: "Risk Register - green CI before ship"
summary: "Technical, operational, security, and compliance risks for 0000037 with their mitigations."
status: "draft"
version: "0.1.0"
---
# Risk Register - green CI before ship

**Skill:** [spec-agent](../../planifest-framework/skills/planifest-spec-agent/SKILL.md) (updated by any agent that identifies a new risk)
**Feature:** 0000037-green-ci-before-ship
**Version:** 0.35.0
**Overall Risk Level:** medium

> Every entry is specific to this feature. R-001 to R-005 come from the Risks section of `design.md`. R-006 onward are added by the spec agent.

## Risks

| ID | Category | Description | Likelihood | Impact | Mitigation | Status |
|----|----------|------------|------------|--------|-----------|--------|
| R-001 | technical | The Git Bash leg fails many suites on its first run on the draft PR, which the orchestrator raises after the P3 push that adds the leg. | high | medium | Fix or skip each failing suite, and record the reason for each skip, per backlog 0000093. Each later push reruns CI on the draft PR, so P3 sees the result before P4. | open |
| R-002 | technical | Windows PowerShell 5.1 differs from PowerShell 7 in encoding and JSON handling, so `setup.ps1` behaves differently on each. | medium | medium | Guard each difference in `setup.ps1`, and test each guard under PowerShell 5.1 (req-011). | open |
| R-003 | operational | The credential scan flags false positives and stops an `autonomous` run. | medium | low | The stop names the file and line. The human on the loop clears the match. | open |
| R-004 | operational | Polling `gh pr checks` waits on a slow or queued runner. | medium | low | Poll every 30 seconds for at most 20 minutes, or 30 in ADR-014's 20 branch, then report the remaining checks as pending (req-001). | open |
| R-005 | operational | Eleven stories in one run stretch P3 and P4. | medium | medium | Split the work into parallel streams by file ownership. | open |
| R-006 | security | A cancelled or timed-out check reads as a pass, so a red PR reads as done. | low | high | Map `cancelled` and timed-out conclusions to unknown, never to pass. Add a suite case for each conclusion (req-001, req-002). | open |
| R-007 | operational | A check status that `gh` cannot read lets the run finish with a red PR unseen. | medium | high | Report the unreadable status, and the run does not read as done. The assumption text in A-001 conflicts with this rule, so the Architecture Layer rule applies. | open |
| R-008 | security | The pre-commit credential scan misses a credential when `gitleaks` is absent, because only the regex patterns run. | medium | high | Run the P8 regex patterns on every scan. Add suite cases with known credential formats. Hold back the push on any match (req-003). | open |
| R-009 | security | The PR body changes after the scan and reaches the PR without a scan. | low | medium | Scan the exact body text that `gh pr create` receives. Do not edit the body after the scan (req-004). | open |
| R-010 | security | A scan log line copies the matched credential into `plan/current/build-log.md`, which the run commits. | low | high | Each `Credential scan (P{N})` line names the file and line only, never the matched value (req-003, req-004). | open |
| R-011 | security | A new CI job gains secrets or broader permissions than the workflow allows. | low | high | Each new job keeps `permissions: contents: read`, no secrets, and `timeout-minutes: 10`, per 0000031-ADR-003 (req-010, req-011). | open |
| R-012 | compliance | The Windows legs run before the ADR that amends 0000031-ADR-001 exists, so CI contradicts a recorded decision. | low | medium | Write the amending ADR before the code for req-010 and req-011. | open |
| R-013 | operational | The two new Windows legs add CI minutes to every PR. | medium | low | Keep `timeout-minutes: 10` on each new job, which caps the cost at 20 minutes per PR. If R-023 raises the Git Bash cap to 20 minutes, the cost rises to 30 minutes per PR. | open |
| R-014 | operational | The consumer workflow copy at `planifest-framework/hooks/planifest.yml` stays unchanged, so consumer projects get no new CI check. | high | medium | Keep the change out of scope, as the design states. The human on the loop decides any later change. | open |
| R-015 | technical | The portability lint flags legitimate tool use or misses a GNU and BSD difference. | medium | low | Add suite cases for a flagged form and an allowed form. Name `grep -r` without `-H` as the first rule (req-009). | open |
| R-016 | technical | The wired-command test passes on macOS and fails on Windows, because it depends on path separators or the working directory. | medium | medium | Run the command string as `setup.sh` writes it. Run every suite from any working directory (req-007, req-009). | open |
| R-017 | technical | The migration branch-diff test cannot read the release diff in CI, because CI fetches no tags, so the test passes by skipping. | medium | medium | The test prints `SKIP` and exits 0 when the base tag is absent (req-008). CI skips until backlog 0000199 makes it fetch tags. Run the suite locally with tags present to get the real result. | open |
| R-018 | operational | The P3 requirement-ID scan blocks P3 close on a requirement with no mapped test, such as a docs-only requirement. | medium | low | The scan maps each requirement ID to its tests. A criterion with no `Verified by` field skips the type check and keeps the ID check (req-006). A docs-only requirement uses `manual` with a one-line reason. | open |
| R-019 | operational | Post-P6 revalidation reruns checks on docs-only commits, adding time and surfacing late failures. | medium | low | Run the product's doc-check command when `planifest-overrides/doc-checks.yml` declares one. Otherwise rerun P4 steps 0 to 5. Write each rerun to the `Revalidation (P6)` build-log line (req-005). | open |
| R-020 | operational | The P9 fix-and-push loop pushes up to three times and adds three CI runs, and a flaky test can read as green on the last attempt. | low | medium | Stop after three attempts, then raise an exception-list item. Log each attempt in the build log (req-001). | open |
| R-021 | operational | P9 reads the checks of a different PR, because the PR number is missing or wrong. | low | medium | Write the PR number to the build log before the wait. Read checks for that number only (req-001). | open |
| R-022 | operational | The GUTD check reports the last merged PR's checks as the state of `main`, when a commit landed on `main` without a PR. | low | medium | The GUTD report names the PR number it read, so the human on the loop sees which PR the result covers (req-002). | open |
| R-023 | operational | The Git Bash leg passes its 10-minute cap. A timeout reads as `cancel`, so the PR never reads as done. | medium | high | P3 measures the leg on the draft PR's first CI run that holds the `windows-latest` leg. If the leg passes 10 minutes, P3 raises that leg's cap to 20 minutes under the conditional ADR that P2 wrote, which amends 0000031 ADR 003 for that leg only. Sharding is the second fallback. The new suites also add time to the macOS leg, which has about 2.5 minutes of headroom (req-010). | open |
| R-024 | operational | The draft PR shows the human on the loop an unfinished branch while P3 to P9 run. | low | low | The PR stays in draft state. The orchestrator writes its body under "CI before P4" in `design.md`, citing paths only and scanned by `credential-scan.mjs`. P9 Step 10 marks it ready only when no exception waits. | open |

## Assumptions Logged as Risks

Documented assumptions from the specification are logged here with likelihood: medium.

| ID | Assumption | Impact if Wrong | Status |
|----|-----------|----------------|--------|
| A-001 | `gh` is installed and signed in wherever P9 and GUTD run. | The check reports that it could not run. The design's assumption text says the run carries on, but the Architecture Layer says the run does not read as done (see R-007). | open |
| A-002 | `gitleaks` may be absent. | Only the regex patterns run, so recall is lower (see R-008). | open |
| A-003 | Windows runners have Git Bash and Windows PowerShell 5.1 preinstalled. | The new Windows legs need an install step. The draft PR's first CI run shows this at P3. | open |
| A-004 | `gh run list --branch main` returns no usable conclusion, so GUTD reads the last merged PR's checks instead. | None, because the design does not read a `main` run. | open |
| A-005 | `gh run list` returns a usable conclusion for every `pull_request` run. | P9 and GUTD find no result to report. | open |
| A-006 | `.github/workflows/planifest.yml` triggers on `pull_request` only. | A future `push` trigger makes the merged-PR lookup redundant, but not wrong. | open |
