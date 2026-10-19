---
title: "Requirement: req-005 - ship-without-asking-and-final-report"
summary: "In autonomous mode P7 to P9 ask nothing. The ship agent pushes and raises the PR, and the run ends with one final report. Merging stays human-only."
status: "draft"
version: "0.1.0"
---
# Requirement: req-005 - ship-without-asking-and-final-report

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Source:** US-001, US-002
**Priority:** must-have

## User Story

As the human on the loop, I choose `autonomous` at P0, so that the run goes from confirmed design to a raised PR with no gate waiting for me.

## Functional Requirements

### Standards file (`planifest-framework/standards/autonomous-run-standards.md`)

- **`## Final report`:** The section gives the report's format. The report has these parts, in order:
  1. What shipped.
  2. Every decision and deviation, from the build log's `Decision` and `Deviation` lines.
  3. The version, from the Step 9 tag.
  4. The PR URL and its CI result, from `gh pr checks`. If CI hasn't finished, the result reads `pending`.
  5. The clean-tree result, from the scoped `git status --porcelain` check at the end of P9 (req-013). It names any file left over, or reads `clean`.
  6. Every exception waiting, from the build log's `Exception waiting` lines. If there are none, the part reads `none`.
- The report ends by saying that the human on the loop reviews and merges the PR.
- The report is the only output of P7 to P9 in `autonomous` that addresses the human on the loop.

### Ship skill (`planifest-framework/skills/planifest-ship-agent/SKILL.md`)

- **Reading the run mode:** The ship agent reads the run mode from the build-log Header table's `Run mode` row (req-006), in `plan/current/build-log.md` before Step 6 and in the archived build log after it. It never reads `plan/.run-mode` after the P9 marker step deletes it. A resume after the marker step reads the same row.
- **Hard Limit 4:** The rule stays for `interactive` and `continuous`. In `autonomous`, the human on the loop's P0 choice gives that awareness, and the final report confirms the tag and the PR.
- **P7 Step 4 (Regression confirmation):** In `autonomous`, the agent decides each candidate as a recorded decision. It passes `agent` as the promoted-by argument to `promote-to-regression.sh`. The final report lists each candidate and its decision.
- **Step 10 (Push/PR decision):** The `local-git-only` check runs first, as now, and an override still wins. In `autonomous` with no such override, skip the prompt and take Option [1]. With the override, take Option [2] and put its PR title and description in the final report.
- **After the PR:** In `autonomous`, any commit the run makes after the PR is raised is pushed straight away, unless the `local-git-only` override applies.
- **Step 11 (Confirm to human):** In `autonomous`, the agent writes the final report in place of the Step 11 message. Step 12 still runs after the report.
- **Merging:** No step, in any mode, runs `gh pr merge` or merges the PR in another way.

### Orchestrator skill (`planifest-framework/skills/planifest-orchestrator/SKILL.md`)

- **`## Phase 7 - Archive`, Gate line:** The text "always a confirmation stop" stays for `interactive` and `continuous`. In `autonomous`, P7 doesn't stop, and the final report replaces the confirmation.
- **`## Phase 9 - Ship`, "What P9 produces" and Gate:** In `autonomous`, the ship agent raises the PR without asking and ends with the final report.

### Pipeline reference (`planifest-framework/pipeline-reference.md`)

- The "P9 always stops" line applies to `interactive` and `continuous`. One sentence adds that `autonomous` raises the PR and ends with the final report, and that the human on the loop still merges.

### Tests

- Add `planifest-framework/tests/test-0000033-req-005-ship-without-asking-and-final-report.sh`. `run-tests.sh` picks it up.
- `planifest-framework/tests/test-0000025-req-001-ship-agent-pr-footer.sh` asserts Step 10 text. It must pass unchanged.
- `planifest-framework/tests/test-0000032-req-001-marker-clear-before-tag.sh` also asserts Step 10 text. req-007 edits one of its assertions as a listed exception. This requirement edits none of its assertions, and it must pass after the req-007 edit.

### Verified by

- The standards file has a `## Final report` heading, and the section names the six parts, including the clean-tree result.
- The section names `gh pr checks` and says the human on the loop merges.
- The ship skill reads the run mode from the build-log `Run mode` row. No line after the P9 marker step reads `plan/.run-mode` for the mode.
- Step 10 checks `local-git-only` before the `autonomous` rule, by line number.
- Step 10 still holds both `Option [1] (Agent pushes)` and `Option [2] (Human pushes)` headings.
- The after-PR push rule names the `local-git-only` exception.
- The ship skill's Step 11 names the final report for `autonomous`, and Step 12 still follows it.
- The ship skill doesn't contain `gh pr merge`.
- The orchestrator's Phase 7 gate line still contains "always a confirmation stop" and also names `autonomous`.
- `pipeline-reference.md` names `autonomous` next to the P9 stop rule.

## Acceptance Criteria

- [ ] (AC-1) In `autonomous`, P7 to P9 ask nothing. The ship agent raises the PR unless a `local-git-only` override applies, and no mode merges the PR.
- [ ] (AC-2) An `autonomous` run ends with one final report that holds the six parts, including the clean-tree result and every exception waiting.
- [ ] (AC-7) P7 to P9 stay as they are in `interactive` and `continuous`, and the new suite and the 0000025 req-001 and 0000032 req-001 suites pass.

## Dependencies

- req-001 defines `autonomous`. req-002 defines the build-log lines that the report reads.
- req-006 adds the build-log `Run mode` row that the ship agent reads.
- req-007 rewrites the Step 10 prompt wording.
- req-013 adds the scoped `git status --porcelain` check at the end of P8 and P9. Its commit of leftover files runs before the final report.
- req-012 replaces the P7 archive steps.
