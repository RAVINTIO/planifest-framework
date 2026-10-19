---
title: "ADR 008: Release budget in size points"
summary: "A product sets a target and a ceiling in size points in planifest-overrides/release-budget.yml. P0 sizes each candidate as small, medium, or large and recommends a fill from the backlog up to the target. A fill over the ceiling gets a split recommendation. An absent or invalid file keeps the three-story rule."
status: "accepted"
version: "0.1.0"
---
# ADR-008 - Release budget in size points

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Component:** planifest-framework
**Date:** 2026-10-19

## Context

The orchestrator's `### Decomposition` section says a feature with more than 3 user stories is too big. Step 3c then offers backlog entries one by one, with no sense of size.

The rule fits a new product. It doesn't fit a repo that runs many small stories at once. This run holds 10 stories, against that rule. Backlog 0000103 asks for a release size that each repo sets for itself.

Three stories also says nothing about size. One large story can outweigh three small ones.

0000016-ADR-003 set the pattern for product settings. The framework ships a template, the human on the loop copies it into `planifest-overrides/`, and an absent file keeps the default. 0000005-ADR-002 keeps that folder outside the framework.

At P1, D-006 asked where the size classes live and what happens over the ceiling.

## Decision

- **Budget file:** A product may create `planifest-overrides/release-budget.yml` from `templates/release-budget.template.yml`. It holds two whole numbers, `target` and `ceiling`, in size points. The framework never writes the file, and setup doesn't install it (ADR-015).
- **Size classes (D-006):** `standards/release-sizing.md` defines three classes, each with a one-line test:
  - small (1)
  - medium (2)
  - large (3)
- **Fill:** P0 sizes each candidate in the brief and in `plan/backlog/`. It sums the brief's candidates, then recommends backlog entries until the next would pass `target`. P0 presents the fill as one list with each size class, the total, the target, and the ceiling. The human confirms or edits it in one answer.
- **Ceiling (D-006):** P0 never recommends a fill above `ceiling`. If the human's choice passes it, P0 recommends moving candidates to a later wave. The human decides, and the build log records the decision. It is a split recommendation, not a hard block.
- **Absent or invalid file:** The three-story rule and step 3c behave as before. An invalid file also prints a one-line warning. A file is invalid if a key is missing or not a positive whole number, or if `target` exceeds `ceiling`.
- **Records:** Step 3c writes one build-log line, either `Release budget: {total} of target {target}, ceiling {ceiling}` or `Release budget: none, three-story rule`. The design's `## Scope` gains a `Release size` line.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Keep the three-story rule for every repo (status quo) | No new file | Repos with many small stories split work that fits one release, or ignore the rule | Backlog 0000103 names this as the defect |
| Make the story count configurable | One number to set | A count still ignores story size | Size points measure what the rule is trying to limit |
| Estimate in hours or days | Familiar to many teams | Agent estimates of time are unreliable, and P0 can't check them | Three coarse classes are enough for a fill |
| Block any fill over the ceiling | Firm limit | Stops a run when the human on the loop has a reason to go over | D-006 keeps the human's choice, with a split recommendation |
| Put the budget in `product.yml` | One product config file | `product.yml` holds versioning, and the framework edits it | Overrides are the folder the framework only reads |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | A new template, `templates/release-budget.template.yml`, and a new standard, `standards/release-sizing.md`. The orchestrator's `### Decomposition` section and step 3c gain a budget branch and a build-log line. The design, feature brief, and brief guide templates name the budget. A new suite covers req-010. |

## Consequences

**Positive:**
- Each repo sizes its releases to fit how it works, with no framework edit.
- The fill rests on size, so one large story counts as more than one small one.
- P0 presents the fill as one list, so backlog pickup costs one question.
- Repos with no budget file see no change.

**Negative:**
- P0 must size every candidate, which adds work at the start of each run.
- Three classes are coarse. Two medium stories can differ a lot in effort.
- The orchestrator now holds two rules of thumb, and readers must know which one applies.

**Risks:**
- The agent may size candidates too low and fill a release past what one run can finish. The build log records each size class, so the P8 report can show the drift.
- A typo in the budget file falls back to the three-story rule. The one-line warning is the only signal, and a human on the loop who skims P0 may miss it.

## Related ADRs

- ADR-007 - related-to. The fill stays a real fork and counts as one question.
- ADR-015 - depends-on. The product's human on the loop owns the budget file.
- 0000016-ADR-003 (loop toggles in `planifest-overrides/`) - related-to. The budget file follows its template and absent-file pattern.
- 0000005-ADR-002 (`planifest-overrides/` sibling directory) - depends-on

## Supersedes

- None. The three-story rule stays as the default when no valid budget file exists.

## Superseded By

- None
