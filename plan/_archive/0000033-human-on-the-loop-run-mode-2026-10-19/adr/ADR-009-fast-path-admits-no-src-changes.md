---
title: "ADR 009: Fast Path admits no-src changes"
summary: "Fast Path's prerequisite relaxes to admit a change with no src/ target, such as documentation, governance, or framework text. Its four criteria stay word for word. This was chosen over a new documentation track and over stating the status quo."
status: "accepted"
version: "0.1.0"
---
# ADR-009 - Fast Path admits no-src changes

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Component:** planifest-framework
**Date:** 2026-10-19

## Context

The framework has three tracks. Fast Path requires "an existing feature with code at `src/{component-id}/`". The Change Pipeline requires one or two existing components. A change with no `src/` target meets neither, so it falls to the Feature Pipeline.

Backlog 0000062 reports this from `rapid-prototypes`. Two runs there changed only markdown. Both ran the Feature Pipeline and skipped P2, P4, and P5 by hand. Each skip needed its own human decision and its own `.skips` note.

The same gap applies here. A change to a skill, a template, or a standard has no `src/` target. It often meets all four Fast Path criteria, and only the prerequisite excludes it.

The backlog entry offers three options:

- Relax the Fast Path prerequisite.
- Add a documentation track.
- State the status quo as policy, with a set of pre-approved skips.

## Decision

- **Prerequisite:** `workflows/fast-path.md` accepts either of two things:
  - an existing feature with code at `src/{component-id}/`
  - a change with no `src/` target, such as documentation, governance, tooling, or framework text
- **Criteria:** The four Fast Path criteria stay word for word. A no-`src/` change must meet all four. A change that fails one goes to the Change Pipeline or the Feature Pipeline by the existing rows.
- **Manifest step:** Step 4 updates the `component.yml` that covers the changed paths, such as `planifest-framework/component.yml`. If no manifest covers them, step 4 is skipped. Step 5 names the covering component, or the changed paths if none covers them.
- **Routing:** The orchestrator's `### Three-Track Decision Tree` gains a row for a no-`src/` change, routed to Fast Path when all criteria pass. `### Fast Path Criteria and Execution` says the same in one sentence.
- **Unchanged:** `hooks/pre-push` and `.github/workflows/planifest.yml` don't change. Their Fast Path check runs only when `src/` changed.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Add a documentation track with its own phase set | A track shaped for governance work | A fourth track to route, document, test, and keep in step with the other three | Fast Path's four criteria already fit this class, so a new track repeats them |
| State the status quo: Feature Pipeline with a pre-approved skip set | No routing change | Small changes still run a heavy track, and the skip set needs its own upkeep | It records the dead end as policy instead of removing it |
| Relax Fast Path's prerequisite (chosen) | Smallest change, and the criteria already describe the class | Fast Path now covers work with no component manifest | Fits the gap with one prerequisite line and one track row |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | `workflows/fast-path.md` changes its prerequisite and steps 4 and 5. The orchestrator gains one track-table row and one sentence. A new suite covers req-011. |

## Consequences

**Positive:**
- A small documentation or governance change takes the lightweight track, with no hand-made skips.
- Downstream products such as `rapid-prototypes` can retire their routing overrides.
- Framework changes in this repo can use Fast Path when they meet the criteria.

**Negative:**
- A Fast Path change with no covering manifest leaves no `component.yml` record. Only the step 5 log entry records it.
- Fast Path has no ADR step, so a governance change that carries a real decision could ship without one.

**Risks:**
- An agent could class a governance change that alters routing or a gate as "copy". Criterion 3 still excludes routing logic, and the orchestrator must apply it to framework text as strictly as to code.
- Because the pre-push check runs only when `src/` changed, nothing checks a no-`src/` Fast Path change after the orchestrator's own criteria check.

## Related ADRs

- 0000014-ADR-004 (version bump rules by track) - related-to. A no-`src/` Fast Path change takes a patch bump, as any Fast Path change does.
- ADR-007 - related-to. Fast Path skips P0, so the P0 question policy doesn't apply to it.

## Supersedes

- None

## Superseded By

- None
