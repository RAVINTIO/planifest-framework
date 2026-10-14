---
title: "Risk Register - Context Mode and Telemetry MCP removal"
summary: "Technical, operational, and security risks with their mitigations."
status: "active"
version: "0.1.0"
---
# Risk Register - Context Mode and Telemetry MCP removal

**Skill:** [spec-agent](../skills/spec-agent-SKILL.md) (updated by any agent that identifies a new risk)
**Feature:** 0000030-context-mode-and-telemetry-mcp-removal
**Version:** 0.29.0
**Overall Risk Level:** medium

> Every entry must be specific to this feature. Do not produce generic risks.

## Risks

| ID | Category | Description | Likelihood | Impact | Mitigation | Status |
|----|----------|------------|------------|--------|-----------|--------|
| R-001 | operational | Self-hosting break. Deleting hook files before this repo's own `.claude/settings.json` entries leaves every prompt calling a missing file. | medium | high | Remove settings entries first, then files, in one final step (req-005). | open |
| R-002 | technical | Residual references. About 200 files are involved, so a mention of context mode or telemetry is missed. | high | low | Run an allowlist-checked `git grep` at P4 against the NFR allowlist. | open |
| R-003 | security | Clean-up over-reach. Path matching removes a hook a person wrote. | low | medium | Match only exact removed Planifest paths, list every removal, and test with a hand-added hook fixture (req-004). | open |
| R-004 | technical | PowerShell drift. `setup.ps1` diverges from `setup.sh` with no live run here. | medium | medium | Add parity tests that compare both scripts' source, and rely on CI. | open |
| R-005 | operational | Migration runs mid-run in this repo. Resume detection runs pending migrations first. | low | medium | Commit the migration file last and target it at downstream installs only (req-005). | open |
| R-006 | technical | Deleting `phase-enum.mjs` breaks a non-telemetry importer. | low | high | Grep every importer before deletion. Current importers are telemetry modules and tests only. Re-run the check at P4 and run the enforcement hook tests. | open |
| R-007 | operational | Removing the `validate-telemetry-schema` CI job leaves a required status check or branch rule that waits for a job that no longer exists. | medium | medium | Check the repo's branch protection settings and the workflow `needs:` references before removal (req-002). | open |
| R-008 | technical | `pwsh` is unavailable on this machine, so PowerShell changes get only a static check. A PowerShell-only bug ships. | medium | medium | Use static parity tests and confirm at P4 whether CI runs `pwsh`. | open |
| R-009 | technical | Regression-manifest entries point at deleted tests, so the runner fails or silently skips them. | high | medium | Update `tests/regression/regression-manifest.json` in the same commit as each test deletion (req-001, req-002). | open |
| R-010 | operational | The 27 open backlog entries reference removed code, so a later pickup acts on a stale description. | medium | low | Backlog pickup checks each entry against the tree. Do not edit the entries in this run. | accepted |
| R-011 | operational | A downstream project such as `ovelunor` relies on telemetry events and loses data with no replacement. | low | medium | The migration file names the removal so the owner can decide before refreshing (req-005). | open |
| R-012 | technical | A refresh rebuilt from an older install marker replays a retired flag and setup fails. | medium | high | Accept the three retired flags as no-ops, exit 0, and never write them to the marker (req-004). | open |
| R-013 | technical | A crash during the `settings.json` write corrupts the file. | low | high | Write to a temporary file, then rename. Remove entries before folders so a re-run recovers (req-004). | open |
| R-014 | technical | Node is missing on the downstream machine, so the clean-up cannot run and stale entries stay. | low | medium | Skip with a warning and exit 0. The warning tells the person to re-run setup with Node installed (req-004). | open |
| R-015 | compliance | Tests that assert clean-up behaviour need the removed names, which conflicts with the zero-residual NFR. | medium | low | Name the clean-up blocks, their tests, the migration file, and the refresh-setup note in the NFR allowlist. | open |
| R-016 | technical | Removing the Telemetry field from `build-log.template.md` breaks a skill or test that still expects the field. | medium | medium | Remove the field and every skill check in req-003, then run the full suite. | open |
| R-017 | operational | Splitting the work across parallel agents leaves a requirement half applied when one agent stops. | low | medium | Commit granularly after each requirement and keep each removal step its own commit. | open |

## Assumptions Logged as Risks

Documented assumptions from the specification are logged here with likelihood: medium.

| ID | Assumption | Impact if Wrong | Status |
|----|-----------|----------------|--------|
| A-001 | No downstream project depends on telemetry events beyond what the framework itself consumed. | That project loses data with no replacement. The migration file names the removal. | open |
| A-002 | `pwsh` is not installed on this machine, so PowerShell changes get a static check plus CI. | A PowerShell-only bug ships. | open |
| A-003 | The 27 remaining backlog entries are unaffected apart from passing mentions. | An entry describes code that no longer exists. Backlog pickup catches it. | open |
