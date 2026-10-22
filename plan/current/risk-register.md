---
title: "Risk Register - pipeline friction and gate fixes"
summary: "Technical, operational, security, and compliance risks for 0000036 with their mitigations."
status: "active"
version: "0.1.0"
---
# Risk Register - pipeline friction and gate fixes

**Skill:** [spec-agent](../../planifest-framework/skills/planifest-spec-agent/SKILL.md) (updated by any agent that identifies a new risk)
**Feature:** 0000036-pipeline-friction-and-gate-fixes
**Version:** 0.34.0
**Overall Risk Level:** medium

> Every entry is specific to this feature. R-001 to R-004 come from the Risks section of `design.md`. R-005 onward are added by the spec agent.

## Risks

| ID | Category | Description | Likelihood | Impact | Mitigation | Status |
|----|----------|------------|------------|--------|-----------|--------|
| R-001 | operational | `report-only` critic findings slow P1 and P2 outside `autonomous`. | medium | low | The verdict blocks nothing and goes to the build log with no dismissal step. Review the false-positive rate before any move to `on`. | open |
| R-002 | security | Accepting a `- ` anchor widens what `run-mode.mjs` trusts. A forged anchor could restore `autonomous` without the human on the loop. | low | high | Keep the one-commit rule and the design Confirmation check unchanged. Add suite cases that reject an indented line, another prefix, and a line added in a later commit. A forged, uncommitted, or missing anchor reads as `interactive`. | open |
| R-003 | technical | Changing `shown()` truncation shifts the text of existing block messages. | medium | low | Update every suite that matches exact text in the same change. Run the full suite before commit. | open |
| R-004 | operational | Eleven stories in one run exceed the three-story rule. | medium | medium | Split the work into parallel streams by file ownership, with `path-rules.mjs` in one stream. The orchestrator owns every join. | open |
| R-005 | security | Treating a non-regular `design.md` as no design narrows 0000003 ADR 005 (fail open). A wrong narrowing could block a legitimate write or open a gap. | low | high | Read a non-regular file or a throwing `lstat` as no design, as `existsSync` does today. If a regular file can't be read, fail open. Record the narrowing in an ADR and add suite cases for both sides of the line. | open |
| R-006 | security | A hook that opens a FIFO at `design.md` waits for ever and stalls the session. | low | high | Run `lstat` before any read and never open a non-regular file. Add a suite case with a FIFO and a timeout. | open |
| R-007 | security | Skipping the always-permitted shortcut inside enforcement paths blocks a write that used to pass, such as `planifest-framework/hooks/enforcement/CLAUDE.md`, an always-permitted name inside an enforcement folder. | medium | medium | Route these paths through the normal design scope or Fast Path scope verdict. Keep every other path unchanged. Add suite cases with and without `design.md`. | open |
| R-008 | security | A change in `path-rules.mjs` for US-008 and US-009 weakens an existing check. Fast Path could admit an enforcement path (0000033 ADR-009). | low | high | Keep both changes in one stream. Run the 0000035 suites and the Fast Path scope suites unchanged. Add a case that a scope record never admits an enforcement path. | open |
| R-009 | technical | `shown()` cuts an escape sequence in half at its length cap, which leaves a broken sequence in hook output. | medium | medium | Cut at a boundary before the escape sequence. Add suite cases with a control character, U+202E, and an over-long value for both `ratchet-check.mjs` and `em-dash-guard.mjs`. | open |
| R-010 | technical | New hook code spawns a process or imports a non-built-in module, which breaks 0000035 ADR-001 and 0000032 ADR-004. | low | medium | Use Node built-ins only. A suite source check scans the hooks for `child_process` and external imports. | open |
| R-011 | technical | Each hook call, including the extra `lstat` and the `shown()` change, exceeds the 500 ms target. | low | low | Keep `lstat` to one call. Check suite timing on CI. | open |
| R-012 | technical | The drift check reports false drift because setup does not copy `SKILL.md` byte for byte. Setup rewrites four relative paths in each copy, and PowerShell 5 adds a byte order mark. | medium | medium | Reproduce setup's four path rewrites in the check and strip one leading byte order mark from both copies before comparing. Ignore folders that setup adds. Add a suite that asserts the check's rewrite list matches `setup.sh` and `setup.ps1`, and a case that matches on this repo. | open |
| R-013 | technical | The drift check picks the wrong tool folder when the install marker is missing or unreadable. | medium | low | Fall back to every installed tool folder it finds. Add a suite case with no marker. | open |
| R-014 | operational | An agent runs the stale installed skill after the check warns, or re-runs setup without the human on the loop. | medium | medium | The orchestrator loads the source copy and only recommends `planifest-refresh-setup`. It never re-runs setup itself, and it runs the check again after any setup run. | open |
| R-015 | operational | The drift check exceeds 1 s on this repo as the skill count grows. | low | low | Read each file once and compare in memory. Add a suite timing check. | open |
| R-016 | operational | A downstream project skips the 0.34.0 migration and keeps stale hooks or boot files. | medium | high | The migration records as pending in resume detection. The update policy sentence says a setup-delivered change ships a re-run-setup migration. The drift check also warns on stale skills. | open |
| R-017 | operational | The migration describes the 0.33.0 and 0.34.0 setup-delivered changes wrongly or incompletely, so a project misses a change. | medium | medium | Build the change list from the 0.33.0 and 0.34.0 diffs of setup-delivered files. A suite checks the migration against the 0.31.0 sections. | open |
| R-018 | operational | On a fresh 0.34.0 install the migration re-runs setup for no gain. | medium | low | Setup is safe to re-run, and the migrator writes the record only when the run completes. | open |
| R-019 | operational | P3 records the migration as `applied` here before setup actually re-runs, so the record is wrong. | low | medium | Re-run setup in this repo first and write the record only after it completes. | open |
| R-020 | operational | Removing placeholders from commit subjects leaves a skill with a subject over 72 characters or with the ID missing from the body, which blocks P7 or P9. | medium | medium | A suite fails on any placeholder or a subject over 72 characters across all framework skills. Put the feature ID in the commit body. | open |
| R-021 | operational | Citing hard limits by name and source misses a file, so a bare "Hard Limit 8" survives and an agent confuses the build-log rule with the Write-or-Edit rule. | medium | medium | A suite fails on any bare citation across skills, standards, and templates. Add the Write-or-Edit rule to the dispatch template in `agent-dispatch-standards.md`. | open |
| R-022 | technical | The suite for bare citations flags legitimate text, such as a quoted old citation in an archive or migration. | medium | low | Scope the suite to live framework files and exclude `plan/_archive/`. | open |
| R-023 | operational | The split step prompts too often, or an agent splits a requirement into pieces that hide a shared concern. | medium | low | Fire only when a requirement would reach a fourth criterion. The step asks a question and the agent decides. The design critic rubric checks the result. | open |
| R-024 | technical | Clearing `CLAUDE_PROJECT_DIR` in `run-tests.sh` hides a suite that needs it, or a standalone gate suite still tests the real repo. | medium | medium | Add a suite check that `run-tests.sh` clears the variable. Req-010 also covers every suite that names an enforcement hook, seven today, not the four the brief names. Set it explicitly where a suite needs a value. | open |
| R-025 | compliance | `product.yml` and `component.yml` versions drift from the `0.34.0` tag. | low | medium | The ship agent sets `product.yml` at P7 and the close-out suite checks it against the tag and feature. | open |
| R-026 | operational | A new default of `report-only` adds one critic subagent at each of the P1 and P2 gates, which raises cost outside `autonomous`. | medium | low | The cost is bounded at two subagents per run. The human on the loop can set `design_critic` to `off` in `loop-toggles.yml`. | open |

## Assumptions Logged as Risks

Documented assumptions from the specification are logged here with likelihood: medium.

| ID | Assumption | Impact if Wrong | Status |
|----|-----------|----------------|--------|
| A-001 | Setup copies each `SKILL.md` with exactly four relative-path rewrites, plus an optional leading byte order mark from PowerShell 5. | The drift check reports false drift for every skill (see R-012). | open |
| A-002 | The drift check can tell the active tool from its install marker, `.claude/.planifest-setup-flags` or the tool's equivalent. | The check falls back to every installed tool folder it finds (see R-013). | open |
| A-003 | No existing records need reading. `discovery.md` Record Samples reads None. | A hidden record format would conflict with the new migration record. | open |
| A-004 | `autonomous` keeps `design_critic` at `on`. Only the default outside `autonomous` changes. | The cost boundary and the critic default in US-006 would differ from the design (see R-026). | open |
