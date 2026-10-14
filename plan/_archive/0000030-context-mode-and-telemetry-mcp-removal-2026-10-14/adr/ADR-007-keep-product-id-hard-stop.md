---
title: "ADR 007: Keep the product id hard-stop with a new rationale"
summary: "The P0 hard-stop on product.yml id stays, now justified by versioning and archive attribution rather than telemetry."
status: "accepted"
version: "0.1.0"
---
# ADR-007 - Keep the product id hard-stop with a new rationale

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000030-context-mode-and-telemetry-mcp-removal
**Component:** planifest-framework
**Date:** 2026-10-14

## Context

0000024-ADR-001 made `product.yml` `id` mandatory, and added a P0 hard-stop when it's missing. Its stated reason was that telemetry hooks source `product_id` from that field. ADR-002 removes telemetry. The human on the loop decided to keep the `id` field. Without a new reason, the hard-stop would ask for a value with a false justification.

## Decision

Keep the Phase 0 step 3b hard-stop and the `id` field. Rewrite its rationale and prompt text: the `id` gives the product a stable name for versioning (`product.yml`, `scripts/product-version.mjs`) and for attributing archived runs, wherever the repository is cloned. Mark 0000024-ADR-001 as partly superseded: its decision stands, and its telemetry rationale does not.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Make the `id` optional and drop the hard-stop | One fewer P0 stop | Changes behaviour that 0000024's tests and downstream projects rely on, outside this feature's scope | The human on the loop asked to keep the `id` |
| Keep the hard-stop text unchanged | No edit | The prompt states a reason that is no longer true | Misleads the person answering it |

## Affected Components

| Component | Impact |
|-----------|--------|
| `planifest-framework` | Orchestrator Phase 0 step 3b text, and the decisions index |

## Consequences

**Positive:**
- Existing projects see no behaviour change, only a truthful prompt.

**Negative:**
- Single-component projects still have to declare an `id`, now with a weaker reason than before.

**Risks:**
- A later feature finds no use for the `id`, and this ADR is revisited.

## Related ADRs

- 0000024-ADR-001 - partly supersedes
- ADR-002 - depends-on

## Supersedes

- Partly: 0000024-ADR-001 (rationale only)

## Superseded By

- None
