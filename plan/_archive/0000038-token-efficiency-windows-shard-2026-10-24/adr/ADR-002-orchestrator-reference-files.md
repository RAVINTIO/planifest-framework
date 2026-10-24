---
title: "ADR 002: Phase 0 and Adoption Modes live in two orchestrator reference files"
summary: "Phase 0 and Adoption Modes move into two files under the orchestrator skill's references folder. The orchestrator reads both at the start of P0, and Resume Detection reads them again when a resumed run is still at P0."
status: "accepted"
version: "0.1.0"
---
# ADR-002 - Phase 0 and Adoption Modes live in two orchestrator reference files

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000038-token-efficiency-windows-shard
**Component:** planifest-framework
**Date:** 2026-10-24

## Context

The orchestrator `SKILL.md` is 77,635 bytes. Phase 0 (about 33,000 bytes) and Adoption Modes (about 4,700 bytes) are only needed during P0. Every later request still carries them. Req-004 moves both out and leaves the location to P2. It sets a target of under 41,500 bytes for `SKILL.md`.

Constraints:
- `setup.sh` `copy_skills` copies a skill's `references/` folder with `cp -r`, so a file there reaches every installed tool. The orchestrator `references/` folder holds only `.gitkeep` today.
- `setup.sh` also copies standards into `references/`. The new names must not collide with a standard.
- The `auto-trigger-orchestrator` hook loads `SKILL.md` only. It cannot load a second file.
- A moved block must stay byte-identical to commit `5966840`, so a test can compare it.

## Decision

Use two files in `planifest-framework/skills/planifest-orchestrator/references/`:

- `phase-0-assess-and-coach.md` holds the `## Phase 0 - Assess and Coach` section.
- `adoption-modes.md` holds the `## Adoption Modes` section.

Rules:
1. Each file starts with a short frontmatter block and one line naming `SKILL.md` as its owner. The moved block follows with its heading unchanged. The byte-for-byte test compares the block, not the whole file.
2. `SKILL.md` keeps one short section, `## Phase 0 and Adoption Modes (reference files)`. Its heading differs from the moved headings, so the absence test passes. The section links both files by relative path (`./references/...`) and says when to load them.
3. The Framework Index gains one row for each file.
4. At the start of P0, before any P0 action, the orchestrator reads both files in full.
4a. After the read, the orchestrator writes one build-log line, `P0 references loaded: {paths}`, naming both files. The pointer section in `SKILL.md` holds this instruction. It also holds the gate check: before the P0 to P1 gate passes, the orchestrator confirms the line exists in the build log. The moved Phase 0 block, including its Gate Checklist, stays byte-identical to `5966840`, and the byte test has no exclusion. A skipped read then shows in the build log, and a unit test pins the line and the gate check in the pointer section.
5. Resume Detection gains a step. When the resumed run is still at P0, which means the build log records no passed P0 gate, the orchestrator reads both files again.
6. A run past P0 never loads either file, except when it re-enters P0 through a reversal. A reversal that reopens P0 follows rule 4.
7. Two files, because Adoption Modes feeds the mode choice inside P0 only. A loader can then read each on its own.

Decision (P2): two reference files in the orchestrator's `references/` folder, loaded at P0 start and on resume at P0 / reason: setup already copies that folder, the hook needs no change, and each block stays byte-identical.

Decision (P2): `SKILL.md` keeps a pointer section with a heading that differs from the moved headings / reason: the absence test would otherwise fail on the pointer itself.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| One combined reference file | One load | Mixes two unrelated blocks and weakens the per-block byte test | Two files test more cleanly |
| Put the files in `planifest-framework/standards/` | Reuses the standards copy | Standards copy into every skill's `references/`, so the text spreads to skills that never need it | Wider install footprint |
| Put the files in `templates/` | Existing JIT pattern | Templates describe output shapes, not procedures | Wrong category |
| Make the auto-trigger hook load them | Automatic | Loads the text on every session, which defeats the saving | Defeats the goal |
| Split Phase 0 into several smaller files | Finer loading | Word-for-word move gets harder to verify, and P0 needs most of it at once | No saving inside P0 |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | New files, a smaller `SKILL.md`, a new Framework Index rows and resume step, test greps repointed |

## Consequences

**Positive:**
- Every request after P0 carries about 37,000 fewer bytes.
- Installs get the files with no `setup.sh` change.

**Negative:**
- P0 now costs one extra read step. If the orchestrator skips it, P0 runs without its rules.
- Tests that grep the moved text must point to the new files.

**Risks:**
- The margin is 1,799 bytes. `SKILL.md` is 77,635 bytes now. Removing Phase 0 (33,261 bytes) and Adoption Modes (4,673 bytes) leaves 39,701, and 41,500 less 39,701 is 1,799. These additions must fit in it, with a working budget for each:
  - the pointer section, including the load instruction, the log line, and the gate check: 650 bytes
  - two Framework Index rows: 280 bytes
  - the resume step: 300 bytes
  - the req-005 advisory text: 400 bytes
  The budgets total 1,630 bytes and leave about 170 bytes spare. A size test fails the build if `SKILL.md` reaches 41,500.
- A resumed run could skip the reload. A unit test pins the resume wording.
- A downstream project that has not re-run setup lacks the files. The 0.36.0 migration covers this (ADR-007).

## Related ADRs

- ADR-007 - depends-on (the migration lists the new reference files)

## Supersedes

- None.

## Superseded By

- None.
