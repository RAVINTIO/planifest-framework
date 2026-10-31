---
title: "Backlog Entry: 0000343 - Part 11, Annex 11, and ALCOA+ requirement kit"
summary: "A requirement catalogue for systems that hold GxP records, and an ALCOA+ data integrity review at P5 beside STRIDE."
status: "open"
---
# Backlog Entry: 0000343 - Part 11, Annex 11, and ALCOA+ requirement kit

**Source feature:** none (GAMP 5 gap analysis)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Feature Pipeline
**Related:** 0000291, 0000337, 0000339

---

## Problem

A system that holds GxP records must meet FDA 21 CFR Part 11 and EU GMP Annex 11. Framework doesn't know these rules exist.

P1 writes requirements from the feature brief alone. If the brief omits audit trails or e-signatures, the requirements omit them too. The gap surfaces at audit, long after release.

P5 runs a STRIDE threat model in `ravintio-security-agent`. STRIDE covers attackers. It doesn't ask whether records stay attributable, legible, contemporaneous, original, and accurate (ALCOA+). A system can pass STRIDE and still let a user edit a result without a trace.

## Suggested Action

- Add a requirement catalogue for systems that hold GxP records. Cover at least:
  - audit trail content, protection, and review
  - e-signature meaning and binding to the record
  - access control and role separation
  - record retention
  - backup and restore
- When P0 records that the system holds GxP records, P1 draws matching requirements from the catalogue. The human keeps or waives each one, and a waiver goes to 0000287.
- Add an ALCOA+ data integrity review to P5 beside STRIDE.
- Build on the data classification triggers in 0000291.

Framework produces evidence and never claims compliance. The regulated company's quality unit decides whether the system meets Part 11 and Annex 11.

## Wanted outcome

- A GxP-record system can't pass P1 with a catalogue item left neither kept nor waived.
- The P5 security report holds an ALCOA+ section with one finding or a pass per principle.
- Tests show the catalogue stays silent when the system holds no GxP records.

## Open questions

- Who maintains the catalogue when a regulation changes?
- Should catalogue items carry a default risk class for 0000339?

## Why Deferred

The human asked for the GAMP 5 gap analysis findings to reach the backlog. It builds on 0000291 and needs its own design.
