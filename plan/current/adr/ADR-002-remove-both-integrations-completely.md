---
title: "ADR 002: Remove the Context Mode and Telemetry MCP integrations completely"
summary: "Both optional MCP integrations leave the framework entirely, including pipeline text, and their earlier ADRs become superseded."
status: "accepted"
version: "0.1.0"
---
# ADR-002 - Remove the Context Mode and Telemetry MCP integrations completely

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000030-context-mode-and-telemetry-mcp-removal
**Component:** planifest-framework, setup-hook-integration, context-mode-hooks
**Date:** 2026-10-14

## Context

Planifest supports two optional MCP integrations. Context Mode (features 0000001, 0000008, and 0000017) blocks `Grep`, `Bash`, and `WebFetch` calls in favour of a context-mode plugin. Telemetry (features 0000007, 0000018, 0000019, 0000024, 0000027, and 0000028) emits phase and decision events to `structured-telemetry-mcp`. It also checks for failures and receipts, and records a `Telemetry` field in every build-log phase block.

Together they reach about 200 tracked files and have driven several features of fixes. On 2026-10-14 the human on the loop decided to drop both. They chose complete removal over removing only the MCP wiring.

## Decision

Remove both integrations completely:
- hooks, backstops, and helper scripts
- setup install paths, for every tool
- the `context-mode-hooks` component
- the telemetry standard and the two structured-telemetry docs
- every skill instruction, and the build-log `Telemetry` field
- the CI telemetry schema job
- their tests

Keep `build-log.md`, the P8 build assessment, and the `product.yml` `id` field. None of them needs either MCP. ADR-007 covers the `id`.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Remove only the MCP wiring, and keep the pipeline's telemetry text | Smaller change | Every phase would record `confirmed-disabled` forever, and skills would describe events nothing emits | The human on the loop chose complete removal |
| Keep both integrations, and make them easier to switch off | No removal work | The maintenance cost stays, and so does the skill text every agent loads | The human on the loop decided to drop both |

## Affected Components

| Component | Impact |
|-----------|--------|
| `planifest-framework` | Loses `hooks/context-mode/`, `hooks/telemetry/`, two backstops, `phase-enum.mjs`, `telemetry-standards.md`, and telemetry text in 15 skills and 2 templates |
| `setup-hook-integration` | Stops installing either integration |
| `context-mode-hooks` | Deleted, along with its `product.yml` `components[]` item |

## Consequences

**Positive:**
- Agents load less skill text, and no phase spends effort on emission or failure checks.
- Downstream projects no longer run hooks for MCP servers they may not have.

**Negative:**
- Run duration and decision events are no longer emitted anywhere. `build-log.md` is the only run record.
- Downstream projects that used either integration lose it, with no replacement.

**Risks:**
- A downstream project relied on telemetry events (A-001). The migration file in ADR-006 is its notice.

## Related ADRs

- 0000029-ADR-002 - extends (boot templates already stopped naming third-party MCP plugins)
- 0000003-ADR-005 - related-to (exit-zero failure mode, kept)
- ADR-003, ADR-004, ADR-006, ADR-007 - depends-on this ADR

## Supersedes

- 0000001-ADR-001, ADR-002, ADR-003, ADR-004 (Context Mode enforcement hooks)
- 0000008-ADR-001, ADR-002 (Context Mode plugin routing rules)
- 0000007-ADR-002 (telemetry guidance centralised)
- 0000018-ADR-001, ADR-002 (telemetry gating, failure detection and recovery)
- 0000019-ADR-002 (`context_pressure` phase mapping)
- 0000027-ADR-001 (telemetry receipt backstop)
- 0000028-ADR-001 (telemetry retry semantics)
- Partly: 0000017-ADR-002 (the Context Mode hooks it covered are gone, and the `.mjs` runtime rule stays for the other hooks)
- Partly: 0000028-ADR-002 (the `hooks/telemetry/` placement is gone, and the `hooks/enforcement/` shared modules stay)
- Partly: 0000024-ADR-001 (see ADR-007)

## Superseded By

- None
