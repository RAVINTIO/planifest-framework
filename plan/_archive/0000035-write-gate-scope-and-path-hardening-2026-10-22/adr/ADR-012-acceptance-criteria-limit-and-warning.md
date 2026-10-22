---
title: "ADR 012: Acceptance-criteria limit and warning"
summary: "consistency-check.mjs allows up to 10 acceptance criteria per requirement. From 4 to 10 it prints a warning and exits 0. Above 10 it reports a finding. The feature brief template still asks for 3 and prefers a story split above 3. The human on the loop directed the change on 2026-10-22."
status: "accepted"
version: "0.1.0"
---
# ADR-012 - Acceptance-criteria limit and warning

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000035-write-gate-scope-and-path-hardening
**Component:** planifest-framework
**Date:** 2026-10-22

## Context

`consistency-check.mjs` failed any requirement with more than 3 acceptance criteria. Every later feature meets this gate at P1 and P2.

In this run, an approach 2 fix gave req-002 six criteria. To pass the check, the run first folded criteria into sub-bullets under three checkbox lines. It didn't split the story, which the feature brief template asks for. The hard limit of 3 rewarded the fold and hid the work from the counter.

Folding back to three criteria also needed a `.ratchet-approve` line from the human on the loop. The build log records the exchange at P1. The human on the loop answered: "Change to allow 10 acceptance criteria but favour 3." At P2 the human on the loop added: "There should still be a warning above 3 and less than 10 though for feedback. Just not a hard block."

No user story in the brief covers this change. The build log records it as a P1 deviation that the human on the loop directed. This ADR records the decision.

## Decision

- **Limit:** `consistency-check.mjs` allows up to 10 checkbox criteria in a requirement's `## Acceptance Criteria` section.
- **Warning band:** From 4 to 10 criteria, the check prints one `⚠` line per requirement. The line says to aim for 3 and to consider a story split. The check still exits 0.
- **Finding:** Above 10 criteria, the check reports a finding and exits non-zero.
- **Template:** `feature-brief.template.md` asks for 3 criteria per story. It prefers a split into two stories above 3. It states the warning and the limit of 10.
- **Tests:** `test-0000016-pipeline-governance.sh` and its regression copy test 10 criteria as a pass with a warning. They test 11 criteria as a finding.
- **Commits:** `c7e7642` raised the limit. `bb2d692` added the warning band.
- **Split step:** Backlog 0000139 covers the missing split step in the skills. This ADR doesn't add one.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Keep the hard limit of 3 | Small requirements, no change to the check | Drives folds into sub-bullets that the counter can't see. A fold back needs a human `.ratchet-approve` line. | The human on the loop chose a higher limit |
| Keep 3 and require a story split (backlog 0000139) | Keeps each story small | No skill holds a split step yet. Splits mid-run cost a critic loop each. | Left to backlog 0000139 |
| Raise the limit to 10 with no warning | Fewest prompts | Gives no feedback when a requirement grows past 3 | The human on the loop asked for a warning at P2 |
| No limit | Never blocks | A requirement can grow without bound | Loses the gate for every later feature |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | `scripts/consistency-check.mjs` changes its limit and gains a warning band. `templates/feature-brief.template.md` states both limits. Both copies of `test-0000016-pipeline-governance.sh` gain the 10 and 11 cases. |

## Consequences

**Positive:**
- A requirement can hold 4 to 10 real criteria without a fold, so each criterion stays visible as its own checkbox line.
- The warning still prompts a split, so 3 stays the target.

**Negative:**
- The counter still can't see sub-bullets under a checkbox line. A fold of 12 criteria into 3 lines still passes.
- Requirements can grow larger before any gate stops them, which makes each one harder to test and review.
- The limit doesn't undo folds already made. req-002 criterion 1 still holds eight close-out suite cases as sub-bullets. They test one script, so this run keeps them as one criterion.

**Risks:**
- Agents may treat the warning as noise and stop splitting stories. Backlog 0000139 tracks the missing split step.

## Related ADRs

- ADR-010 - related-to (the req-002 criteria count that raised the question)

## Supersedes

- None

## Superseded By

- None
