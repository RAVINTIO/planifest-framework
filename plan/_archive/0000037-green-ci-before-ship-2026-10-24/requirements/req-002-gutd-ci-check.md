---
title: "Requirement: req-002 - gutd-ci-check"
summary: "GUTD reports the CI result of the last merged PR after the sync steps."
status: "draft"
version: "0.1.0"
---
# Requirement: req-002 - gutd-ci-check

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000037-green-ci-before-ship
**Source:** US-002
**Priority:** must-have

## User Story

As the human on the loop, I see the CI result of the last merged PR when I send GUTD, so that a red `main` never looks healthy.

## Functional Requirements

- `planifest-overrides/instructions/custom-003-git-up-to-date-shorthand.md` gains step 5. It runs after the untracked-files report.
- Step 5 lists merged PRs with `gh pr list --state merged --base main --limit 10 --json number,url,mergedAt`. It picks the entry with the newest `mergedAt`, because the list sorts by creation date. It reads that PR's checks with `gh pr checks {number} --json name,bucket,link`.
- Step 5 never reads a `main` run. It never uses `gh run list --branch main`. CI runs on `pull_request` only (0000031 ADR 003), so no `main` run exists to read.
- The report words every result as "the last merged PR's checks", with the PR number and URL. It never says "main is green" or "main is red".
- Result words: `all passed`, `{n} failed: {names with links}`, `pending`, or `unknown: {names}`. A `cancel` bucket and any other value read as unknown. Unknown never reads as a pass.
- If the list holds no merged PR, step 5 reports "no merged PR to check".
- Step 5 judges the result from the JSON, not from the exit status. `gh pr checks` exits 1 for a failed check and 8 for a pending one, and it still prints the data.
- If `gh` is missing, signed out, or prints output that is not valid JSON, step 5 reports "CI status could not be read". It names `gh auth login` as the fix for a signed-out `gh`.
- The repository's generated `CLAUDE.md` copies the override text. A setup re-run refreshes that copy.
- Step 5 never changes steps 1 to 4. A failed or unreadable CI check does not undo the checkout or the pull.
- Step 5 does not wait. A pending check reads `pending`.
- The "Why" section of the override records the date of this change and the reason: PR #62 merged red and no agent reported it.

Split step: not triggered. The requirement holds three criteria, and no fourth is added.

## Acceptance Criteria
- [ ] After GUTD's sync steps, the report states the result of the last merged PR's checks, found through `gh pr list --state merged --base main --limit 1` and `gh pr checks`, with every red or unknown check named. Verified by: shell test over the override text, plus verify-by-execution with a stub `gh`.
  - Verified by: integration - shell test over the override text, plus execution with a stub `gh`
  - Amended (P1): the lookup requests `--limit 10 --json number,url,title,mergedAt` and picks the newest `mergedAt`. A stub list with an older PR merged later expects that PR. The generated `CLAUDE.md` copy refreshes on a setup re-run.
  - Amended (P5): the lookup requests `--limit 10 --json number,url,mergedAt` and no `title`. GUTD requests no titles, because a title is free text from the PR author.
- [ ] The override never reads a `main` run, and the report words the result as "the last merged PR's checks". With no merged PR, it reports "no merged PR to check". Verified by: shell test over the override text, plus verify-by-execution with a stub `gh`.
  - Verified by: integration - shell test over the override text, plus execution with a stub `gh`
- [ ] If `gh` is missing or signed out, the report says "CI status could not be read" and names `gh auth login`. An unknown, `cancel`, or pending check never reads as a pass. Verified by: shell test over the override text, plus verify-by-execution with a stub `gh` that fails.
  - Verified by: integration - shell test over the override text, plus execution with a stub `gh` that fails
  - Amended (P1): "could not be read" applies only to a missing `gh`, an auth failure, or invalid JSON. A stub that exits 1 with valid JSON holding a `fail` bucket expects the failed-check result, not "could not be read".

## Dependencies
- 0000031 ADR 003 (CI on `pull_request` only, which rules out reading a `main` run).
- `gh` signed in where GUTD runs.
- req-001 (shares the bucket-to-result mapping, defined in the ship skill).
