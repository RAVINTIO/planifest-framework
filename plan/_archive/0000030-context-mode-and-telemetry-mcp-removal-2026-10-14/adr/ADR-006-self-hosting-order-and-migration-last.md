---
title: "ADR 006: Self-hosting order and migration last"
summary: "This repo removes its own telemetry wiring in one final step, entries before files, and the downstream migration file is the last P3 commit."
status: "accepted"
version: "0.1.0"
---
# ADR-006 - Self-hosting order and migration last

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000030-context-mode-and-telemetry-mcp-removal
**Component:** planifest-framework, setup-hook-integration
**Date:** 2026-10-14

## Context

This repository runs Planifest on itself. Its `.claude/settings.json` wires five telemetry hook groups to files under `.claude/hooks/`. If those files go before their entries, every prompt, tool call, and Stop event calls a missing file for the rest of the run. Resume detection also runs any pending file in `planifest-framework/migrations/` before phase work. A migration committed early could run against a half-finished removal in this repo.

## Decision

Split the work in two:
- The framework source changes (REQ-001 to REQ-004) never touch this repo's installed copies under `.claude/`.
- One final P3 step (REQ-005) removes this repo's own telemetry entries from `.claude/settings.json` first, then deletes the installed files. In the same commit it also removes `.claude/telemetry-enabled`, `plan/.telemetry-failures/`, the flag in `planifest-overrides/setup-config/claude-code.md`, and the `CLAUDE.md` emit-phase line.

The migration file is committed after that step, as the last P3 commit. It targets downstream installs only. It tells them to refresh `planifest-framework/` and re-run setup.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Re-run the new `setup.sh` on this repo as the final step | Exercises the real clean-up end to end | Also rewrites this repo's other hooks, skills, and boot files mid-run, mixing unrelated churn into the feature | Too broad for a self-hosting step. P4 exercises setup against fixtures instead |
| Remove this repo's wiring first | Stops telemetry hooks during the run | The run then works without the backstops it was started with, and a mistake breaks every later prompt | Larger window for the R-001 failure |

## Affected Components

| Component | Impact |
|-----------|--------|
| `planifest-framework` | This repo's own install, `CLAUDE.md`, and the migration file |
| `setup-hook-integration` | The install marker under `planifest-overrides/setup-config/` |

## Consequences

**Positive:**
- The window where this repo's hooks point at missing files is one commit wide.
- Resume detection in this repo never sees the new migration mid-run.

**Negative:**
- This repo's telemetry hooks keep running against an MCP server until the final step. They fail open, so nothing blocks.

**Risks:**
- The session runs on, with hooks the harness loaded at start, after their files are deleted. Each such hook then fails open with a missing-module error until the session restarts.

## Related ADRs

- ADR-002 - depends-on
- ADR-004 - related-to (the same entries-before-files order)

## Supersedes

- None

## Superseded By

- None
