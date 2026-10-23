---
title: "Requirement: req-006 - design-critic-default"
summary: "An absent design_critic key, or an absent loop-toggles.yml, reads as report-only outside autonomous. autonomous still reads it as on. The toggle text in the loop runner, template, orchestrator, standards, and docs states the new default, and the gates-as-loops suite asserts it."
status: "draft"
version: "0.1.0"
---
# Requirement: req-006 - design-critic-default

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000036-pipeline-friction-and-gate-fixes
**Source:** US-006 (backlog 0000122)
**Priority:** should-have

## User Story

> One requirement doc = one user story.

As the human on the loop, I see the design critic review P1 and P2 in every run mode by default, so that a fresh-context check catches drafting gaps before I read the artifacts.

## Functional Requirements

### The problem

- The loop runner's Toggle Protocol (`planifest-framework/skills/planifest-loop-runner/SKILL.md:26-43`) reads an absent key as `off` outside `autonomous`.
- With no `planifest-overrides/loop-toggles.yml`, the design critic never runs in `interactive` or `continuous`. The human on the loop reads P1 and P2 artifacts that no fresh-context checker has seen.
- No script reads the toggle. The default lives only in skill, template, standards, and docs text.

### New default

- Outside `autonomous`, an absent `design_critic` key reads as `report-only`. An absent `loop-toggles.yml` reads the same as an absent key.
- In `autonomous`, an absent `design_critic` key still reads as `on` (0000033 ADR 004).
- An explicit value in `planifest-overrides/loop-toggles.yml` still wins over either default.
- An invalid value on `design_critic` still reads as `off` with a one-line warning. Only the absent case changes.
- Every other key keeps its default. Outside `autonomous`, `reversal_protocol`, `verify_by_execution`, `cross_model_review`, `parallel_streams`, and `p0_completeness` still read as `off` when absent.
- The P0 checker block and the P1 re-check stay as they are. They act only in `autonomous`, where the default stays `on`.
- The P1 Toggle record shows `design_critic: report-only (absent default)` outside `autonomous` when the key is absent.

### Report-only behaviour

- In `report-only`, the orchestrator spawns the critic at the P1 and P2 gates, as the orchestrator skill already describes at `:596`.
- The orchestrator writes the critic's verdict line to the P1 or P2 build-log block, and presents the verdict with the gate summary.
- The verdict blocks nothing and changes no artifact. The human on the loop takes no step to dismiss it.

### Text to change

- `planifest-framework/skills/planifest-loop-runner/SKILL.md` Toggle Protocol: the absent-key bullet at `:27` and the sentence at `:39` state the `report-only` default for `design_critic` outside `autonomous`.
- `planifest-framework/templates/loop-toggles.template.yml`: the header lines `:7`, `:8-9`, and `:17` and the commented `design_critic` line at `:28` state the new default. The line stays commented out, so copying the file sets no explicit value.
- Lines `:8-9` say that zero-config behaviour is identical to a pipeline without loop support. That claim stops being true, because the design critic now runs in `report-only` with no file. The lines state that exception.
- `planifest-framework/skills/planifest-orchestrator/SKILL.md:596`: the design-critic paragraph states the default in each run mode and the build-log record.
- `planifest-framework/standards/autonomous-run-standards.md:110`: the toggle-defaults bullet says the `design_critic` default outside `autonomous` is `report-only`.
- `docs/architecture-overview.md:122`: the loop-layer sentence no longer says that an absent file turns every loop off.
- `docs/decisions-index.md:171`: the 0000016 ADR 003 row ("Loop Toggles in planifest-overrides/loop-toggles.yml") notes the amendment by this feature's ADR. The row also says "absent = all off", and the edit corrects that phrase for `design_critic`.

### Decision record

- A P2 ADR records the new default and amends 0000016 ADR 003 and 0000033 ADR 004. The `docs/decisions-index.md:171` row points to it.
- The ADR states why the default stops at `report-only`. Moving it to `on` waits until the critic's false-positive rate is known.
- The ADR names the cost: one extra critic subagent at each of the P1 and P2 gates outside `autonomous`.

### Suite

- `planifest-framework/tests/test-0000033-req-003-gates-as-loops.sh` and its copy in `tests/regression/` change the assertion at `:77`. The suite asserts that the Toggle Protocol reads an absent `design_critic` key as `report-only` outside `autonomous`.
- The suite also asserts that the template header and the commented `design_critic` line name `report-only`.
- The suite still asserts that the other checker keys read as `off` when absent outside `autonomous`.

## Acceptance Criteria

- [ ] The loop runner Toggle Protocol reads an absent `design_critic` key, or an absent toggles file, as `report-only` outside `autonomous` and as `on` in `autonomous`. Every other key keeps its default.
- [ ] The loop runner Toggle Protocol, `templates/loop-toggles.template.yml`, the orchestrator skill, `standards/autonomous-run-standards.md`, and `docs/architecture-overview.md` each state the new default.
- [ ] `test-0000033-req-003-gates-as-loops.sh` and its regression copy assert the new default and pass.

## Dependencies

- 0000016 ADR 003 defines the toggle levels. 0000033 ADR 004 defines the `autonomous` default. The P2 ADR amends both.
- `planifest-framework/skills/planifest-design-critic/SKILL.md` already runs in `report-only` and `on`. This requirement doesn't change the critic.
- [req-003](req-003-ship-commit-subjects.md), [req-004](req-004-run-mode-anchor-format.md), and [req-005](req-005-hard-limits-cited-by-name.md) edit the orchestrator skill. [req-005](req-005-hard-limits-cited-by-name.md) also edits `standards/autonomous-run-standards.md`. [req-007](req-007-story-split-step.md) edits the loop runner skill. The orchestrator orders those edits.
- No dependency on req-001, req-002, or req-008 to req-011.
