---
title: "ADR 019: Records come from scans, never seeded"
summary: "No record comes from the old _done/ folder. In this repo, P3 runs the scans of the six returning migrations and records each result. The two downstream-only migrations get not applicable without a run. A scan with findings writes no record until the human on the loop answers, so in an autonomous run it stays pending as an exception waiting for review."
status: "accepted"
version: "0.1.0"
---
# ADR-019 - Records come from scans, never seeded

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000035-write-gate-scope-and-path-hardening
**Component:** planifest-framework
**Date:** 2026-10-22

## Context

ADR-015 removes `_done/`, and ADR-018 makes any migration with no record pending. On the first session after this release, every project has no records. Something must create the first ones.

Six migrations sat in `_done/` in this repo. That shows they ran here at some time, against an older layout. It says nothing about a downstream project, and it doesn't prove this repo still complies.

Two migrations are downstream-only. They fix setup state in projects that consume the framework. This repo is the framework source, so they never apply here.

This run is `autonomous`. The migrator's Hard Limit 3 needs a human answer for each findings batch. `autonomous-run-standards.md` lists the exceptions that wait for the human on the loop.

## Decision

1. Nothing seeds records from an old `_done/` folder, here or downstream.
2. In this repo, P3 runs the scans of the six returning migrations and writes each record from the result. A clean scan gets `applied` with both counts at `0`.
3. P3 writes `not applicable` records for the two downstream-only migrations without running them. Each body names the reason: this repo is the framework source.
4. A scan with findings writes no record until the human on the loop answers every batch. The migration stays pending until then.
5. In an `autonomous` run, P3 logs one `Exception waiting (P3, human review): {migration}: {findings}` line per migration with findings. P4 reports req-010 AC-010.1 as open. No agent forces a record to close it.
6. An apply answer gives `applied`. An answer of `none` gives `skipped`.
7. A downstream project treats all eight migrations as applicable. Each scan decides its outcome.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Seed `applied` records from `_done/` | No rescans, quiet first session | Records a claim no scan checked. Downstream, `_done/` reflects the framework repo, not the project. | A record must come from a scan run in that project. |
| Write a record for a scan with findings, marked part-done | The run closes AC-010.1 alone | Needs a fourth outcome, which ADR-016 rejected. Hides findings the human on the loop never saw. | Breaks Hard Limit 3 of the migrator and the no-record-means-pending rule. |
| Run the downstream-only migrations here | Every record comes from a scan | Their scans look for setup state this repo doesn't carry. Findings would be false or confusing. | Scope rules them out. `not applicable` states the fact. |
| Mark the downstream-only migrations `not applicable` everywhere | No scan downstream | The framework can't know which projects need them. | Each downstream scan decides. |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | P3 writes eight records in `plan/_migrations/` or logs an exception for each migration with findings. The migrator skill states the no-record-until-answered rule. |

## Consequences

**Positive:**
- Every record reflects a scan in the project that holds it, or a stated reason it doesn't apply.
- Findings always reach the human on the loop before a record closes the migration.
- A compliant downstream project gets clean scans and `applied` records on first use.

**Negative:**
- Every downstream project rescans six older migrations after refresh (R-003).
- AC-010.1 may stay open at the end of this autonomous run, waiting on the human on the loop.

**Risks:**
- An older scan may report false findings against today's layout (R-013, A-002). Those findings wait for the human on the loop, who can answer `none` to get a `skipped` record.
- A scan that can't run leaves its migration pending, so the next session tries again.

## Related ADRs

- ADR-015 - depends-on: `_done/` goes away, so it can't seed anything.
- ADR-016 - depends-on: defines the outcomes P3 writes.
- ADR-017 - related-to: P3 writes through the migrator's Record step.
- ADR-018 - depends-on: a migration with findings stays pending under its rule.

## Supersedes

- None

## Superseded By

- None
