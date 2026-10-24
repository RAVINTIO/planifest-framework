---
title: "Requirement: req-007 - wired-command-test"
summary: "A test executes the hook command strings that setup.sh writes into settings.json."
status: "draft"
version: "0.1.0"
---
# Requirement: req-007 - wired-command-test

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000037-green-ci-before-ship
**Source:** US-007 (backlog 0000071)
**Priority:** should-have

## User Story

As a framework maintainer, I run a test that executes the hook command string `setup.sh` writes, so that a broken wiring fails the suite.

## Functional Requirements
- FR-007.1: The test runs `setup.sh` for Claude Code into a temporary workspace. It then parses `.claude/settings.json` from that workspace.
- FR-007.2: For each enforcement entry, the test takes the `command` value verbatim. It runs that string through `bash -c` with the workspace as the working directory. It never rebuilds the string.
- FR-007.3: The enforcement entries under test are the `gate-write` entry (matcher `Write`) and the `shell-write-guard` entry (matcher `Bash`). Each gets one violating payload and one clean payload on stdin.
- FR-007.4: The test also runs one `UserPromptSubmit` entry the same way. The `auto-trigger-orchestrator` entry is the target. It receives a prompt payload on stdin.
- FR-007.5: If the settings file has no entry for a named hook, the test fails and names the hook. A missing entry never reads as a skip.
- FR-007.6: The test reads the JSON with `node`, so it needs no `jq`.

## Acceptance Criteria
- [ ] AC-007.1: For the `gate-write` entry, the verbatim `command` exits 2 on a `Write` payload that targets `src/` with no `plan/current/design.md`. It exits 0 on a payload that targets `plan/`. (Verified by: shell suite)
- [ ] AC-007.2: For the `shell-write-guard` entry, the verbatim `command` exits 2 on a `Bash` payload such as `echo x > src/a.js` with no design. It exits 0 on `ls`. (Verified by: shell suite)
- [ ] AC-007.3: For the `auto-trigger-orchestrator` `UserPromptSubmit` entry, the verbatim `command` exits 0 and prints valid JSON. If the test rewrites the entry to a bare `.mjs` path with no `node` prefix, or to a wrong directory, the same run exits non-zero (a negative fixture proves the test detects a broken wiring). (Verified by: shell suite)

## Split step

Split step: keep. All three criteria check one outcome, that the string the installer wrote runs and decides correctly. The two hook kinds share one harness and one story.

## Dependencies
- `planifest-framework/setup.sh` writes the commands (the `gate_cmd`, `shell_guard_cmd`, and `trigger_cmd` variables).
- `planifest-framework/hooks/enforcement/gate-write.mjs`, `shell-write-guard.mjs`, and `auto-trigger-orchestrator.mjs`.
- `planifest-framework/tests/helpers/assert.sh`.
- Suite structure: `planifest-framework/tests/test-0000031-req-004-setup-flags-marker-check.sh` and `test-0000030-req-004-install-clean-up-and-retired-flags.sh` show how suites build a workspace and run `setup.sh`.

## Files P3 changes
- New: `planifest-framework/tests/test-0000037-req-007-wired-command.sh`
- No change to `setup.sh` is expected. If the test finds a real wiring defect, P3 fixes it in `planifest-framework/setup.sh` and records a Deviation.
