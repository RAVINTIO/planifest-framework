---
title: "Scope - pipeline friction and gate fixes"
summary: "Defines what 0000036 delivers, what it leaves out, and that nothing is deferred."
status: "active"
version: "0.1.0"
---
# Scope - pipeline friction and gate fixes

**Skill:** [spec-agent](../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000036-pipeline-friction-and-gate-fixes
**Version:** 0.34.0

> Release size follows the three-story rule, with no `release-budget.yml`. This run carries eleven stories in one wave, by the choice of the human on the loop.

## In Scope

- Backlog entries 0000122, 0000127, 0000139, 0000143, 0000149, 0000154, 0000155, 0000157, 0000158, 0000159, and 0000160.
- One re-run-setup migration, `migrate-0.34.0-rerun-setup.md` (US-001):
  - It covers the setup-delivered changes in both 0.33.0 and 0.34.0.
  - It follows the sections of the 0.31.0 migration.
  - `standards/framework-update-policy.md` states that a release that changes a setup-delivered file ships such a migration.
  - This repo records it as `applied` after P3 re-runs setup here.
- A skill drift check, `scripts/skill-drift-check.mjs` (US-002):
  - It compares `SKILL.md` bytes only, source against the installed copy.
  - It warns and never blocks. It exits 0 on a match, 1 on drift or a missing copy, and 2 when it can't compare.
  - A project with no installed copies reports "not installed" with exit 1 and a setup recommendation.
  - If the active tool is unknown, it covers every installed tool folder it finds.
  - Orchestrator resume detection runs it at session start and again after any setup run in the same session.
  - On drift, the orchestrator loads the source copy and recommends `planifest-refresh-setup`. It never re-runs setup itself.
- Ship commit subjects (US-003): no framework skill subject template holds a placeholder. Subjects name the phase and action only, as in `plan(p9): clear session markers`. The feature ID goes in the body. A suite fails on a placeholder or a subject over 72 characters.
- Run-mode anchor format (US-004):
  - `run-mode.mjs` accepts the bare line or one leading `- `.
  - The one-commit rule, the design Confirmation check, and the `interactive` fallback for a forged, uncommitted, or missing anchor stay unchanged.
  - The orchestrator skill and the build-log template show the bare line in a code block as the preferred form.
- Hard-limit citations (US-005): every citation names its rule and source, for example "the build-log rule (orchestrator Hard Limit 8)". `standards/agent-dispatch-standards.md` states the Write-or-Edit rule in its dispatch template. A suite fails on a bare citation.
- Design critic default (US-006):
  - An absent `design_critic` key reads as `report-only` outside `autonomous`. `autonomous` stays `on`.
  - A missing `loop-toggles.yml` reads the same as a missing key.
  - Critic verdicts go to the build log, with no dismissal step.
  - The loop runner Toggle Protocol, the toggles template, and the orchestrator skill state the default. An ADR records the change.
  - `test-0000033-req-003-gates-as-loops.sh` and its regression copy assert it.
- Split step (US-007): the spec agent, the design critic rubric, and the loop runner fix dispatch each carry a step. It fires when a requirement would reach a fourth criterion and asks whether it holds two concerns. A suite checks all three skills.
- Non-regular `design.md` (US-008):
  - `lstat` runs before any read. A folder, FIFO, or other non-regular file counts as no design, and a `src/` write blocks with exit 2.
  - The hook never opens a non-regular `design.md`.
  - If `lstat` throws, for example with `EACCES`, or a regular file can't be read, the hook fails open.
  - An ADR narrows 0000003 ADR-005 for the non-regular case only.
- Permitted names in enforcement paths (US-009): the always-permitted shortcut skips paths inside the enforcement list. Those paths take the normal route through the design scope or the Fast Path scope verdict. A suite covers both cases with and without `design.md`.
- Test runner (US-010): `run-tests.sh` clears `CLAUDE_PROJECT_DIR` before any suite. The four gate-related suites that lack it clear the variable for a standalone run. A suite checks both.
- Escaped hook output (US-011): `ratchet-check.mjs` and `em-dash-guard.mjs` print quoted text through `shown()`. `shown()` never cuts an escape sequence in half at its length cap. Suite cases cover a control character, U+202E, and an over-long value.
- Tests for each story under `planifest-framework/tests/`, run through `run-tests.sh`.
- Version `0.33.0` to `0.34.0` in `planifest-framework/component.yml`. `product.yml` is set to match at P7.
- Setup integration docs under `src/setup-hook-integration/`, only if setup behaviour changes.

## Out of Scope

- Shell-guard parser entries 0000105, 0000108, 0000115, and 0000116. They wait on 0000118 and 0000119.
- The remaining 0000035 hardening entries: 0000140 to 0000142, 0000144 to 0000148, and 0000150 to 0000152.
- Renumbering the orchestrator or boot hard limits.
- Changing what setup copies or where it copies it.
- Moving the design critic default to `on` outside `autonomous`. That waits until the false-positive rate is known.
- Having the drift check compare anything but `SKILL.md` bytes, or re-run setup itself.
- Any change to the three-story rule or to run modes.

## Deferred

Nothing deferred. No item is blocked on a later decision, and no story waits on another feature.
