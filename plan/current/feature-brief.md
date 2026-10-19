---
title: "Feature Brief - human-on-the-loop run mode"
summary: "An autonomous run mode with the human on the loop, a P0 that asks only real forks, configurable release sizing, parallel streams, and a close-out that needs nobody."
status: "approved"
version: "0.1.0"
---
# Feature Brief - human-on-the-loop run mode

**Feature ID:** 0000033-human-on-the-loop-run-mode

> The orchestrator drafted this brief from 11 backlog entries the human picked at P0. The human confirms it with the design.

## Business Goal

Downstream products already run P1 to P9 with no human interaction, but only through overrides that fight the framework text at about ten points. A fresh session can resolve each conflict the wrong way. This feature makes the framework own that mode. The human sets intent at P0, reviews the result after P9, and no gate waits in between unless it's on a declared exception list.

P0 also asks too many questions. On `ovelunor` 0000013 it asked about twelve one-at-a-time confirmations. This feature cuts P0 to the questions that need the human's judgement.

## Source backlog entries

| Entry | Story |
|-------|-------|
| 0000078 upgrade continuous run to human-on-the-loop | US-001, US-002, US-003 |
| 0000076 P0 asks too many coaching questions | US-004 |
| 0000101 sample the existing records a design depends on at P0 | US-004 |
| 0000103 release sizing and a configurable release budget | US-005 |
| 0000104 subagent acceleration | US-006 |
| 0000082 a batching boundary leaves work no agent owns | US-006 |
| 0000075 P7 archive step relies on a glob delete | US-007 |
| 0000073 ship-agent can close a run with untracked artifacts | US-007 |
| 0000086 revalidate after P6 docs edits | US-008 |
| 0000059 clarify agent-vs-human pronouns in choice prompts | US-009 |
| 0000062 no lightweight track for projects without `src/` components | US-010 |

## Features

| Feature | User Stories | Priority | Stream |
|---------|-------------|----------|--------|
| Autonomous run mode | US-001: As the human on the loop, I choose `autonomous` at P0, so that the run goes from confirmed design to a raised PR with no gate waiting for me. | must-have | 1 run modes and gates |
| Declared exceptions and one report | US-002: As the human on the loop, I get asked only for items on a declared exception list, and only in one final report, so that I know exactly when a run needs me. | must-have | 1 run modes and gates |
| Gates become loops | US-003: As the human on the loop, I see a failed gate retried by a fresh-context checker with a changed approach, so that a cap or a no-progress halt doesn't stop an autonomous run. | must-have | 1 run modes and gates |
| P0 asks only real forks | US-004: As the human on the loop, I answer P0 questions only where the answer needs my judgement or changes what gets built, so that derivable items reach me once, in the design draft. | must-have | 2 P0 rework |
| Release budget | US-005: As the human on the loop, I set a release budget for my repo, so that P0 fills each release from the backlog up to that budget instead of a fixed three-story rule. | must-have | 2 P0 rework |
| Parallel streams | US-006: As the human on the loop, I see independent requirements move through the phases as parallel subagent streams with one owner for every join, so that a run with many small requirements finishes faster and leaves no seam unowned. | must-have | 4 parallel dispatch |
| Close-out with no human | US-007: As the human on the loop, I get a P7 to P9 close-out that needs no glob delete and ends with a clean working tree, so that an autonomous run can finish without me. | must-have | 3 close-out |
| Revalidate after P6 | US-008: As the human on the loop, I see the P4 checks run again after P6 edits, so that a doc edit can't break a check that already passed. | should-have | 3 close-out |
| Choice prompts name the actor | US-009: As the human on the loop, I read choice prompts that name who acts in each option, so that I never have to track a shifting "I". | should-have | 1 run modes and gates |
| Lightweight track | US-010: As the human on the loop, I route a change with no `src/` component through a lightweight track, so that governance and documentation changes stop running the full Feature Pipeline. | should-have | 2 P0 rework |

## Waves

One wave. The human chose all 11 entries in one run. The four streams in the table above group the requirements for parallel dispatch.

## Target Architecture

### Components

| Component | Type | New or Existing | Responsibility |
|-----------|------|-----------------|---------------|
| `planifest-framework` | component-pack | existing | Skills, standards, templates, hooks, and scripts. Every change in this feature lands here. |

### Data Ownership

| Data Store | Owner Component | Shared With |
|------------|----------------|-------------|
| `plan/.run-mode` and `plan/current/` run state | `planifest-framework` (orchestrator and phase skills) | none |
| `planifest-overrides/` settings files | the product's human on the loop | `planifest-framework` reads them |

