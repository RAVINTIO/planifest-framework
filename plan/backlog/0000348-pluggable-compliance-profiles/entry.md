---
title: "Backlog Entry: 0000348 - pluggable compliance profiles"
summary: "Let a versioned profile set the artefacts, gates, evidence kinds, approver roles, and trace chains a regulated run needs, with skeletons in the pack and organisation copies in overrides."
status: "open"
---
# Backlog Entry: 0000348 - pluggable compliance profiles

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31

**Suggested route:** Feature Pipeline
**Related:** 0000279, 0000285, 0000286, 0000287, 0000288, 0000290, 0000337, 0000356, 0000357

---

## Problem

Entry 0000285 gives Framework a control catalogue, control tags, evidence status, and a matrix. A regulated team needs more than that. Nothing in Framework covers these needs:

- tiering a run by inputs, such as safety class or SOX scope
- choosing the artefacts and templates a tier requires
- gate rules per phase, with evidence kinds and approver roles
- trace chains longer than a control tag
- stacking more than one framework on a run
- versioning a profile and locking it for a run

## Suggested Action

- Ship skeleton profiles in `ravintio-framework/profiles/`. Each skeleton holds clause IDs and short titles only, because ISO and IEC text is under copyright.
- Organisations copy a skeleton into `ravintio-overrides/profiles/` and extend it.
- Use a YAML shape like this one:

```yaml
profile: medical-device-software
version: 1.0.0
standards:
  - { id: IEC 62304, edition: "2006+A1:2015" }
classify:
  safety-class: [A, B, C]
artefacts:
  - { id: soup-register, template: soup-register.template.md, phase: P1, when: "safety-class in [B, C]" }
gates:
  P4:
    evidence: [test-report, risk-control-verification]
    approvals: [{ role: qa, independent-of: author }]
trace:
  - [hazard, risk-control, requirement, test]
controls: [catalogue-ref-from-0000285]
```

- P0 asks the `classify` keys, resolves the active profiles, and writes them into `design.md`. Entry 0000288 locks them by hash.
- A profile only adds artefacts, gates, and trace rules. It never removes a base gate.
- Stacked profiles take the strictest rule, and P0 reports each conflict.
- Phase skills read the resolved profile. They never branch on a framework name.
- Evidence that reads `missing` or `unknown` fails a gate. Entry 0000287 handles waivers.
- The `none` profile keeps today's behaviour.

First skeletons:

1. GxP (0000337).
2. Medical device software: IEC 62304, with ISO 14971 and ISO 13485 design controls.
3. NIST SSDF with SLSA. It covers much of ISO 27001 A.8.25 to A.8.33 and SOX change management.
4. ISO 27001 Annex A mapping. It maps A.5.8, A.5.19 to A.5.23, A.8.4, A.8.9, and A.8.25 to A.8.33 to Framework evidence. It reuses the SSDF evidence where the two overlap.

0000356 proposes which frameworks Framework enforces by default and which it offers as profiles.

DO-178C, ISO 26262, and EN 50716 aren't worth targeting. An LLM code generator would need the top tool qualification level under each of them.

## Wanted outcome

A run under a profile produces exactly the artefacts, gates, and trace chains that profile names. Tests check that a stacked run takes the strictest rule, and that `none` changes nothing.

## Why Deferred

Filed from the Zero comparison review on 2026-10-31. It needs its own design and depends on 0000285 and 0000288.
