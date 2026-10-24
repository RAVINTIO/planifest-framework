---
title: "Requirement: req-011 - Windows PowerShell coverage"
summary: "Run test_setup.ps1 under Windows PowerShell 5.1 in CI, and extend it to run the stale clean-up and a retired flag live."
status: "draft"
version: "0.1.0"
---
# Requirement: req-011 - Windows PowerShell coverage

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000037-green-ci-before-ship
**Source:** US-011 (backlog 0000092 and 0000094)
**Priority:** should-have

## User Story

As a framework maintainer, I see `setup.ps1` run under Windows PowerShell 5.1, and the stale clean-up and retired-flag paths run live under PowerShell, so that Windows defects fail in CI.

## Functional Requirements

- Windows PowerShell 5.1 becomes a supported runtime for `setup.ps1`. An ADR written at P2 amends 0000031 ADR 001, which said 5.1 is not tested. `docs/architecture-overview.md` lists "PowerShell 7+ or Windows PowerShell 5.1" in its runtime table and CI table, and drops the "no CI coverage" sentence.
- A new job `setup-powershell-51` in `.github/workflows/planifest.yml` runs on `windows-latest` with `shell: powershell` and runs `./planifest-framework/tests/test_setup.ps1`. It first prints `$PSVersionTable.PSVersion` and fails if the major version is not 5. A comment above the job states that it is repository-only.
- The new job sets `permissions: contents: read`, reads no secret, sets `timeout-minutes: 10`, and runs on `pull_request` only (0000031 ADR 002 and ADR 003). The existing `setup-powershell` job and its PowerShell 7 check stay unchanged.
- `planifest-framework/setup.ps1` and `test_setup.ps1` must run under 5.1. P3 fixes any 5.1 difference the leg reveals, such as encoding, JSON depth, or `ConvertFrom-Json` date handling, in the file that holds the difference. Each fix keeps PowerShell 7 behaviour.
- `test_setup.ps1` gains a section that seeds a stale Claude Code state in a fresh workspace. The state holds one stale `settings.json` entry (a `context-mode` Grep hook command), one stale hook folder (`.claude/hooks/telemetry/`), and one hook a person added by hand. The seed copies the fixtures from `test-0000030-req-004-install-clean-up-and-retired-flags.sh`.
- The new section runs `setup.ps1 claude-code --context-mode-mcp`. It asserts four outcomes:
  - The command exits 0.
  - Exactly one output line contains the substring `--context-mode-mcp was removed in 0.29.0 and has no effect`. The real line in `setup.ps1` adds a `  ! ` prefix and a full stop, so the match is on the substring and not the whole line.
  - The stale entry and the stale folder are gone, and the hand-added hook survives.
  - The retired flag does not appear in `.claude\.planifest-setup-flags`.
- The section runs under both PowerShell 7 and Windows PowerShell 5.1, because both jobs run `test_setup.ps1`.
- A new test, `planifest-framework/tests/test-0000037-req-011-windows-powershell-coverage.sh`, checks the workflow text for the new job and checks `test_setup.ps1` text for the seed, the flag run, and the four assertions. `src/setup-hook-integration/docs/quirks.md` Q-013 records that the clean-up now runs live, and Q-006 and Q-008 stay as they are.
- Windows PowerShell 5.1 has no `pwsh`-only syntax in the touched files. The guard that the discovery notes mention near line 709 of `setup.ps1` is a comment about reparse points, so no code guard needs a change.

Split step: keep. Backlog 0000092 and 0000094 share one outcome, that `setup.ps1` runs live under PowerShell on Windows with its clean-up path covered, and 0000094 alone adds no job. The requirement holds three criteria. Neither half ships alone in a useful form, because the clean-up test only proves the 5.1 claim if it runs in the 5.1 leg.

## Acceptance Criteria

- [ ] The workflow holds a `setup-powershell-51` job on `windows-latest` with `shell: powershell`, `permissions: contents: read`, `timeout-minutes: 10`, no secrets, and a version check that fails unless the major version is 5. The `Setup under Windows PowerShell 5.1` check passes on the feature PR. (Verified by: static workflow-text test, then CI run read through `gh pr checks`)
  - Verified by: integration - shell suite over the workflow text, then the CI run read through `gh pr checks`
- [ ] `test_setup.ps1` seeds a stale `settings.json` entry, a stale hook folder, and a hand-added hook, runs `setup.ps1 claude-code --context-mode-mcp`, and asserts the exit code, the single notice, the clean-up, the surviving hook, and the clean marker. Both the PowerShell 7 job and the 5.1 job pass it. (Verified by: live PowerShell run in CI, and a static test of the `test_setup.ps1` text)
  - Amended (P1): the single-notice assertion matches one output line that contains the substring `--context-mode-mcp was removed in 0.29.0 and has no effect`, not an exact line.
  - Verified by: e2e - live `test_setup.ps1` run in the PowerShell 7 and 5.1 CI jobs, plus a shell suite over the `test_setup.ps1` text
- [ ] `docs/architecture-overview.md` names Windows PowerShell 5.1 as a supported runtime and lists the new job. A P2 ADR amends 0000031 ADR 001 and links to it. (Verified by: static doc-text test)
  - Verified by: integration - shell suite over the doc text

## Dependencies

- 0000031 ADR 001 (amended by this requirement), ADR 002, and ADR 003.
- `test-0000030-req-004-install-clean-up-and-retired-flags.sh` supplies the stale fixtures and the notice text.
- Q-006, Q-008, Q-013, and Q-014 in `src/setup-hook-integration/docs/quirks.md`. Q-014 covers the BOM-less `Write-SettingsFile`, which the 5.1 leg exercises.
- The existing `setup-powershell` job and `test-0000031-req-001-003-ci-jobs.sh` stay green.
