---
title: "ADR 002: P9 polls PR checks and fixes red checks in autonomous"
summary: "A new ship Step 10c polls gh pr checks as JSON every 30 seconds for up to 20 minutes. It maps buckets to results, fixes red checks in autonomous with 3 attempts, reuses an open draft PR, and pushes the tag after the check."
status: "accepted"
version: "0.1.0"
---
# ADR-002 - P9 polls PR checks and fixes red checks in autonomous

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000037-green-ci-before-ship
**Component:** planifest-framework
**Date:** 2026-10-24

## Context

PR #62 merged with a failing CI check that no agent reported. P9 raises the PR and then writes its final report without reading CI.

Four constraints shape the fix:

- macOS has no `timeout` command, and one Bash call caps at 10 minutes.
- `gh pr checks` exits 1 for a failed check and 8 for a pending one. It still prints the data.
- CI runs on `pull_request` only (0000031 ADR 003). The orchestrator raises a draft PR at P3, so a PR may exist when P9 starts.
- The ship skill keeps a PR draft while an exception waits (0000033 D-003).

## Decision

P9 gains Step 10c, after Step 10b and before Step 11.

- **Polling.** Step 10c runs `gh pr checks {n} --json name,bucket,link` every 30 seconds for at most 20 minutes, or 30 minutes when ADR-014's 20-minute branch applies. It ends when the list is non-empty and nothing is pending. It rereads once after 30 seconds to catch a late job.
- **Judging.** The agent judges from the JSON and never from the exit status. A non-zero exit with valid JSON is data.
- **Buckets.** `pass` is a pass. `fail` is red. `pending` is pending. `skipping` is skipped. `cancel`, a timed-out check, an empty list, and any other value read as unknown. Unknown never counts as a pass.
- **Fix loop.** In `autonomous` only, a red check starts up to 3 fix attempts on the feature branch. Each attempt commits under the credential scan (ADR-003) and pushes without force. After the third failure, the agent writes `Exception waiting (P9, 6)` and runs `gh pr ready --undo {n}`. In `interactive` and `continuous`, a red check goes to the human on the loop in the Step 11 message.
- **Existing PR.** Step 10 checks for an open PR with `gh pr view --json number,url,isDraft`. If one exists, it updates that PR with `gh pr edit --body-file` and never raises a second. It runs `gh pr ready` only when the build log holds no `Exception waiting` line.
- **Tag.** Step 10 pushes the branch only. The agent pushes the `v{version}` tag after Step 10c. If fix commits land, it recreates the local tag at the new head first.
- **Blocked.** Any result other than all passed writes `Progress: P9 blocked`. It never writes `P9 done`.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| `gh pr checks --watch` | One call, no loop | Exit status carries the result, and the call can pass the 10 minute Bash cap | Exit codes mask data, and the cap breaks it |
| Wrap the call in `timeout` | Short to write | macOS lacks `timeout` | Not portable |
| Read the exit status only | Short to write | Exit 8 and exit 1 hide which checks are red | The report must name each check |
| Fix red checks in every run mode | One rule | `interactive` and `continuous` already stop at the P9 gate | The human on the loop is present there |
| Push the tag at Step 9 | Matches the old order | A pushed tag never moves, so fix commits leave it on the wrong head | The tag must name the head CI passed |
| Always raise a new PR | No lookup | Two PRs for one branch, and the draft's CI history is lost | Reuse keeps one PR |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | Ship skill gains Step 10c and the existing-PR path. The autonomous standard gains report part 4 content. The orchestrator Resume Detection gains a P9 rule. |

## Consequences

**Positive:**
- A red or unknown PR never reads as done.
- The poll works on macOS, Linux, and Windows.
- The tag names a head that CI read.

**Negative:**
- P9 can wait 20 minutes on a slow runner.
- The Step 11 push of `final-report.md` starts a CI run that nobody reads. Backlog 0000193 covers it.
- A fix attempt adds commits after the archive step.

**Risks:**
- A queued runner reads as pending after 20 minutes. The run blocks, which is the safe result.
- If the Git Bash leg passes 10 minutes, the 20 minute window needs review. R-023 tracks this.

## Related ADRs

- ADR-003 - depends-on (fix commits run the credential scan)
- ADR-004 - depends-on (PR text scanned before create and edit)
- ADR-005 - related-to (shares the bucket mapping)
- 0000031 ADR 003 - depends-on (`pull_request` only)
- 0000033 D-003 - depends-on (draft while an exception waits)

## Governs

req-001

## Supersedes

- None

## Superseded By

- None
