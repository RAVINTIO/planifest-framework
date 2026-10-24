---
title: "Requirement: req-001 - p9-ci-check"
summary: "P9 reads the PR's CI checks after it raises the PR and reports the result before the final report."
status: "draft"
version: "0.1.0"
---
# Requirement: req-001 - p9-ci-check

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000037-green-ci-before-ship
**Source:** US-001
**Priority:** must-have

## User Story

As the human on the loop, I see the PR's CI result in the P9 report, so that a red PR never looks done.

## Functional Requirements

- Step 10 records `PR: #{n} {url}` in the P9 block of `{archive-dir}/build-log.md` as soon as `gh pr create` returns. It does this before any wait. Step 10b commits the line with the other leftovers.
- A draft PR for the branch may already exist when P9 starts (design decision "CI before P4"). Step 10 checks for an open PR on the branch with `gh pr view --json number,url,isDraft`. If one exists, Step 10 updates its title and body with `gh pr edit --body-file`, after the req-004 scan. It runs `gh pr ready` only when the build log holds no `Exception waiting` line. Otherwise the PR stays draft and its body lists every waiting exception, per ship Step 10 (0000033 D-003). It never raises a second PR. Step 10c reads that PR.
- Step 9 may create the `v{version}` tag locally. Step 10 pushes the branch only. The agent pushes the tag after Step 10c ends. If Step 10c adds fix commits, the agent deletes the local tag and creates it again at the new head before the push. A pushed tag never moves, so no force push happens. The tag then names the head that CI passed, or the last head if CI stays red. The final report names any fix commits.
- A new Step 10c runs after Step 10b and before Step 11. It reads checks with `gh pr checks {n} --json name,bucket,link`. It polls every 30 seconds for at most 20 minutes, or 30 minutes when ADR-014's 20-minute Git Bash cap applies. The window is the longest job cap plus 10 minutes. It does not use the `timeout` command, which macOS lacks.
- Polling ends when the list is non-empty and no check is pending, or when the window passes (20 minutes, or 30 in ADR-014's 20 branch). After the first non-empty list, the agent waits 30 seconds and rereads once more. A late-registering job then does not read as "all passed".
- The agent judges the result from the JSON, not from the exit status. `gh pr checks` exits 1 when a check fails and 8 when a check is pending, and it still prints the data. A non-zero exit with valid JSON is read as data.
- Each check maps to one result. `pass` is a pass. `fail` is red. `pending` is pending. `skipping` is skipped. `cancel`, a timed-out check, and any other value read as unknown. Unknown never counts as a pass.
- An empty check list at the end of the window reads as unknown, with the note "no checks reported".
- Step 10c writes one build-log line: `CI checks (P9): {all passed | {n} failed: {names} | pending after {window} minutes | unknown: {names}}`.
- Step 10c commits its `CI checks (P9): ...` lines, the progress line, and each fix attempt line to the archived build log. It stages that file by explicit path and uses its own commit, before Step 11. Step 11 then commits only `final-report.md`, and a session loss drops no log line. The push of this commit starts a CI run that nobody reads, which backlog 0000193 already covers.
- In `autonomous`, a red check starts a fix attempt on the feature branch. The agent fixes the cause, commits under the credential scan (req-003), pushes without force, and rereads the checks. After 3 attempts, it writes `Exception waiting (P9, 6): CI check {name} still red after 3 fix attempts`. Exception item 6 is an exhausted budget. In the same branch, the agent runs `gh pr ready --undo {n}`, so the PR no longer shows as ready while a check is red.
- In `interactive` and `continuous`, a red check goes to the human on the loop in the Step 11 message with a question about fixing it. The agent does not push a fix without that answer.
- If the status can't be read, the agent reports "CI status could not be read" and the reason. This covers only a missing `gh`, an auth failure, or output that is not valid JSON. A non-zero exit with valid JSON is not unreadable. The run does not read as done.
- A report that has any result other than all passed (red, pending, unknown, or unreadable) writes `Progress: P9 blocked at {End}: CI {result}`. It never writes `P9 done`.
- Part 4 of the final report in `planifest-framework/standards/autonomous-run-standards.md` lists each non-passing check by name and link, and states the result words above. Step 11 in other run modes gains a `CI:` line with the same content.
- If the `local-git-only` override applies, no PR exists. Step 10c logs `CI checks (P9): not run, no PR raised` and the progress line reads `done`.
- On resume at P9, the agent reads `PR: #{n}` from the build log. It rereads the checks for that PR and never runs `gh pr create` a second time. Step 2a of Resume Detection in the orchestrator skill states this.
- Names and links in the report come from `gh` fields only. The report never pastes raw check output or log text (see req-004).
- CI stays on `pull_request` only (0000031 ADR 003). The check reads the PR's own run, never a `main` run.
- **Coverage:** the check covers the head that P9 read. The Step 11 push of `final-report.md` starts a CI run that nobody reads. That gap stays deferred as backlog 0000193, and the final report words the result as "the head that P9 read".

Split step: not triggered. The requirement holds three criteria, and no fourth is added.

## Acceptance Criteria
- [ ] After `gh pr create`, the P9 build-log block holds `PR: #{n}` before Step 10c waits, and the wait ends within 20 minutes with each check mapped to pass, red, pending, skipped, or unknown. Verified by: shell test over the ship skill text, plus verify-by-execution with a stub `gh`.
  - Amended (P2): the wait ends within the window, 20 minutes, or 30 minutes in ADR-014's 20 branch.
  - Verified by: integration - shell test over the ship skill text, plus execution with a stub `gh`
  - Amended (P1): the stub `gh` cases include exit 1 with valid JSON holding a `fail` bucket, which reads `red`, and an empty list that reads unknown.
  - Amended (P1): the ship skill text also holds the existing-PR path (`gh pr view`, `gh pr edit --body-file`, `gh pr ready`), the tag push after Step 10c, and the build-log commit at the end of Step 10c.
  - Amended (P1): `gh pr ready` runs on a reused PR only when no `Exception waiting` line exists. With one, the PR stays draft, per 0000033 D-003.
- [ ] A red check in `autonomous` gets up to 3 fix-and-push attempts on the feature branch, then an `Exception waiting (P9, 6)` line. A `cancelled`, timed-out, pending, or unreadable status never reads as a pass, and the progress line reads `P9 blocked`. Verified by: shell test over the ship skill and standards text, plus verify-by-execution with a stub `gh`.
  - Verified by: integration - shell test over the ship skill and standards text, plus execution with a stub `gh`
  - Amended (P1): after the third failed attempt, the PR returns to draft with `gh pr ready --undo {n}`.
- [ ] A resumed P9 rereads the checks of the PR in the build log, never raises a second PR, and the final report part 4 names each non-passing check with its link. Verified by: shell test over the orchestrator Resume Detection text and the standards text.
  - Verified by: integration - shell test over the orchestrator Resume Detection text and the standards text

## Dependencies
- req-003 (credential scan runs before each fix commit).
- req-004 (the report cites paths and results only).
- `gh` signed in where P9 runs. Without it, the status can't be read and the run does not read as done.
- 0000031 ADR 003 (CI on `pull_request` only).
