---
title: "ADR 003: Ship the rename as 0.37.0 and remove old-name reads at 1.0.0"
summary: "The rename release is a minor bump to 0.37.0. Old-name reads stay through 0.x and go at 1.0.0."
status: "accepted"
version: "0.1.0"
---
# ADR-003 - Ship the rename as 0.37.0 and remove old-name reads at 1.0.0

**Skill:** [adr-agent](../skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000039-ravintio-rebrand
**Component:** ravintio-framework
**Date:** 2026-10-25

## Context

The pack is at 0.36.0. The rename changes pack paths, skill names, variables, and marker files. Consumers must run a migration to upgrade.

Backlog 0000237 suggested a major bump for this change. The human on the loop set the release to 0.37.0 at P0 on 2026-10-25. That decision overrides the backlog suggestion.

Semantic versioning allows a breaking change in a 0.x release. A 0.x number does not hide the break. The migration and the release notes carry it.

RAVINTIO Zero shipped its rename as 1.0.0 and then relabelled it 0.12.0 (RAVINTIO Zero 0000164 ADR 005). The relabel cost a tag deletion and confused tools that had already seen the 1.0.0 tag.

Setup keeps a few old-name reads so a consumer can upgrade in steps. ADR-004 lists them. They need a removal point.

## Decision

- The rename ships as 0.37.0, a minor bump from 0.36.0.
- P6 writes 0.37.0 to `product.yml`, `ravintio-framework/component.yml`, and `docs/about.md` (req-010).
- No live file names 1.0.0 as this release (req-010).
- The old-name reads in ADR-004 stay through the 0.x line.
- They go at 1.0.0. The 1.0.0 release removes them and says so in its change record.
- The migration body and the change record state the 1.0.0 removal point in plain words (req-010, req-006).

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Ship the rename as 1.0.0, as backlog 0000237 suggests | Signals a break at the version number | The human on the loop asked for a rename, not a major version. 1.0.0 also claims a stable interface the pack does not yet offer. RAVINTIO Zero had to relabel its 1.0.0 | The human on the loop chose 0.37.0 at P0. The sibling repo shows the cost of the other path |
| Remove the old-name reads now, with no window | Setup code has one name to read. The brand guard needs fewer allowlist entries | A consumer who sets `PLANIFEST_SESSION_ID` or keeps an old boot-file block loses behaviour or gets a duplicate block on the first setup run | Consumers upgrade in steps, so a window protects them. The cost of keeping the reads is small |
| Keep the old-name reads until 2.0.0 | A longer window for slow consumers | The old name stays in live code for two more major lines. The brand guard keeps its allowlist entries for that whole time | 1.0.0 is the next planned break. A longer window gives no extra safety and keeps the old name alive |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-framework | Version fields in `component.yml`, `product.yml`, and `docs/about.md` read 0.37.0. The old-name reads in setup carry a 1.0.0 removal note. |
| setup-hook-integration | Its tests cover the old-name reads through 0.x. They must be removed or inverted at 1.0.0. |

## Consequences

**Positive:**
- No tag deletion and no relabel. Tools see one release number for the rename.
- A consumer can upgrade in steps. The old session variable and old boot-file blocks keep working until 1.0.0.
- The 0.x line leaves room to declare a stable interface later, on purpose.

**Negative:**
- A minor bump hides a breaking change from tools that read only the version number. A consumer who auto-accepts minor updates gets a pack that fails until they run the migration. Setup stops with a message that names the migration.
- The old name stays in setup code and in brand guard allowlist entries until 1.0.0. Each entry costs review time.

**Risks:**
- The 1.0.0 removal is easy to forget. A consumer's old setting then works much longer than planned. The removal point is written in the migration body and in the allowlist reasons, so the guard names it.
- A reader who expects a major bump for a rename may skip the migration. The setup stop for an old pack folder covers that case.

## Related ADRs

- ADR-004 - depends-on. It defines which old names setup reads.
- ADR-005 - related-to. It covers the backup that the migration keeps.
- ADR-007 - related-to. Its allowlist entries for old-name reads cite the 1.0.0 removal.
- RAVINTIO Zero 0000164 ADR 005 - extends. This record applies the same version logic from the start.

## Supersedes

- None

## Superseded By

- None
