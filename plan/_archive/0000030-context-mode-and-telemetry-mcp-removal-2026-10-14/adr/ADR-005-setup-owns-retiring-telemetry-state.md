---
title: "ADR 005: Setup takes ownership of retiring telemetry state"
summary: "setup-hook-integration owns removal of every stale Context Mode and Telemetry artifact, including plan/.telemetry-* folders the telemetry hooks used to write."
status: "accepted"
version: "0.1.0"
---
# ADR-005 - Setup takes ownership of retiring telemetry state

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000030-context-mode-and-telemetry-mcp-removal
**Component:** setup-hook-integration, planifest-framework
**Date:** 2026-10-14

## Context

Hard limit: one component owns each dataset, and no other component writes to it. The telemetry hooks in `planifest-framework` wrote `plan/.telemetry-failures/` and `plan/.telemetry-receipts/`. Setup wrote `.claude/telemetry-enabled`, the hook folders, and the settings entries. ADR-004 has setup delete all of them, so ownership of the `plan/.telemetry-*` folders must move before setup touches them.

## Decision

`setup-hook-integration` owns the removal of every artifact in ADR-004's clean-up list, including `plan/.telemetry-failures/` and `plan/.telemetry-receipts/`. The writer of those folders is deleted by ADR-002, so they have no other owner. `planifest-framework` keeps ownership of `build-log.md` and the build-log template. `setup-hook-integration` keeps ownership of each tool's settings file and the install marker.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Leave the `plan/.telemetry-*` folders in place | No ownership question | Dead folders stay in every downstream repo | The human on the loop accepted removing them (Scope Lock clarification C) |
| Have the orchestrator delete them at P0 | The old owner's component cleans its own data | Only runs when a pipeline starts, and needs new orchestrator text about telemetry | Puts telemetry text back into the skill ADR-002 cleans |

## Affected Components

| Component | Impact |
|-----------|--------|
| `setup-hook-integration` | Gains ownership of retiring the `plan/.telemetry-*` folders |
| `planifest-framework` | Gives up ownership of data its deleted hooks wrote |

## Consequences

**Positive:**
- Every stale artifact has exactly one owner that removes it.

**Negative:**
- Setup now writes under `plan/`, which it didn't before. The writes are limited to deleting these two folders.

**Risks:**
- A future feature adds a `plan/.telemetry-*` folder for another reason, and setup deletes it. The exact folder names keep that unlikely.

## Related ADRs

- ADR-004 - related-to
- 0000018-ADR-002 - superseded by ADR-002 (it created the failure markers)

## Supersedes

- None

## Superseded By

- None
