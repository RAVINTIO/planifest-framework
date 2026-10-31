---
title: "Backlog Entry: 0000338 - GAMP specification hierarchy and a living system spec"
summary: "Map Framework artefacts to URS, FS, and DS, add a configuration specification for Category 4, and keep one versioned system specification across runs."
status: "open"
---
# Backlog Entry: 0000338 - GAMP specification hierarchy and a living system spec

**Source feature:** none (GAMP 5 gap analysis)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Feature Pipeline
**Related:** 0000268, 0000296, 0000340, 0000337

---

## Problem

A GAMP 5 auditor expects a specification hierarchy: user requirements (URS), functional specification (FS), and design specification (DS). Framework writes similar artefacts but never names that mapping.

- The feature brief and user stories hold user intent.
- Requirement files hold functional behaviour.
- ADRs and the execution plan hold design.

Framework has no configuration specification, which a Category 4 system needs.

Specs also live per run. P7 moves them to `plan/_archive/{feature}/`. After ten runs, nobody can read the current specification of the system in one place. An auditor must rebuild it from ten archives.

Requirements already carry `Verified by:` lines in `ravintio-framework/templates/requirement.template.md`. Nothing states which spec level each test verifies, so the V-model stays implicit.

## Suggested Action

- Publish a mapping from Framework artefacts to URS, FS, and DS when the GxP profile in 0000337 is on.
- Add a configuration specification template for Category 4 systems.
- Keep a living, versioned system specification outside the archive. Each run updates that one baseline, and the archive keeps the run's delta. Reuse the permanent-home approach that 0000296 proposes for ADRs.
- State the V-model mapping per release: which spec level each test verifies.

Framework produces evidence and never claims compliance. The regulated company's quality unit owns the validation decision.

## Wanted outcome

- A reader finds the current URS, FS, and DS of a system at one fixed path.
- Each release records a version of that baseline and the runs that changed it.
- Each test names the spec level it verifies, and 0000340 can build on that link.

## Open questions

- Should the living spec sit under `docs/` or per component under `src/{component}/docs/`?
- How do Gherkin criteria from 0000268 map to FS entries?

## Why Deferred

The human asked for the GAMP 5 gap analysis findings to reach the backlog. This needs its own design and depends on 0000337.
