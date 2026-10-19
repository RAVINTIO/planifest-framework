---
title: "Release Sizing"
version: "1.0.0"
---
# Release Sizing

P0 sizes each release in size points against a budget the human on the loop sets. The budget lives in `planifest-overrides/release-budget.yml`, copied from `templates/release-budget.template.yml`. The orchestrator's `### Decomposition` section and step 3c link here (0000033-ADR-008).

If the file is absent or invalid, none of this applies. The three-story rule and step 3c behave as before. An invalid file also prints a one-line warning.

---

## Size classes

P0 gives each candidate one class:

| Class | Points | Applies when |
|-------|--------|--------------|
| small (1) | 1 | One requirement that touches one file or section, with no new artifact type. |
| medium (2) | 2 | A few requirements, or one that adds a new file, script, or template. |
| large (3) | 3 | A change across several components or skills, or one that needs new ADRs. |

If a candidate fits two classes, P0 picks the larger one.

## Candidates

A **candidate** is either of these:

- a user story in the feature brief
- a backlog entry under `plan/backlog/`

## The fill

1. P0 sums the points of the candidates already in the brief.
2. P0 sorts the backlog entries by priority, then by age.
3. P0 recommends entries to pull in until the next entry would take the total past `target`.
4. P0 presents the fill as one list. The list shows each entry's size class, the total, the `target`, and the `ceiling`.
5. The human confirms or edits the list in one answer, per recommend-then-confirm.

The fill is a recommendation. Entries outside the fill stay untouched unless the human discards them.

## The ceiling

P0 never recommends a fill above `ceiling`. If the human's choice takes the total past `ceiling`, P0 recommends moving candidates to a later wave. The human decides, and the build log records the decision. It is a split recommendation, not a hard block.

## Records

Step 3c appends one line to the P0 build-log block:

- `Release budget: {total} of target {target}, ceiling {ceiling}`
- `Release budget: none, three-story rule`

The design's `## Scope` section gets a `Release size` line with each candidate's class and the total.
