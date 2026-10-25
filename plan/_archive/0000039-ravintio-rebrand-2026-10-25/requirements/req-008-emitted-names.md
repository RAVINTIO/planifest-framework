---
title: "Requirement: req-008 - emitted-names"
summary: "Hooks, setup output, and the generated boot file emit RAVINTIO names and paths."
status: "draft"
version: "0.1.0"
---
# Requirement: req-008 - emitted-names

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000039-ravintio-rebrand
**Source:** US-001
**Priority:** must-have

## User Story

As a human on the loop, I see RAVINTIO names in every hook message, log line, and generated boot file, so that the pack matches the RAVINTIO org.

## Functional Requirements
- `hooks/enforcement/path-rules.mjs` uses `ravintio-framework` in `ROOT_MARKERS`, in the enforcement path list, and in the always-permitted list (`.ravintio-session`). It also lists `.opencode/plugins/@ravintio/opencode-hooks/` and `.github/workflows/ravintio.yml` as enforcement paths.
- The gate-write and orchestrator-presence messages name the `ravintio-orchestrator` skill. Hook and setup output uses the `[RAVINTIO]` prefix in place of `[Planifest]`.
- Setup runs `git config core.hooksPath ravintio-framework/hooks`.
- The OpenCode plugin path and registration use the `@ravintio` npm scope in `setup/opencode.sh` and `setup/opencode.ps1`.
- The workflow file `ravintio.yml` names its workflow `RAVINTIO Strict Pipeline`.
- The generated boot file for Claude Code and every other tool names `ravintio-framework/` paths. This includes the sanctioned-scripts list in Hard Limit 8, such as `ravintio-framework/scripts/archive-current.mjs` and `ravintio-framework/setup.sh`.
- The fixture for the second criterion starts from an old 0.36.0 install. Its `core.hooksPath` reads `planifest-framework/hooks`, and its OpenCode plugin sits under `@planifest`. The test runs the migration helper and then setup, and checks both values change.
- Split step: this is the second half of the split from req-002. The old-name reads (the `PLANIFEST_SESSION_ID` fallback) belong to req-003.

## Acceptance Criteria
- [ ] `path-rules.mjs` tests pass with `ravintio-framework` as the root marker, `.ravintio-session` always permitted, and the `@ravintio` and `ravintio.yml` enforcement paths. The gate-write and presence messages name `ravintio-orchestrator` and start with `[RAVINTIO]`. Verified by: unit
- [ ] After `setup.sh claude-code` runs on a fixture, `core.hooksPath` equals `ravintio-framework/hooks` and the OpenCode plugin sits under `@ravintio`. Setup output holds no `[Planifest]` text. Verified by: integration
- [ ] The generated `CLAUDE.md` and the boot files for the other tools hold no `planifest-framework/` path. Each sanctioned script in Hard Limit 8 exists under `ravintio-framework/`, and the workflow name reads `RAVINTIO Strict Pipeline`. Verified by: integration

## Dependencies
- req-001-pack-paths-and-identifiers renames the files and folders that these names point to.
- req-002-runtime-names covers the setup state files and the old-marker replacement.
- req-003-environment-variables owns the `PLANIFEST_SESSION_ID` fallback.
- req-007-brand-guard catches any `planifest` name that these edits miss.
