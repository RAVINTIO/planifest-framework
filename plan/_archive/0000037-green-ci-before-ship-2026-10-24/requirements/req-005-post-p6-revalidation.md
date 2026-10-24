---
title: "Requirement: req-005 - post-p6-revalidation"
summary: "After the P6 commit the docs agent reruns the product's doc-check command, or the full P4 check set when none is declared, and a failure loops with a cap."
status: "draft"
version: "0.1.0"
---
# Requirement: req-005 - post-p6-revalidation

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000037-green-ci-before-ship
**Source:** US-005
**Priority:** should-have

## User Story

As the human on the loop, I see the P4 checks rerun after the P6 docs edits, so that a docs change can't break a green check before ship.

## Functional Requirements

### Current state (read before P3)

`planifest-framework/skills/planifest-docs-agent/SKILL.md` already holds a `## Post-P6 revalidation` section (0000033 ADR 012). It reads `planifest-overrides/doc-checks.yml` and falls back to P4 steps 0 to 5. It caps the failure loop at 5 cycles. This requirement closes four gaps and changes no other behaviour.

### Run after the P6 commit

- The docs agent runs revalidation after the P6 commit and before it reports P6 complete. A revalidation that runs only after the last doc edit but before the commit doesn't satisfy this.
- If `planifest-overrides/doc-checks.yml` declares a valid `command`, run that command. A valid `command` is one line of at most 500 characters.
- If the file is absent, or has no valid `command`, rerun P4 steps 0 to 5 of the validate-agent `## Process`. Step 6 (verify by execution) doesn't rerun. If the file exists but its `command` is invalid, log why.
- The product declares the command in `planifest-overrides/doc-checks.yml`, copied from `planifest-framework/templates/doc-checks.template.yml`. The framework never creates this file. This keeps the declaration with the other product-owned overrides and needs no new file type.
- If P6 made no edit, skip the rerun and record the skip.

### Log line

- The docs agent writes one build-log line in the P6 block, in this form:
  - `Revalidation (P6): {command | P4 steps 0-5}, {pass | fail | skipped, no P6 edits}`
- A failure also writes the failing check and its cycle count on the same line.

### Failure handling

- In `interactive` and `continuous`, a failure follows the existing rule. The docs agent fixes the P6 edit, never the check, and loops up to 5 cycles. After the cap it escalates in the `VALIDATION BLOCKED` format.
- In `autonomous`, the revalidation runs as a loop under `planifest-loop-runner` with a cap of 3 cycles. This matches the other P1 to P6 loops in `standards/autonomous-run-standards.md` (Gates as loops).
  - When the cap runs out, the agent starts a new approach under `## Changing approach`. Each approach states how it differs from the last.
  - After 3 approaches, the failure becomes an exception-list item: `Exception waiting (P6, 6): revalidation {failing check and what the human on the loop must do}`. Item 6 is the exhausted-budget item. The run carries on with work that doesn't depend on the failing check, and the final report lists the item.
- If the failure doesn't trace to a P6 edit, the agent records it and escalates, as today. It doesn't change code under `src/` outside `docs/`.

### Named in the routing surfaces

- The orchestrator's Phase Invocation Table row for P6 lists a passing revalidation in its gate condition.
- The P6 row of the Gates as loops table in `planifest-framework/standards/autonomous-run-standards.md` lists a passing revalidation in its pass condition.

## Acceptance Criteria
- [ ] After the P6 commit, the docs agent runs the command in `planifest-overrides/doc-checks.yml`, or P4 steps 0 to 5 when no valid command exists. It then writes `Revalidation (P6): {command | P4 steps 0-5}, {pass | fail | skipped, no P6 edits}`. Verified by: integration (a fixture repo with and without the override file).
- [ ] If revalidation fails in `autonomous`, the docs agent loops with a cap of 3 and up to 3 approaches, then files `Exception waiting (P6, revalidation)`. Outside `autonomous` it keeps the 5-cycle cap and the `VALIDATION BLOCKED` escalation. Verified by: unit (a test that reads the docs-agent and standards text for both caps).
  - Amended (P2): the exception line reads `Exception waiting (P6, 6): revalidation {failing check}`, so it keeps the `(P{N}, {item})` format (ADR-006).
- [ ] The orchestrator's P6 gate condition and the autonomous standard's P6 pass condition both name a passing revalidation. Verified by: unit (a text test over both files).

## Split step: keep

Three criteria, so the split step does not trigger. The three describe one outcome: a docs edit can't leave a failing check unseen. Each checks a different surface of that outcome.

## Dependencies
- 0000033 ADR 012, which created the revalidation section and `doc-checks.template.yml`.
- `planifest-framework/standards/autonomous-run-standards.md` (Gates as loops, Changing approach).
- `planifest-framework/skills/planifest-loop-runner/SKILL.md`.
- Files P3 changes: `planifest-framework/skills/planifest-docs-agent/SKILL.md`, `planifest-framework/skills/planifest-orchestrator/SKILL.md`, `planifest-framework/standards/autonomous-run-standards.md`, `planifest-framework/templates/doc-checks.template.yml` (comment text only if needed).
