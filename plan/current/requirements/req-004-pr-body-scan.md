---
title: "Requirement: req-004 - pr-body-scan"
summary: "The ship agent scans the PR title and body for credentials before gh pr create, and PR text cites paths and results only."
status: "active"
version: "0.1.0"
---
# Requirement: req-004 - pr-body-scan

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000037-green-ci-before-ship
**Source:** US-004
**Priority:** must-have

## User Story

As the human on the loop, I know that the PR body cites paths and never raw output, so that the PR text leaks nothing.

## Functional Requirements

- Step 10 of the ship skill writes the PR title and body to files outside the repository with the Write tool. It runs `node planifest-framework/scripts/credential-scan.mjs --file {path}` over each file before `gh pr create`.
- `credential-scan.mjs` (req-003) gains a `--file {path}` mode. It scans that file's content with the same rules and prints a line number only.
- Step 10 raises the PR with `--title "{title}"`, using the scanned title, and `--body-file {body-path}`. The heredoc `--body` form is removed, so the scanned text is the text sent.
- On a match, the agent regenerates the body once, citing paths and results only, and scans again. If the second scan matches or exits `2`, the agent does not run `gh pr create`.
- When the PR is held back, the agent takes Option [2] without the description. It writes `Exception waiting (P9, 7): credential sighting in PR text at line {n}`. The final report names the line, never the text.
- A scan writes `Credential scan (P9): PR text clean ({scan mode})` or `Credential scan (P9): PR text held back`. A regex-only scan says so.
- The PR-text rule goes into the ship skill beside the description template. The PR title and body cite file paths, requirement IDs, ADR IDs, check names, counts, and result words. They never include pasted command output, log lines, file contents, diff hunks, or error text.
- The draft-PR exception list in the body names each exception by item number and path only.
- Option [2] output (the PR description for the human to paste) passes the same scan and follows the same rule.
- The check lists in the body come from req-001 fields (name, bucket, link) and carry no raw output.

Split step: not triggered. The requirement holds three criteria, and no fourth is added.

## Acceptance Criteria
- [ ] Step 10 scans the PR title and body files with `credential-scan.mjs --file` before `gh pr create`, and passes the scanned body with `--body-file`. Verified by: shell test over the ship skill text, plus a script test of `--file` mode.
- [ ] A body that matches is regenerated once. A second match, or exit `2`, means no `gh pr create` call, an `Exception waiting (P9, 7)` line, and a final report entry that names the line and not the text. Verified by: shell test over the ship skill text, plus verify-by-execution with a fixture body.
- [ ] The ship skill states that PR text cites paths and results only, never raw output, and Option [2] output follows the same scan. Verified by: shell test over the ship skill text.

## Dependencies
- req-003 (provides `credential-scan.mjs`, extended here with `--file`).
- req-001 (the check list in the body uses its fields).
- Orchestrator Hard Limit 6 (credentials rule) and exception item 7.
