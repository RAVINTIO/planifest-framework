---
title: "Requirement: req-016 - always-parallel-work-units"
summary: "Each phase skill lists the work units that always run in parallel and dispatches them in one batch, so parallel dispatch is the default in every phase."
status: "draft"
version: "0.1.0"
---
# Requirement: req-016 - always-parallel-work-units

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Source:** US-006
**Priority:** must-have

## User Story

As the human on the loop, I see every phase dispatch its independent work units in one batch, so that no phase decides for itself whether to split work.

## Functional Requirements

### Dispatch standards (`planifest-framework/standards/agent-dispatch-standards.md`)

- **`## Parallelism Rules`:** Add a subsection headed `### Always-parallel work units`. It states these rules:
  1. Parallel dispatch is the default in every phase and every run mode.
  2. Each phase skill lists its always-parallel units under its `## Parallelism Directive`, in a list headed `**Always parallel:**`.
  3. The phase dispatches every listed unit that applies to the run in one batch. A batch is one message that holds one call per unit. Subagent work uses an `Agent` call, and a search or check uses a tool call.
  4. If a listed unit runs alone or in a later batch, the phase records the dependency reason in the build-log `Notes` field.
- The existing MUST-parallelise and Cannot-parallelise tables stay unchanged.
- The subsection states that the list sets a floor. A phase may batch more units when they pass the dependency test.

### Phase skills

Each skill below gains an `**Always parallel:**` list at the top of its parallelism section. Existing table rows stay unchanged.

- **Spec agent (`planifest-framework/skills/planifest-spec-agent/SKILL.md`, `## Parallelism Directive`):**
  - One subagent per requirement file with no cross-reference to a sibling.
  - Scope, risk register, and domain glossary.
- **ADR agent (`planifest-framework/skills/planifest-adr-agent/SKILL.md`, `## Parallelism Directive`):**
  - One subagent per ADR that doesn't cite another ADR in this run.
- **Codegen agent (`planifest-framework/skills/planifest-codegen-agent/SKILL.md`, `## Parallel Dispatch Checklist`):**
  - One TDD subagent per leaf requirement, as checklist step 3 already says. The list names step 3 as the batch.
- **Validate agent (`planifest-framework/skills/planifest-validate-agent/SKILL.md`, `## Parallelism Directive`):**
  - Lint and typecheck, as Batch 1.
  - Independent component test suites, within Batch 2.
- **Security agent (`planifest-framework/skills/planifest-security-agent/SKILL.md`, `## Parallelism Directive`):**
  - STRIDE threat modelling, dependency audit, secrets scan, and input validation scan.
  - One review per component with no shared secrets or auth logic.
- **Docs agent (`planifest-framework/skills/planifest-docs-agent/SKILL.md`, `## Parallelism Directive`):**
  - Per-component docs for independent components.
  - Living-doc updates with no shared content.
  - Recommendations and the iteration log.
- **Ship agent (`planifest-framework/skills/planifest-ship-agent/SKILL.md`):** Add a `## Parallelism Directive` section before `## P7: Archive`. It lists one always-parallel unit set:
  - The P7 cross-reference search for `plan/current/...` links, and the Step 4 scan for `# REGRESSION-CANDIDATE:` tags. Both are read-only searches.
  - The section states that the numbered P7 and P9 steps stay in order, because each step reads the output of the step before it.

### Back-compat

- The lists change how a phase dispatches, not what it produces. Gates, STOP rules, and artifacts stay the same in `interactive` and `continuous`. The existing standards already set parallel as the default posture.

### Tests

- Add `planifest-framework/tests/test-0000033-req-016-always-parallel-work-units.sh`. `run-tests.sh` picks it up.
- These existing suites assert the current Parallelism Directive text. Their assertions stay unchanged and must still pass:
  - `planifest-framework/tests/test-0000006-build-assessment.sh`
  - `planifest-framework/tests/test-0000010-framework-quality-improvements.sh`
  - `planifest-framework/tests/test-0000025-req-003-docs-agent-parallelism.sh`
  - `planifest-framework/tests/test-0000025-req-003-subagent-parallelism-expansion.sh`

### Verified by

- `agent-dispatch-standards.md` has an `### Always-parallel work units` heading inside `## Parallelism Rules`, checked by line number.
- That subsection names `**Always parallel:**`, `one batch`, and the build-log `Notes` field.
- Each of the spec, ADR, validate, security, and docs skills has `**Always parallel:**` inside its `## Parallelism Directive` section.
- The codegen skill has `**Always parallel:**` inside `## Parallel Dispatch Checklist`.
- The ship skill has a `## Parallelism Directive` heading before `## P7: Archive`, checked by line number.
- That ship section names `REGRESSION-CANDIDATE` and the cross-reference search.
- In each of the seven skills, the `**Always parallel:**` list has at least one item.
- The four existing suites above pass unchanged.

## Acceptance Criteria

- [ ] The spec, ADR, codegen, validate, security, docs, and ship skills each list their always-parallel work units and say to dispatch them in one batch.
- [ ] `agent-dispatch-standards.md` states that parallel dispatch is the default in every phase and that a unit run alone needs a build-log reason.
- [ ] The new suite and the four existing parallelism suites pass under `run-tests.sh`.

## Dependencies

- 0000006-ADR-003 (parallelism lives in skill text, not hooks). This requirement adds skill text only and needs no new hook or script.
- req-015 runs these batches inside each stream when `parallel_streams` resolves `on`.
- req-017 owns the join after each batch.
- req-018 records the subagent count that shows whether each batch ran.
- req-012 and req-013 also change the ship skill's P7 steps. The new ship `## Parallelism Directive` must name the steps as they stand after those changes.
