---
title: "ADR 009: Design critic reads as report-only by default"
summary: "Outside autonomous, an absent design_critic key or an absent loop-toggles.yml reads as report-only, so the critic reviews P1 and P2 in every run mode. autonomous keeps on. An invalid value still reads as off. This amends 0000016 ADR 003 and 0000033 ADR 004 for the design_critic key only."
status: "accepted"
version: "0.1.0"
---
# ADR-009 - Design critic reads as report-only by default

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000036-pipeline-friction-and-gate-fixes
**Component:** planifest-framework
**Date:** 2026-10-22

## Context

This ADR serves [req-006](../requirements/req-006-design-critic-default.md) (US-006, backlog 0000122).

0000016 ADR 003 puts loop toggles in `planifest-overrides/loop-toggles.yml`. An absent file or key reads as `off`. That kept the 0000016 rollout free of regressions.

0000033 ADR 004 amended it for `autonomous` only. In `autonomous`, five checker keys read as `on` when absent, and `design_critic` is one of them. Outside `autonomous`, an absent key still reads as `off`.

So in `interactive` and `continuous`, a product with no toggle file never runs the design critic. The human on the loop reads P1 and P2 artifacts that no fresh-context checker has seen. In this run, the critic rejected the P1 artifacts twice before it approved them, and each rejection led to real fixes.

No script reads the toggle. The default lives only in skill, template, standards, and docs text.

0000016 ADR 006 calls for a report-only trial before any verifier gains blocking power. The critic's false-positive rate outside `autonomous` is still unknown.

## Decision

- **New default outside `autonomous`:** An absent `design_critic` key reads as `report-only`. An absent `loop-toggles.yml` reads the same as an absent key.
- **`autonomous` unchanged:** An absent `design_critic` key still reads as `on`, as 0000033 ADR 004 decided.
- **Explicit values win:** An explicit value in `loop-toggles.yml` wins over either default, including `off`.
- **Invalid values unchanged:** An invalid `design_critic` value still reads as `off` with a one-line warning. Only the absent case changes.
- **Other keys unchanged:** Outside `autonomous`, every other key still reads as `off` when absent. That covers `reversal_protocol`, `verify_by_execution`, `cross_model_review`, `parallel_streams`, and `p0_completeness`.
- **Report-only behaviour:** The orchestrator spawns the critic at the P1 and P2 gates. It writes the verdict line to the phase's build-log block and shows it with the gate summary. The verdict blocks nothing, changes no artifact, and needs no dismissal step.
- **Why not `on`:** Moving the default to `on` outside `autonomous` waits until the P8 reports show the critic's false-positive rate. A blocking default with an unknown false-positive rate would stall human-led runs on wrong rejections.
- **Template:** The commented `design_critic` line in `templates/loop-toggles.template.yml` states the new default. It stays commented out, so copying the template sets no explicit value. The header no longer claims that zero-config behaviour matches a pipeline without loops.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Keep `off` and document how to turn the critic on | No change to 0000016 ADR 003. No added cost. | Most products never create the toggle file, so the critic stays unused outside `autonomous` | It leaves US-006 unmet |
| Default to `on` outside `autonomous` | Matches `autonomous`. Critic findings feed a fix loop. | A REJECT-default checker with an unknown false-positive rate could block good work in every run. It also skips the report-only trial that 0000016 ADR 006 asks for. | The false-positive rate must be known first |
| Turn every checker key to `report-only` outside `autonomous` | One rule for all keys | `verify_by_execution` and `cross_model_review` cost far more per run. Backlog 0000122 asks for the design critic only. | It adds cost and scope that no story asks for |
| Have setup create `loop-toggles.yml` with `design_critic: report-only` | Makes the setting visible in a file | 0000016 ADR 003 rests on setup never writing `planifest-overrides/`. A written file would also look like the human on the loop's explicit choice. | It breaks the ownership rule for the overrides folder |
| Treat an invalid value as `report-only` too | One fallback for all bad input | A typo would turn the critic on silently, and the one-line warning would read as noise | An explicit but broken value should fail safe to `off`, as before |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | `skills/planifest-loop-runner/SKILL.md` Toggle Protocol states the new absent-key rule for `design_critic`. `templates/loop-toggles.template.yml`, `skills/planifest-orchestrator/SKILL.md`, and `standards/autonomous-run-standards.md` state the default in each run mode. `tests/test-0000033-req-003-gates-as-loops.sh` and its regression copy assert it. |
| docs | `docs/architecture-overview.md` drops the claim that an absent file turns every loop off. `docs/decisions-index.md` marks the 0000016 ADR 003 row as amended by this ADR. |

## Consequences

**Positive:**
- A fresh-context critic reviews P1 and P2 in every run mode by default. The human on the loop sees its verdict before reading the artifacts.
- The report-only runs build the false-positive data needed before a later change to `on`.
- Products that set an explicit value see no change.

**Negative:**
- Each `interactive` or `continuous` run spawns one more critic subagent at each of the P1 and P2 gates. That costs tokens and wall time, and a product can't avoid it without creating the toggle file.
- Zero config no longer means "no loops". A product that relied on that claim now runs a critic it never asked for.
- The absent-key rule now differs by key as well as by run mode. That adds one more branch to the Toggle Protocol that every reader must apply by hand.

**Risks:**
- Report-only findings become noise that the human on the loop learns to skip. The P8 report should show how often the human on the loop acted on a verdict.
- An agent applies the new default to every key, not only `design_critic`. The suite asserts that the other keys still read as `off` when absent.

## Related ADRs

- 0000016 ADR 003 (loop toggles) - amended by this ADR. An absent `design_critic` key, or an absent file, reads as `report-only` outside `autonomous`. The ADR stays in force for every other key.
- 0000033 ADR 004 (gates as loops) - amended by this ADR. Its rule that absent keys read as `off` outside `autonomous` no longer holds for `design_critic`. Its `autonomous` default of `on` is unchanged.
- 0000016 ADR 006 (fresh-context verifiers) - depends-on. Report-only is the trial level it asks for.
- ADR-008 - related-to. The anchor decides whether a run is `autonomous`, and so which default applies.

## Supersedes

- None. This ADR amends 0000016 ADR 003 and 0000033 ADR 004 for `design_critic` outside `autonomous`. Both stay in force otherwise, and their archived files stay unchanged.

## Superseded By

- None
