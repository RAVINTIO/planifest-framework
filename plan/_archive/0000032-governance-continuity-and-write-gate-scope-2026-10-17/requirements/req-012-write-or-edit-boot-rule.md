---
title: "Requirement: req-012 - write-or-edit-boot-rule"
summary: "The boot templates gain a Hard Limit that code changes go through Write or Edit, covering the gaps the shell guard can't see."
status: "draft"
version: "0.1.0"
---
# Requirement: req-012 - write-or-edit-boot-rule

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000032-governance-continuity-and-write-gate-scope
**Source:** US-004
**Priority:** should-have

## User Story

As the human on the loop, I want every boot file to require code changes through **Write** or **Edit**, so that the agent doesn't rely on the shell guard's heuristic.

## Functional Requirements

### Boot-file rule

- `planifest-framework/templates/standard-boot.md` and `planifest-framework/templates/cursor-boot.md` each gain a Hard Limit: code changes go through **Write** or **Edit**, never through Bash. The rule says the shell guard is a heuristic and can't see writes made inside scripts (ADR-006).
- The "Hook Enforcement" section of the same template gains a `shell-write-guard` bullet (PreToolUse: Bash, Claude Code only).
- In that section, the `gate-write` bullet states that paths outside the repository are never gated. The closing paragraph states that block reasons go to stderr.
- Setup regenerates every boot file from the template (0000029-ADR-001), so this repository's `CLAUDE.md` gains the rule when setup runs.

### Tests

- A new Bash suite, `planifest-framework/tests/test-0000032-req-012-write-or-edit-boot-rule.sh`, checks both templates and the `CLAUDE.md` that setup generates.

### Verified by

- `templates/standard-boot.md` holds the Hard Limit that code changes go through **Write** or **Edit**, and a `shell-write-guard` bullet.
- `templates/cursor-boot.md` holds the same Hard Limit.
- After `setup.sh claude-code`, the generated `CLAUDE.md` holds the same Hard Limit.

## Acceptance Criteria

- [ ] `templates/standard-boot.md` holds the Hard Limit that code changes go through **Write** or **Edit**, and a `shell-write-guard` bullet.
- [ ] `templates/cursor-boot.md` holds the same Hard Limit.
- [ ] After `setup.sh claude-code`, the generated `CLAUDE.md` holds the same Hard Limit.

## Dependencies

- Req-008: the shell guard and the limits that the Hard Limit covers.
- Req-006: the outside-repository rule that the `gate-write` bullet states.
- Req-007: the stderr rule that the closing paragraph states.
- ADR-006 records the boot-file Hard Limit as the cover for the guard's gaps.
