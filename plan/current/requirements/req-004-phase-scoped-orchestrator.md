---
title: "Requirement: req-004 - phase-scoped orchestrator"
summary: "Phase 0 and Adoption Modes move word for word into reference files loaded at P0."
status: "active"
version: "0.1.0"
---
# Requirement: req-004 - phase-scoped orchestrator

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000038-token-efficiency-windows-shard
**Source:** US-004
**Priority:** should-have

## User Story

As an agent past P0, I don't carry the P0 and Adoption Modes text, so that each request carries less context.

## Functional Requirements
- The `## Phase 0 - Assess and Coach` section (lines 239 to 588 of `planifest-framework/skills/planifest-orchestrator/SKILL.md`, about 33,000 bytes) moves word for word into a reference file.
- The `## Adoption Modes` section (lines 768 to 818, about 4,700 bytes) moves word for word into a reference file.
- The orchestrator loads both files at P0. The Framework Index lists them.
- Resume Detection loads them again when a resumed run is still at P0.
- Each test assertion that greps the moved text points to the new file.
- A new test checks that the moved text no longer sits in `SKILL.md`, so no grep passes on the wrong file.
- `SKILL.md` ends under 41,500 bytes. It stands at 77,635 bytes now.
- The reference file location and any file split is a P2 decision.

## Acceptance Criteria
- [ ] The moved sections match their original text word for word, and the Framework Index lists both reference files. Verified by: unit
- [ ] A new test finds none of the moved text in `SKILL.md`, and every existing assertion on that text reads the new file. Verified by: unit
- [ ] The orchestrator loads the reference files at P0, Resume Detection reloads them for a resumed run at P0, and `SKILL.md` is under 41,500 bytes. Verified by: unit

## Dependencies
- The `auto-trigger-orchestrator` hook still loads `SKILL.md` at session start.
- Test suites that grep orchestrator text. P3 runs the full suite after the move.
- Orchestrator rule-restatement tests from earlier features (canonical-file pointers).

Split step: keep. The move, the grep updates, and the reload rule all serve one outcome, a smaller orchestrator after P0.
