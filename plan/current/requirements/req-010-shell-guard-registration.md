---
title: "Requirement: req-010 - shell-guard-registration"
summary: "setup.sh and setup.ps1 register the shell guard for Claude Code exactly once, however often setup runs."
status: "draft"
version: "0.1.0"
---
# Requirement: req-010 - shell-guard-registration

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000032-governance-continuity-and-write-gate-scope
**Source:** US-004
**Priority:** should-have

## User Story

As the human on the loop, I want both setup scripts to register the shell guard for Claude Code exactly once, so that every install runs the guard and a re-run never duplicates it.

## Functional Requirements

### Setup registration (AC-10)

- `install_enforcement_hooks` in `planifest-framework/setup.sh` adds a `PreToolUse` group `{matcher: "Bash", hooks: [{type: "command", command: "node \".claude/hooks/enforcement/shell-write-guard.mjs\""}]}`.
- Before it adds the group, the remove-then-re-add filter drops any `Bash` group whose command contains `shell-write-guard`. Groups that the human on the loop added for `Bash` stay in place.
- `Merge-EnforcementHookSettings` in `planifest-framework/setup.ps1` adds the same `Bash` group with the same filter. It uses the `node $HooksDir/shell-write-guard.mjs` command form that file already uses for `gate-write.mjs`.
- Only the Claude Code install path reaches these two functions, so no other tool gains the hook (ADR-006).
- Both setup scripts already copy every `*.mjs` file in `hooks/enforcement/`. That copies `shell-write-guard.mjs` and `path-rules.mjs` with no change to the copy step.

### Tests

- `planifest-framework/tests/test_setup.sh` and `planifest-framework/tests/test_setup.ps1` assert the registration and the idempotence.

### Verified by

- After `setup.sh claude-code` runs twice, `.claude/settings.json` holds exactly one `PreToolUse` group with matcher `Bash` whose command runs `shell-write-guard.mjs`.
- After `setup.ps1 claude-code` runs twice, the same check holds.
- A `Bash` group the human on the loop added before setup survives both setup runs.
- After `setup.sh claude-code`, `.claude/hooks/enforcement/shell-write-guard.mjs` exists.

## Acceptance Criteria

- [ ] After `setup.sh claude-code` runs twice, `.claude/settings.json` holds exactly one `Bash` PreToolUse group that runs `shell-write-guard.mjs`, and the hook file is installed.
- [ ] After `setup.ps1 claude-code` runs twice, the same single registration holds.
- [ ] A `Bash` group the human on the loop added before setup survives both setup runs.

## Dependencies

- Req-008: the `shell-write-guard.mjs` hook that setup registers.
- ADR-006 records the Claude Code only registration.
- The 0000031 CI jobs run `test_setup.ps1` on Windows and `test_setup.sh` on Linux.
