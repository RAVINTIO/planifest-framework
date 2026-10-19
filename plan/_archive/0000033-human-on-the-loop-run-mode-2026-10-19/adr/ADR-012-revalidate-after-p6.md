---
title: "ADR 012: Revalidate after P6"
summary: "After its last P6 edit, the docs agent reruns the P4 check set, or a smaller doc-check command that the product declares in planifest-overrides/doc-checks.yml. A failure enters a loop capped at 5 that fixes the doc edit, never the check."
status: "accepted"
version: "0.1.0"
---
# ADR-012 - Revalidate after P6

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Component:** planifest-framework
**Date:** 2026-10-19

## Context

P4 runs lint, typecheck, tests, and build, and confirms they pass. P6 then edits documentation, often in tracked files that P4 suites read. Text-level suites in this framework assert skill and docs wording. A P6 edit can therefore break a check that already passed, and nothing reruns it before P7 archives the run.

Backlog 0000075 records this gap. In an `autonomous` run (ADR-002), no human looks at the tree between P6 and the PR. The PR's CI run would be the first place the break shows.

Some products have a slow full suite and a fast doc-only check. A full P4 rerun for a one-line doc edit costs them time. req-014 holds the detail.

## Decision

- **New section:** The docs agent skill gains `## Post-P6 revalidation`, after `## What You Produce` and before `## Rules`. The docs agent runs it after its last doc edit and before it reports P6 complete.
- **Check selection:**
  1. If `planifest-overrides/doc-checks.yml` exists and declares a valid `command`, the agent runs that command.
  2. Otherwise, the agent reruns the P4 check set. That set is steps 0 to 5 of the validate-agent `## Process` section. Step 6, verify by execution, doesn't rerun.
- **Override file:** A new template, `templates/doc-checks.template.yml`, documents one key, `command`. The value is a single shell command line of at most 500 characters. The framework never creates `planifest-overrides/doc-checks.yml`. The product's human on the loop owns it (ADR-015). If the key is missing or invalid, the agent runs the full P4 set and logs why.
- **Pass:** The agent records the command or check set and the result in the P6 build-log block.
- **Failure:** The agent fixes the P6 edit that caused the failure, then reruns the failing check. The loop runs under `planifest-loop-runner` with the P4 cap of 5 cycles. The agent fixes the doc, never the check. At the cap, it escalates in the validate-agent `VALIDATION BLOCKED` format. In `autonomous`, the change-of-approach rule (ADR-005) applies at the cap.
- **Failure not caused by P6:** The agent records it and escalates in the same format. The docs agent doesn't change code under `src/` outside `docs/`.
- **Skip:** If Gate B decided no docs update was needed and P6 made no edit, the agent logs `Post-P6 revalidation: skipped, no P6 edits`.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Rerun the full P4 set always, with no override | One rule, nothing to configure | Slow for products with a long suite and doc-only edits | A product can't trade speed for scope where it knows its doc checks |
| Run P4 again as a full phase after P6 | Reuses the validate agent as it stands | Adds a phase and reruns verify by execution, which P6 edits can't affect | Costs more than the risk needs |
| Rely on the PR's CI run | No framework change | The break shows after the PR exists, and P7 has already archived the run | An `autonomous` run would raise a red PR with no fix loop |
| Move P6 before P4 | P4 then covers doc edits | P6 documents what P4 confirmed, and P5 security fixes come after P4 | Breaks the phase order that later phases depend on |
| Let the docs agent edit a failing check | Fastest way back to green | Weakens the check to fit the doc | A check weakened to pass no longer protects what P4 confirmed |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | The docs agent skill gains `## Post-P6 revalidation`. A new template, `doc-checks.template.yml`, documents the override. A new suite covers req-014. |

## Consequences

**Positive:**
- A doc edit can't break a passing check without the run catching it before P7.
- An `autonomous` run raises a PR whose checks passed after the last edit.
- Products with a slow suite can declare a faster doc-only check.

**Negative:**
- P6 takes longer, by up to one full P4 run.
- A product's doc-check command can cover less than P4. A break outside its scope then reaches the PR's CI run.

**Risks:**
- A `doc-checks.yml` command could run anything, since it is a shell line from the repo. The human on the loop owns the file, and the framework never writes it, so the trust level matches the repo's own scripts.
- A flaky test could fail the rerun with no P6 cause. The agent records it and escalates, which may stop an `autonomous` run on noise.

## Related ADRs

- 0000016-ADR-007 (deterministic caps) - depends-on. The loop uses the existing P4 cap of 5.
- ADR-005 - depends-on. It governs the cap in `autonomous`.
- ADR-015 - related-to. It assigns ownership of `planifest-overrides/doc-checks.yml`.

## Supersedes

- None

## Superseded By

- None
