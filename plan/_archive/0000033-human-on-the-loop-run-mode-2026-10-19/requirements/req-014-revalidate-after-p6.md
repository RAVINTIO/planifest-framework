---
title: "Requirement: req-014 - revalidate-after-p6"
summary: "The docs agent reruns the P4 check set after its P6 edits, or a smaller doc-check command that a product declares in planifest-overrides/doc-checks.yml."
status: "draft"
version: "0.1.0"
---
# Requirement: req-014 - revalidate-after-p6

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Source:** US-008
**Priority:** should-have

## User Story

As the human on the loop, I see the P4 checks run again after P6 edits, so that a doc edit can't break a check that already passed.

## Functional Requirements

### Docs agent skill (`planifest-framework/skills/planifest-docs-agent/SKILL.md`)

- **New section `## Post-P6 revalidation`:** It sits after `## What You Produce` and before `## Rules`. The docs agent runs it after its last doc edit and before it reports P6 complete.
- **Which checks run:**
  1. If `planifest-overrides/doc-checks.yml` exists and declares a `command`, run that command.
  2. Otherwise, rerun the P4 check set. That set is steps 0 to 5 of the validate-agent `## Process` section. Step 6 (verify by execution) doesn't rerun.
- **On pass:** Record the command or check set and the result in the P6 build-log block.
- **On failure:** Fix the P6 edit that caused it, then rerun the failing check. The loop follows `planifest-loop-runner` with the P4 cap of 5 cycles. Fix the doc, never the check. If the cap runs out, escalate in the validate-agent `VALIDATION BLOCKED` format. In `autonomous` mode, req-004 governs what happens at the cap.
- **Not caused by P6:** If the failing check doesn't trace to a P6 edit, record it and escalate in the same format. The docs agent doesn't change code under `src/` outside `docs/`.
- **Skip case:** If Gate B decided no docs update was needed and P6 made no edit, record `Post-P6 revalidation: skipped, no P6 edits` and skip the rerun.

### New template (`planifest-framework/templates/doc-checks.template.yml`)

- Documents one key, `command`, which holds a single shell command line. An example is `npm run test:docs`.
- States that the framework never creates `planifest-overrides/doc-checks.yml`. The product's human owns it, and the framework only reads it.
- States that the file is optional. If it's absent, P6 reruns the full P4 check set.

### Tests

- A new Bash suite, `planifest-framework/tests/test-0000033-req-014-revalidate-after-p6.sh`, covers this requirement through text assertions on the docs agent skill and the template. `run-tests.sh` picks it up.
- These suites assert docs agent text and must pass unchanged:
  - `planifest-framework/tests/test-0000025-req-006-docs-agent-continuous-run.sh`
  - `planifest-framework/tests/test-0000025-req-003-docs-agent-parallelism.sh`
  - `planifest-framework/tests/test-0000016-pipeline-governance.sh`

### Verified by

- The docs agent skill has a `## Post-P6 revalidation` heading after `## What You Produce` and before `## Rules`, checked by line number.
- The section names `planifest-overrides/doc-checks.yml` and the validate-agent `## Process` steps 0 to 5.
- The section names `planifest-loop-runner`, a cap of 5, and `VALIDATION BLOCKED`.
- The section records its result in the P6 build-log block and names the skip case.
- `planifest-framework/templates/doc-checks.template.yml` exists, declares `command`, and says the framework never creates the override file.

## Acceptance Criteria

- [ ] (feature AC 6) After its last edit, the docs agent reruns the P4 check set, or the `command` from `planifest-overrides/doc-checks.yml` when that file exists.
- [ ] (feature AC 6) A failing rerun enters a loop capped at 5 cycles that fixes the doc edit, and escalates in the P4 format at the cap.
- [ ] (feature AC 7) The new suite and the unchanged docs agent suites pass under `run-tests.sh`.

## Dependencies

- req-001 defines `autonomous`. req-004 defines the behaviour at a cap in `autonomous` mode.
- `planifest-validate-agent` defines the P4 check set and the `VALIDATION BLOCKED` format.

## Input Validation

- [ ] Input source: `planifest-overrides/doc-checks.yml`, key `command`
- [ ] Allowed character pattern: a single line. A value with a newline is invalid.
- [ ] maximum length: 500 characters
- [ ] Failure behaviour: if the file has no `command` key or the value is invalid, run the full P4 check set and log why in the P6 build-log block
- [ ] Logging policy: sanitised value only in output
