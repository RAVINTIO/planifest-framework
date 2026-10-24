---
title: "ADR 004: PR text is scanned from files and sent from the same files"
summary: "The PR title and body go to files outside the repository. The agent scans them with credential-scan.mjs --file and sends the body with --body-file. PR text cites paths and results only."
status: "accepted"
version: "0.1.0"
---
# ADR-004 - PR text is scanned from files and sent from the same files

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000037-green-ci-before-ship
**Component:** planifest-framework
**Date:** 2026-10-24

## Context

The ship skill builds the PR body with a heredoc passed to `gh pr create --body`. The agent cannot scan that text before it leaves, and the body can change after any check. A pasted log line or error text can carry a credential into a public PR.

R-009 names the risk: the body changes after the scan. The scan must read the exact text that `gh` sends.

## Decision

Step 10 of the ship skill writes the PR title and body to files outside the repository with the Write tool. It then runs `node planifest-framework/scripts/credential-scan.mjs --file {path}` on each file. `--file` mode applies the same rules as ADR-003 and prints a line number only.

- `gh pr create` and `gh pr edit` send the body with `--body-file`. The heredoc `--body` form is removed.
- The same rule covers the P3 draft PR, the P9 `gh pr edit` update, and the Option [2] description.
- On a match, the agent regenerates the body once and scans again. A second match, or exit `2`, means no `gh pr create`. The agent writes `Exception waiting (P9, 7)` and names the line, never the text.
- PR text cites file paths, requirement IDs, ADR IDs, check names, counts, and result words. It never holds pasted command output, log lines, file contents, diff hunks, or error text.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Scan a heredoc string passed on the command line | No temp file | The scanned text and the sent text can differ, and the shell may expand it | The scan must read the sent text |
| Write the body file inside the repository | Easy to find | The file could be staged and committed | A file outside the repository cannot reach a commit |
| Scan after `gh pr create` and edit on a match | Fewer steps | The secret is public before the scan | Too late |
| Rely on the writing rule alone | No script change | An agent can still paste output by mistake | The scan is the control, the rule lowers the match rate |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | Ship skill Step 10 and the description template change. `credential-scan.mjs` gains `--file`. The orchestrator draft PR step follows the same rule. |

## Consequences

**Positive:**
- The scanned text is the sent text.
- A leak through PR text stops before it is public.

**Negative:**
- The agent writes and scans two extra files per PR.
- A match can hold the PR back, which leaves the human on the loop to paste a description.

**Risks:**
- The body is edited after the scan. The skill text forbids any edit between the scan and the send (R-009).
- A temp file outside the repository holds PR text. It carries paths and results only, so the exposure is small.

## Related ADRs

- ADR-002 - related-to (the P9 edit uses the same rule)
- ADR-003 - depends-on (the script and its rules)
- 0000033 D-003 - related-to (Option [2] and waiting exceptions)

## Governs

req-004, req-001

## Supersedes

- None

## Superseded By

- None
