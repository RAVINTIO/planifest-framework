---
title: "Requirement: req-007 - partial reads of large files"
summary: "The boot template tells agents to search or read a section of any file over about 20 KB."
status: "active"
version: "0.1.0"
---
# Requirement: req-007 - partial reads of large files

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000038-token-efficiency-windows-shard
**Source:** US-007
**Priority:** should-have

## User Story

As an agent, I search or read a section of a file over about 20 KB, so that one read doesn't add 75 KB.

## Functional Requirements
- `planifest-framework/templates/standard-boot.md` (6,112 bytes, the source of `CLAUDE.md`) gains one directive. For a file over about 20 KB, search it or read the section you need with an offset and a limit.
- The directive removes or softens no existing rule in the template.
- `setup.sh` and `setup.ps1` carry the directive into the generated boot file for each tool.

## Acceptance Criteria
- [ ] `standard-boot.md` holds one directive for files over about 20 KB that names searching or an offset and limit read. Verified by: unit
- [ ] A setup run on a fixture project writes the directive into the generated boot file. Verified by: integration
- [ ] Every other line of `standard-boot.md` is unchanged, and the full suite passes. Verified by: integration

## Dependencies
- The re-run-setup migration in the execution plan carries this change to existing installs.

Split step: keep. One template directive gives one outcome.
