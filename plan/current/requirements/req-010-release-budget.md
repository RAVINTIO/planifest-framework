---
title: "Requirement: req-010 - release-budget"
summary: "A repo sets a release target and ceiling in size points in planifest-overrides/release-budget.yml, and P0 sizes each candidate and recommends a fill from the backlog up to the target."
status: "draft"
version: "0.1.0"
---
# Requirement: req-010 - release-budget

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Source:** US-005
**Priority:** must-have

## User Story

As the human on the loop, I set a release budget for my repo, so that P0 fills each release from the backlog up to that budget instead of a fixed three-story rule.

## Functional Requirements

### New template (`planifest-framework/templates/release-budget.template.yml`)

- Holds two keys, `target` and `ceiling`. Each is a whole number of size points.
- The header comment says these things:
  - Copy this file to `planifest-overrides/release-budget.yml` to set a budget.
  - The framework and its agents never write to `planifest-overrides/`. Setting a budget is a deliberate human act, as with `loop-toggles.yml`.
  - An absent file keeps the three-story rule.
  - An invalid file also keeps the three-story rule, with a one-line warning. A file is invalid if either key is missing or not a positive whole number, or if `target` is greater than `ceiling`.
- `setup.sh` and `setup.ps1` don't change. They don't install templates into `planifest-overrides/` today, and this file follows that pattern.

### New standard (`planifest-framework/standards/release-sizing.md`)

The orchestrator skill is already 9,276 words, so the sizing detail lives here and the skill links to it.

- Defines three size classes. Each class has a point value and a one-line description that P0 applies to a candidate:
  - small (1)
  - medium (2)
  - large (3)
- Defines a **candidate** as a user story in the brief or a backlog entry under `plan/backlog/`.
- Defines the **fill**. P0 sums the points of the candidates already in the brief. It then recommends backlog entries to pull in until the next entry would take the total past `target`.
- Defines the **ceiling**. P0 never recommends a fill above `ceiling`. If the human's choice takes the total past `ceiling`, P0 recommends moving candidates to a later wave. The human decides, and the build log records the decision.
- States that the fill is a recommendation. The human confirms or edits it, per recommend-then-confirm.

### Orchestrator skill (`planifest-framework/skills/planifest-orchestrator/SKILL.md`)

- **`### Decomposition`, "Rule of thumb":** Keep the three-story rule. Add that `planifest-overrides/release-budget.yml` replaces it when the file exists and is valid. Link to `standards/release-sizing.md`.
- **`### Phase 0 Start Actions`, step 3c (Backlog pickup):** Add a budget branch. If a valid budget file exists, P0 sizes every candidate. It presents the recommended fill as one list. The list shows each entry's size class, the total, the target, and the ceiling. The human confirms or edits the list in one answer. Entries outside the fill stay untouched unless the human discards them. If the file is absent or invalid, step 3c behaves exactly as now.
- **`### Phase 0 Start Actions`, step 3c:** Append one line to the P0 build-log block, in one of two forms:
  - `Release budget: {total} of target {target}, ceiling {ceiling}`
  - `Release budget: none, three-story rule`

### Design template (`planifest-framework/templates/design.template.md`)

- **`## Scope`:** Add a `Release size` line. It states each in-scope candidate's size class, the total, and the target and ceiling. If no budget file exists, it states `three-story rule`.

### Feature brief template and guide

- **`planifest-framework/templates/feature-brief.template.md`, `## Features` rule of thumb:** Add that a repo's `planifest-overrides/release-budget.yml` replaces the three-story rule when it exists.
- **`planifest-framework/templates/feature-brief-guide.md`, `### Features` rule of thumb:** Add the same sentence.

### Tests

- Add `planifest-framework/tests/test-0000033-req-010-release-budget.sh`. It makes text assertions on the files above. It also parses `release-budget.template.yml` and checks that `target` and `ceiling` are positive whole numbers with `target` no greater than `ceiling`. `run-tests.sh` picks it up.
- No existing suite asserts the rule-of-thumb text, so no existing suite changes.

### Verified by

- `templates/release-budget.template.yml` exists and has numeric `target` and `ceiling` keys, with `target` no greater than `ceiling`.
- The template's comment names `planifest-overrides/release-budget.yml` and says an absent file keeps the three-story rule.
- `standards/release-sizing.md` contains `small (1)`, `medium (2)`, `large (3)`, `target`, and `ceiling`.
- The orchestrator's `### Decomposition` section still contains "more than 3 user stories". It also names `release-budget.yml` and links to `release-sizing.md`.
- Step 3c names `release-budget.yml`. It contains both build-log forms, `Release budget: {total} of target` and `Release budget: none, three-story rule`.
- The design template's `## Scope` section contains `Release size`.
- `feature-brief.template.md` and `feature-brief-guide.md` both name `release-budget.yml`.

## Acceptance Criteria

- [ ] A repo can set `target` and `ceiling` in `planifest-overrides/release-budget.yml`, copied from `templates/release-budget.template.yml`. The framework never writes that file.
- [ ] If the file exists and is valid, P0 sizes each candidate as small (1), medium (2), or large (3). It recommends a fill from the backlog up to `target`, never above `ceiling`, and the human confirms or edits the fill.
- [ ] If the file is absent or invalid, the three-story rule and step 3c behave as before. The new suite passes under `run-tests.sh`.

## Dependencies

- req-008 (p0-real-forks-only). Scope is a real fork, so the fill stays a question. P0 asks it once, as one list, and it counts as one question.
- 0000016 loop engineering set the `planifest-overrides/` pattern this file follows: a template the human copies, and an absent-file default.
