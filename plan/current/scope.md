---
title: "Scope - green CI before ship"
summary: "Defines what 0000037 delivers, what it leaves out, and what it defers."
status: "draft"
version: "0.1.0"
---
# Scope - green CI before ship

**Skill:** [spec-agent](../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000037-green-ci-before-ship
**Version:** 0.35.0

> Release size exceeds the three-story rule, with no `release-budget.yml`. The human on the loop confirmed eleven stories from ten backlog entries as one run.

## In Scope

- P9 CI check after `gh pr create`, with a fix-and-push loop on the feature branch (req-001).
- GUTD CI check of the last merged PR's checks (req-002).
- Pre-commit credential scan in `autonomous`, which holds back the push on a match (req-003).
- PR body scan before `gh pr create`, and a rule that PR text cites paths only (req-004).
- Post-P6 revalidation of the P4 checks, with an optional product-declared doc-check command in `planifest-overrides/` (req-005).
- "Verified by" field in the requirement template, and a P3 requirement-ID scan (req-006).
- Wired-command test, which runs the hook command string that `setup.sh` writes (req-007).
- Migration branch-diff test, which compares a re-run-setup migration's file list with the release diff (req-008).
- Working-directory independence for every suite, and a portability lint that runs in the suite (req-009).
- Windows Git Bash suite leg in `.github/workflows/planifest.yml` (req-010).
- Windows PowerShell 5.1 setup leg, and the live stale clean-up and retired-flag tests under PowerShell. A new ADR amends 0000031 ADR 001 (req-011).

## Out of Scope

- A `push` trigger on `main`. 0000031 ADR 003 keeps CI on the `pull_request` trigger only.
- Any merge by the agent, including auto-merge.
- Changes to the consumer workflow at `planifest-framework/hooks/planifest.yml`.

## Deferred

Nothing deferred.

Amended (P1): two items are deferred.

- Backlog 0000193 tracks a gap in P9. The Step 11 push of `final-report.md` starts a CI run on a head that P9 never reads. Until 0000193 lands, the check covers only the head that P9 reads.
- Backlog 0000199 tracks a gap in CI. CI fetches no tags, so the tag check in req-008 skips until 0000199 lands.
