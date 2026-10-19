---
title: "ADR 003: Declared exception list"
summary: "In autonomous mode only six declared items wait for the human on the loop. Every other question becomes a recorded decision. A gross deviation is a change the fresh-context reversal assessor classes as altering. A product can add items in planifest-overrides/exception-list.yml but can't remove any."
status: "accepted"
version: "0.1.0"
---
# ADR-003 - Declared exception list

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Component:** planifest-framework
**Date:** 2026-10-19

## Context

`autonomous` (ADR-002) must still stop for some things. The design names them, and req-002 turns them into a list. The human on the loop needs to know in advance which items can reach them. NFR-001 counts any other touchpoint as a defect.

Today the stop points sit in many places:

- the one-question rule in each phase skill (0000014-ADR-008)
- recommend-then-confirm
- the four "always stop" cases in reversal step 4
- codegen's Stop-and-Ask option

0000016-ADR-005 stops every cascade over 3 artifacts, whatever the run mode.

A gross deviation needs a definition that an agent can't stretch. The deviating agent has a motive to call its own change minor. Execution-plan D-013 settles who classifies it, and D-002 settles the cascade case.

Products also have their own human-only items. `planifest-overrides/` is the directory the product's human on the loop owns (0000005-ADR-002).

## Decision

- **The list:** In `autonomous`, only these six items wait for the human on the loop:
  1. A schema change or a destructive operation (Hard Limits 2 and 3).
  2. A gross deviation.
  3. Human review of the running result.
  4. Promotion beyond the candidate environment.
  5. A human-only input, such as a captcha.
  6. An exhausted budget, such as the reversal budget or the approach budget (ADR-005).
- **Handling an item:** The agent writes what the item needs, such as a migration proposal or a defect report. It finishes all work that doesn't depend on the item. It records an `Exception waiting` build-log line and lists the item in the final report. It never asks about the item mid-run.
- **Everything else is a decision:** A question that isn't on the list becomes a decision. The agent takes the option it would have recommended. It records a `Decision` line in the build log and in the artifact the decision touches. In `autonomous`, the one-question rule and recommend-then-confirm give way to this rule.
- **Gross deviation (D-013):** A gross deviation is a change the reversal protocol would class as *altering*. It changes the confirmed problem, the users, or the in-scope list. The fresh-context `planifest-reversal-assessor` classifies it. The deviating agent never classifies its own deviation. If that agent suspects a gross deviation, it files a defect report and the assessor decides. Every other deviation gets an *additive* `Deviation` line.
- **Assessor availability:** In `autonomous`, an absent `reversal_protocol` key reads as `on` (ADR-004). The assessor is therefore present in every `autonomous` run.
- **Reversal step 4 (D-002):** In `autonomous`, step 4 cases (a) altering, (b) a re-exit from P0, and (c) budget exhaustion become exception-list items. Case (d), an additive cascade over 3 artifacts, proceeds. The build log and the final report record it. The four cases keep their "always stop" text in `interactive` and `continuous`.
- **Codegen:** In `autonomous`, codegen's Stop-and-Ask option becomes a defect report to the assessor. An *altering* verdict makes it an exception-list item. Any other verdict sends codegen down option 1 with an *additive* deviation.
- **Product extension:** A product adds items in `planifest-overrides/exception-list.yml` under an `additional:` key. The file can only add items. An absent file means the six items alone. The framework ships `templates/exception-list.template.yml` and never writes the override file.
- **Standing rules in every mode:** Merging a PR stays human-only. Hard Limits 2 and 3 stay human-gated. No override can remove an item.
- **Rule text:** The list, the line formats, and these rules live in `standards/autonomous-run-standards.md` under `## Exception list` (ADR-001).

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Let each phase skill decide what to ask | No central list | The human on the loop can't predict when a run needs them. NFR-001 can't be measured. | Breaks US-002 |
| Let the deviating agent classify its own deviation | No extra subagent | The maker under-finds its own errors (0000016-ADR-006). An agent can call any change additive. | D-013 names the assessor |
| Define a gross deviation by size, such as a count of changed files | Deterministic | A one-line change can alter scope, and a large change can keep the intent | The *altering* class already captures intent |
| Keep every cascade over 3 artifacts as a stop in `autonomous` | No change to 0000016-ADR-005 | A correct additive fix stops the run, so `autonomous` stalls on routine corrections | D-002 keeps the stop only for *altering* changes |
| Let `exception-list.yml` remove items as well as add them | Full product control | A product could drop schema changes or merges from human review | NFR-004 forbids it |
| Ask exception items mid-run as they arise | The human on the loop sees them sooner | Each one becomes a wait, and the run can't finish the independent work | US-002 asks for one final report |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | `autonomous-run-standards.md` gains `## Exception list`. A new `exception-list.template.yml` ships. The orchestrator's reversal step 4 and Phase Conventions change. The reversal assessor's rubric row 5 and codegen's deviation protocol change. Seven phase skills gain one deferral sentence. |

## Consequences

**Positive:**
- The human on the loop knows in advance every item that can reach them.
- The P8 touchpoint audit can flag any wait outside the list as a finding.
- An independent subagent decides whether a change is gross, not the agent that made it.
- Products extend the list without forking framework text.

**Negative:**
- In `autonomous`, the agent takes decisions a human would have made. A poor decision surfaces only in the final report or at PR review.
- Every `autonomous` deviation that might be gross costs an assessor spawn.
- An additive cascade over 3 artifacts now proceeds without a human in `autonomous`. That is a narrower reading of 0000016-ADR-005 in this mode.

**Risks:**
- The assessor classes an *altering* change as *additive*, and the run ships a scope change. The final report lists every deviation, and the human on the loop reviews before merging.
- A future skill edit adds a stop that isn't on the list. The text-level tests assert the six items, and the P8 audit flags the stop.
- A product's `exception-list.yml` holds vague items that an agent can't match. The template says items are free text, so unclear items need a human edit.

## Related ADRs

- 0000016-ADR-005 (cascade threshold of 3 artifacts) - amended by this ADR in `autonomous` only
- 0000014-ADR-008 (one-question rule) - related-to. The rule gives way to recorded decisions in `autonomous`.
- 0000016-ADR-006 (fresh-context verifiers) - depends-on. The assessor follows its contract.
- 0000005-ADR-002 (planifest-overrides sibling directory) - depends-on
- ADR-002 - depends-on. It defines `autonomous`.
- ADR-004 - depends-on. It turns `reversal_protocol` on in `autonomous`.
- ADR-005 - related-to. It defines the approach budget that item 6 names.
- ADR-006 - related-to. The final report lists each waiting item.
- ADR-015 - related-to. It records ownership of `exception-list.yml`.

## Supersedes

- Amends 0000016-ADR-005 in `autonomous` only. An additive cascade over 3 artifacts proceeds with a build-log record. An *altering* reversal still waits as a gross deviation. The ADR stays in force for `interactive` and `continuous`.

## Superseded By

- None
