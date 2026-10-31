---
title: "Backlog Entry: 0000349 - SOUP and third-party component register"
summary: "Keep a register of each third-party component with its version, supplier, requirements, licence, and known anomalies, filled from the SBOM and checked at P5."
status: "open"
---
# Backlog Entry: 0000349 - SOUP and third-party component register

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31

**Suggested route:** Feature Pipeline
**Related:** 0000280, 0000281, 0000290

---

## Problem

Medical device standards call third-party code "software of unknown provenance" (SOUP). Regulated teams must record each such component and why it's fit for use. Framework tracks dependencies only in package manifests. It keeps no record of what each component must do, who supplies it, or which known faults it carries.

These clauses expect such a register:

- IEC 62304 5.3.3, 5.3.4, and 7.1.3
- ISO 13485 7.4
- ISO 27001 A.8.30
- NIST SSDF PW.4

## Suggested Action

- Add a register template with one row per component. Each row holds these fields:
  - name and version
  - supplier
  - purpose
  - functional and performance requirements the component must meet
  - licence
  - known anomaly list
  - last review date
- Fill the name, version, supplier, and licence from the SBOM that 0000281 ingests.
- At P5, flag any dependency in the SBOM that has no register row.
- Leave purpose, requirements, and anomaly review to a human or to a profile rule (0000348). The agent drafts them but never marks a review done.
- Add the register to the evidence export (0000290).

## Wanted outcome

Every dependency in a run's SBOM has a register row with a review date. A test proves that P5 reports a dependency missing from the register.

## Why Deferred

Filed from the Zero comparison review on 2026-10-31. It depends on the SBOM ingest in 0000281 and the adapter contract in 0000280.