### Integration Points

| From | To | Method | Contract |
|------|-----|--------|----------|
| Orchestrator | Phase skills | skill load | `plan/.run-mode` value and the exception list |
| Phase skills | `planifest-loop-runner` | skill load | loop state files in `plan/current/` |

## Stack

| Concern | Decision |
|---------|----------|
| Language | Markdown skills and standards, JavaScript (`.mjs`) scripts and hooks, Bash and PowerShell setup |
| Runtime | Node for scripts and hooks |
| Framework | none |
| Frontend | none |
| Database | none |
| ORM | none |
| Testing | Bash test suites under `planifest-framework/tests/`, run by `run-tests.sh` |
| IaC | none |
| Cloud | none |
| Compute | none |
| CI | GitHub Actions |
| Build target | local |

## Scope Boundaries

### In Scope
- The 11 backlog entries listed above.

### Out of Scope
- Decomposing the orchestrator skill (0000020). It restructures the same file and goes in the next run.
- Quality gates for agent workflow evaluation (0000097), beyond the human-touchpoint count in US-002.
- Shell-guard, setup, and Windows entries.
- Push notifications. The framework can't send one on every tool, so on-the-loop visibility uses the build log.

### Deferred
- Nothing deferred.

## Non-Functional Requirements

| NFR | Target | Measurement |
|-----|--------|-------------|
| Human touchpoints | 0 outside the exception list in an `autonomous` run | Touchpoint count in the build log, flagged by the P8 report |
| P0 questions | at most 3 coaching questions when the brief is complete and the stack is unchanged | Question count in the P0 build-log block |
| Back-compat | `interactive` and `continuous` behave exactly as before | Existing test suites pass unchanged |
| Security | No exception-list item can be skipped: schema changes, destructive operations, and merges stay human-only | Tests over skill text and the run-mode contract |

## Constraints and Assumptions

### Constraints
- Merging a PR stays human-only in every mode.
- Hard limits 2 and 3 (schema and destructive changes) stay human-gated in every mode.
- No em dashes in framework prose. `em-dash-guard.mjs` blocks them.

### Assumptions
- A fresh-context checker is good enough to stand in for the human at a phase gate. The design critic and cross-model reviewer exist already.

## Scenario Paths

**Happy path:**

> You choose `autonomous` at P0 and confirm the design, the scope answers, and the run mode in one turn. After that, the run goes from confirmed design to a raised PR with no gate waiting for you. A fresh-context checker stands in at each gate and retries a failed check with a changed approach. Independent requirements move in parallel streams, and the build log records every decision. Success is one final report and a clean working tree. You review and merge.

**First-run path:**

> A product upgrades with no release-budget setting, no `autonomous` value in `plan/.run-mode`, and its own overrides. Nothing changes until you choose. `interactive` and `continuous` behave as before. If no release setting exists, P0 keeps the three-story rule. P0 offers `autonomous` and records it only after you accept it. An override wins over the `autonomous` text, and an override never counts as choosing `autonomous`.

**Error / sad path:**

> The most likely failure is a gate the run can't clear. The run doesn't stop and doesn't ask. It records each attempt and tries a different approach, up to 3 approaches per loop instance. The fourth becomes an exception-list item. A gross deviation is one the reversal protocol would class as *altering*. An exhausted budget is also an exception-list item. Exception-list items wait in the final report, and the run finishes all other work first.

**Cross-session continuity:**

> If a session stops mid-run, the next session carries on from where it stopped. `plan/.run-mode` keeps the mode, and 0000012-ADR-005 changes so `autonomous` is a recognised value. Loop state files keep attempt counts and budgets, so a restart doesn't reset them. Each parallel stream keeps a state file under `plan/current/streams/`. A stop during the P7 archive repeats only the unfinished steps.

## Acceptance Criteria

- [ ] An `autonomous` run goes from confirmed design to a raised PR with no phase gate, escalation, or ship question waiting for the human.
- [ ] In `autonomous` mode, only exception-list items wait, and they appear in one final report.
- [ ] P0 asks only real forks and records the number of questions it asked.
- [ ] A repo can set a release budget, and P0 fills the release up to it.
- [ ] P7 archives with no glob delete, and P9 ends with a clean working tree.
- [ ] P4 checks run again after P6.
- [ ] `interactive` and `continuous` runs behave exactly as before.
