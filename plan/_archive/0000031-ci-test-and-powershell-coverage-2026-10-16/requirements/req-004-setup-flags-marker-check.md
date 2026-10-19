---
title: "Requirement: req-004 - setup-flags-marker-check"
summary: "test_setup.ps1 parses the setup-flags marker and checks its fields."
status: "active"
version: "0.1.0"
---
# Requirement: req-004 - setup-flags-marker-check

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000031-ci-test-and-powershell-coverage
**Source:** US-003
**Priority:** must-have

## User Story

As the human on the loop, I see CI fail when `Write-SetupFlagsMarker` writes a `.planifest-setup-flags` file that isn't valid JSON or lacks its fields, so that a `ConvertTo-Json` bug can't ship (backlog 0000050).

## Functional Requirements
- After a plain `setup.ps1 claude-code` run, `test_setup.ps1` reads `.claude\.planifest-setup-flags` and parses it with `ConvertFrom-Json`.
- It fails unless all of these hold:
  - `tool` equals `claude-code`.
  - `flags` is present and is an empty array.
  - `writtenAt` matches `yyyy-MM-ddTHH:mm:ssZ`.
  - `attemptStatus` equals `completed`.
- After the `--include-full-skill-library` run, it fails unless `flags` is an array holding exactly `--include-full-skill-library`.
- Each failure throws a `FAIL:` message that names the field and the value it found.
- The raw marker text counts as an array only if it holds a JSON array literal for `flags`. That catches the case where `ConvertTo-Json` collapses a one-item array to a string.

## Acceptance Criteria
- [ ] A marker with valid fields passes, for both the plain run and the flagged run.
- [ ] A marker that isn't valid JSON, lacks a field, or holds `flags` as a string makes the script throw a `FAIL:` message naming the field.
- [ ] The Windows CI job from REQ-003 runs these checks and passes.

## Dependencies
- REQ-003 runs these assertions live. They run locally only on a Mac with `pwsh` installed.
