---
title: "ADR 001: Stack unchanged, new detail in standards files"
summary: "0000033 keeps the declared stack of Markdown skills and Node .mjs scripts. New autonomous, sizing, and dispatch detail goes into standards files that the skills link to, so the orchestrator skill grows by short link lines only."
status: "accepted"
version: "0.1.0"
---
# ADR-001 - Stack unchanged, new detail in standards files

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Component:** planifest-framework
**Date:** 2026-10-19

## Context

The design declares this stack:

- Markdown skills and standards
- Node `.mjs` scripts and hooks
- GitHub Actions CI
- a local build target

The design declares no database, ORM, IaC, cloud, or compute. Every change lands in `planifest-framework`.

This feature adds a lot of new rule text. The new `autonomous` run mode needs these sections:

- a run-mode table
- an exception list
- gate checkers
- an approach budget
- visibility line formats

P0 also gains size classes for the release budget. Each phase skill gains a list of always-parallel work units.

The orchestrator skill already holds 9,276 words. The design's first risk, and risk register R-001, say it will grow further. NFR-005 asks that new detail go into standards files and that the skill links to them. Backlog 0000020 decomposes the orchestrator in a later run, and this run keeps it out of scope.

Two new scripts carry the deterministic checks: `scripts/archive-current.mjs` (req-012) and `scripts/stream-reconcile.mjs` (req-017). Both fit the declared Node stack.

## Decision

- **Stack:** The stack stays as the design declares it. The feature adds no language, runtime, library, or service. The two new scripts are Node `.mjs` files with no new dependency. Their tests run under the existing `run-tests.sh` and the 0000031 CI jobs.
- **Where new detail lives:** New rules go into standards files under `planifest-framework/standards/`:
  - `autonomous-run-standards.md` is a new file. req-001 creates it, and req-002 to req-006 add sections.
  - `release-sizing.md` is a new file. It holds the small, medium, and large size classes (D-006, req-010).
  - `agent-dispatch-standards.md` already exists. It gains the parallel-dispatch and join rules (req-015 to req-017).
  - `formatting-standards.md` already exists. It gains the choice-prompt rule (req-007).
- **How skills refer to it:** The orchestrator and phase skills add a short line that links to the standards section. They don't copy the rule text. The only rule text in a skill is a sentence that an existing test or a stop rule needs at that exact point.
- **Measure:** P6 reports the orchestrator skill's word count, as NFR-005 requires.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Put the new rules inline in the orchestrator and phase skills | Each rule sits where an agent acts on it, so no extra file read | The orchestrator grows well past 9,276 words. Rules repeat across seven phase skills and drift apart. | Breaks NFR-005 and raises R-001 |
| Decompose the orchestrator skill in this run | Fixes the size problem at its root | Doubles the run size on top of 10 stories. It overlaps backlog 0000020, which the design puts out of scope. | Out of scope by the confirmed design |
| Add a new skill for `autonomous` mode | Keeps run-mode rules apart from the orchestrator | A skill loads per phase, but every phase needs the run-mode rules. It also adds a skill that the host tool doesn't need (0000027-ADR-003). | Standards files already serve shared rules |
| Write the reconcile and archive checks as skill text, not scripts | No new code | Both checks are deterministic. Skill text alone fails the ignore test of 0000016-ADR-007. | ADR-014 and ADR-010 record the script choice |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | Two new standards files and two edited ones. Two new Node scripts with tests. The orchestrator and phase skills gain link lines in place of rule text. |

## Consequences

**Positive:**
- The orchestrator skill grows by link lines only, which keeps a fresh session able to read it.
- Each rule has one home, so seven phase skills can't drift apart on it.
- Backlog 0000020 can split the orchestrator later without moving the new rules again.

**Negative:**
- An agent must open a second file to apply a rule. A session that skips the link misses the rule.
- Tests must assert text in two places: the link line in the skill and the rule in the standards file.

**Risks:**
- An agent reads the skill but not the linked standards file, and applies `interactive` behaviour in an `autonomous` run. The text-level tests assert that each skill names `autonomous-run-standards.md` (req-002).
- The orchestrator still grows past an acceptable size. The P6 word count makes that visible, and 0000020 follows this run.

## Related ADRs

- 0000006-ADR-003 (parallelism as skill instructions) - related-to. Dispatch rules stay in text, now in a standards file.
- 0000016-ADR-007 (deterministic enforcement) - depends-on. It justifies the two scripts.
- 0000027-ADR-003 (skill-scope principle) - related-to
- ADR-002, ADR-003, ADR-004, ADR-005 - related-to. Their rules live in `autonomous-run-standards.md`.
- ADR-008 - related-to. Its size classes live in `release-sizing.md`.
- ADR-010, ADR-014 - related-to. They record the two scripts.

## Supersedes

- None

## Superseded By

- None
