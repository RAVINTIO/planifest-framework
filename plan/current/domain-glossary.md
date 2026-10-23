---
title: "Domain Glossary - green CI before ship"
summary: "Definitions of domain terms used within feature 0000037."
status: "draft"
version: "0.1.0"
---
# Domain Glossary - green CI before ship

**Skill:** [spec-agent](../../planifest-framework/skills/planifest-spec-agent/SKILL.md) (updated by any agent that introduces a new domain term)
**Feature:** 0000037-green-ci-before-ship
**Version:** 0.34.0

> Terms come from `design.md`, `feature-brief.md`, and `discovery.md`. Concepts without a clear name are listed after the table.

## Terms

| Term | Definition | Aliases | Used In |
|------|-----------|---------|---------|
| P9 CI check | The check in the ship skill's Step 10. It waits for the PR's checks after `gh pr create` and reports each result before the final report. | P9 check | planifest-framework |
| Last merged PR's checks | The check results of the most recent pull request merged into `main`. The GUTD check reads them through `gh pr list --state merged --base main --limit 1` and `gh pr checks`. | last merged PR checks | planifest-framework |
| GUTD CI check | The step in the GUTD instruction that reads the last merged PR's checks and reports them. | | planifest-framework |
| Pending check | A check that is still running when the P9 wait reaches 20 minutes. P9 reports it as pending, never as a pass. | | planifest-framework |
| Unknown check status | The state of a check whose conclusion is `cancelled` or timed out, or whose status `gh` cannot read. It reads as unknown, never as a pass. | unknown | planifest-framework |
| Red-check handling | The rule that P9 writes the PR number to the build log before it waits. On a failing check, P9 fixes the check on the feature branch and pushes again, up to three attempts. | | planifest-framework |
| Exception-list item | The entry the ship agent raises for the human on the loop when a check stays red after three fix attempts. | | planifest-framework |
| Credential scan | A scan of text for credentials. It runs the P8 credential patterns always, and `gitleaks` when it is installed. | credential patterns | planifest-framework |
| Pre-commit credential scan | The credential scan of staged files that an `autonomous` run performs before each commit and push. | pre-commit scan | planifest-framework |
| Held-back push | A push that the pre-commit credential scan stops after a match. The run stops at the match, and the push waits until the human on the loop clears it. | | planifest-framework |
| PR body scan | The credential scan of the pull request body that runs before `gh pr create`. | | planifest-framework |
| Post-P6 revalidation | The rerun of the P4 checks after the P6 docs edits. It stops a docs change from breaking a green check before ship. | revalidation | planifest-framework |
| Doc-check command | A command that a product declares in `planifest-overrides/`. Post-P6 revalidation runs it when the product declares one. | | planifest-framework |
| Verified by | A field on each acceptance criterion in the requirement template. It names the criterion's test type, and the spec agent sets it at P1. | | planifest-framework |
| Requirement-ID scan | The scan that P3 runs before it closes, so that untested requirements surface before P4. | | planifest-framework |
| Wired command | The hook command string that `setup.sh` writes into a generated `settings.json`. | hook command string | setup-hook-integration |
| Wired-command test | The test that runs the wired command, so a broken wiring fails the suite. | | planifest-framework, setup-hook-integration |
| Re-run-setup migration | A migration that tells the human on the loop to re-run setup, so installed hooks and boot files match the framework version. | | planifest-framework |
| Release diff | The file changes between the prior release and the current one. A re-run-setup migration's file list must match it. | | planifest-framework |
| Migration branch-diff test | The test that compares a re-run-setup migration's file list with the release diff. | | planifest-framework |
| Portability lint | The lint in the suite that flags tool use that behaves differently on GNU and BSD systems, such as `grep -r` without `-H`. | | planifest-framework |
| Working-directory independence | The rule that every suite runs correctly from any working directory. | | planifest-framework |
| Git Bash leg | The CI job that runs the suite on a Windows runner under Git Bash. | Git Bash suite leg | planifest-framework |
| Windows PowerShell 5.1 leg | The CI job that runs `setup.ps1` under Windows PowerShell 5.1. | PowerShell 5.1 leg | setup-hook-integration |
| Live PowerShell test | A test in `test_setup.ps1` that runs the stale clean-up and a retired-flag path for real under PowerShell, not through a stub. | | setup-hook-integration |
| Stale clean-up path | The path in `setup.ps1` that cleans up an earlier install. | | setup-hook-integration |
| Retired flag | A setup flag that the framework no longer supports. | | setup-hook-integration |
| `pull_request` trigger | The only event that starts the CI workflow, per 0000031-ADR-003. | | planifest-framework |
| Check log line | The build-log line that each check writes, such as `CI checks (P9): ...`, `Credential scan (P{N}): ...`, or `Revalidation (P6): ...`. | | planifest-framework |
| Run mode `autonomous` | The run mode in which the pre-commit credential scan applies. | `autonomous` | planifest-framework |
| Human on the loop | The person who sets intent at P0, reviews the result after P9, and merges. | | planifest-framework |

## Concepts without a clear name

- **Timed-out check.** The design uses "timed-out" for a check whose job reaches its `timeout-minutes` limit. The design uses "pending" for a check that the P9 wait does not finish within 20 minutes. This glossary keeps the two terms separate.
- **Unreadable status.** The design lists an unreadable status with the `cancelled` conclusion under unknown. No separate term names an unreadable status. This glossary treats it as part of the unknown check status until the human on the loop names it.
