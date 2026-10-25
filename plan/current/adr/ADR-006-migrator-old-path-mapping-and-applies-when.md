---
title: "ADR 006: Migrator old-path mapping and Applies when"
summary: "The migrator keeps file-name order, maps old pack paths to new ones when it runs shipped pre-0.37.0 migrations, and skips a migration whose Applies when line is false."
status: "accepted"
version: "0.1.0"
---
# ADR-006 - Migrator old-path mapping and Applies when

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000039-ravintio-rebrand
**Component:** ravintio-framework (renamed from planifest-framework)
**Date:** 2026-10-25

## Context

The orchestrator lists pending migrations in file-name order. `migrate-0.37.0-ravintio-rename.md` sorts before four older migrations:

- `migrate-adoption-mode-and-about-md.md`
- `migrate-product-yml-component-paths.md`
- `migrate-remove-context-mode-and-telemetry.md`
- `retroactive-release-tags.md`

A consumer on 0.36.0 that has not run those four reaches them after the rename. By then `planifest-framework/` has moved to `.ravintio-backup/` and `ravintio-framework/` holds the live pack. The shipped bodies name `planifest-framework/` paths, so they would read a pack that is gone.

Shipped migration bodies must stay byte-identical (ADR-009). The old pack in `.ravintio-backup/` must never act as a live pack (ADR-005).

Two more facts shape the choice:

- An installed 0.36.0 orchestrator scans only `planifest-framework/migrations/`. It cannot find the rename migration inside the copied `ravintio-framework/`.
- This source repo and a fresh consumer have no old pack. The rename migration does not apply to either, yet it must not show as pending.

## Decision

Keep file-name order for pending migrations. Resolve old paths in the migrator instead of changing the order or the migration bodies.

- When the migrator runs a migration shipped before 0.37.0, it maps `planifest-framework/` to `ravintio-framework/` and `planifest-overrides/` to `ravintio-overrides/`. It also maps `planifest-` skill names to `ravintio-`.
- The migrator applies the mapping to the paths it reads and writes. It never edits the shipped file, so each body stays byte-identical.
- The migrator never reads `.ravintio-backup/` as a live pack.
- The migrator reads an `**Applies when:**` line near the top of a migration. If the condition is false, it skips Steps 2 to 4 and reports `Skipped:` with the reason. It records `not applicable` with both counts at `0`.
- This source repo and a fresh consumer both read the condition as false. Both get the `not applicable` record, so the rename migration is never pending there. This follows 0000035 ADR 010 and RAVINTIO Zero 0000160 ADR 003.
- The orchestrator reports every migration it skips for a false condition. It never skips one silently.
- The migrator's framework source check reads `id: "ravintio-framework"` in the root `product.yml`.
- A 0.36.0 consumer runs the rename helper by hand, from the upgrade steps, before setup. The helper writes no record. The new migrator then finds the rename migration pending, runs a no-op helper rerun as a check pass, and records `applied`.

Decision (P2): keep file-name order and map old paths in the migrator / reason: it leaves shipped bodies and migration names untouched, and it keeps the backup out of every read.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Rename the rename migration so it sorts last | No path mapping. Older migrations run against the old pack. | The old pack is gone by the time the helper runs, since the helper must run before setup. A 0.36.0 orchestrator also lists only the old folder. The name would carry a sort trick that later releases must keep honouring. | Older migrations would still need the old paths, and the helper has to run first. |
| Rewrite the old migration bodies to name the new paths | Bodies match the live layout. No mapping rule. | Breaks byte-identical history (ADR-009). Edits migrations that already ran in other repos. A consumer on an older tag would find bodies that name paths it does not have. | History must stay as written. |
| Order by version number in place of file name | Explicit, readable order | Most migrations carry no version in the name. Needs a new metadata field on every shipped file. Changes an ordering rule that consumers already rely on. | Too much new surface for one rename. |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-framework | The migrator skill gains path mapping and `Applies when:` support. The orchestrator reads `ravintio-framework/migrations/` and reports skipped migrations. |
| setup-hook-integration | Setup stops while the old folders exist and names the migration. Setup does not run the helper. |

## Consequences

**Positive:**
- Shipped migration bodies stay byte-identical, so history and checksums hold.
- Older migrations run in the order they always ran, against the live pack.
- This source repo and every fresh consumer get a clean `not applicable` record, and the rename migration never shows as pending.
- Any later migration can use `Applies when:` to skip itself with a visible reason.

**Negative:**
- The migrator carries a path-mapping rule that exists only for pre-0.37.0 bodies. A maintainer who reads a body next to its run must know the mapping.
- A 0.36.0 consumer must run the helper by hand before setup, because the installed orchestrator cannot find the migration. A human on the loop who skips that step meets the setup stop.

**Risks:**
- The mapping misses a path form, such as a path built from parts. An older migration then reads a missing folder. The integration test with a 0.36.0 fixture covers the shipped bodies.
- A bug in the mapping reads `.ravintio-backup/` as a live pack. The test asserts that no migration run reads that folder.
- A wrong `Applies when:` result marks a real consumer `not applicable`. The consumer then keeps the old pack. Setup still stops while the old folders exist, so the error surfaces there.

## Related ADRs

- ADR-002 - depends-on (the rename map defines the path and skill-name pairs)
- ADR-005 - depends-on (the backup folder the migrator must never read as live)
- ADR-009 - depends-on (shipped migration bodies stay as written)
- ADR-004 - related-to (old-name reads follow the same no-silent-fallback idea)

## Supersedes

- None.

## Superseded By

- None.

Governs: req-009. Related: req-001, req-006.
