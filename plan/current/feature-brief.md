---
title: "Feature Brief - pipeline friction and gate fixes"
summary: "Removes recurring pipeline workarounds, keeps installed copies in step with source, and closes two gate bypasses and two hook output gaps."
status: "draft"
version: "0.1.0"
---
# Feature Brief - pipeline friction and gate fixes

**Feature ID:** 0000036-pipeline-friction-and-gate-fixes

> Written by the orchestrator from eleven backlog entries the human on the loop pulled in at P0 on 2026-10-22. The human on the loop asked for one big release.

## Business Goal

Recent runs each paid for the same workarounds. A long feature ID breaks the P9 commit. A list-item anchor stops `autonomous` from restoring. Two rules share the number Hard Limit 8. Installed skills and hooks drift from source, and downstream projects get no prompt to re-run setup. This release removes those workarounds and turns the design critic on by default. It also closes two write-gate bypasses and two hook output gaps.

## Features

| Feature | User Stories | Priority | Wave |
|---------|-------------|----------|------|
| Re-run setup migration (0000158) | US-001: As the human on the loop in a downstream project, I get a migration that re-runs setup after I update the framework, so that my installed hooks and boot file match the framework version. | must-have | 1 |
| Installed skill drift check (0000154) | US-002: As the human on the loop, I see which installed skills differ from source when a session starts, so that no phase runs on a stale skill copy. | must-have | 1 |
| Short ship commit subjects (0000160) | US-003: As the human on the loop, I see every ship commit pass the `commit-msg` hook whatever the feature ID length, so that P7 and P9 never stop on a rejected subject. | must-have | 1 |
| Run-mode anchor format (0000127) | US-004: As the human on the loop, I see `autonomous` restore after P0 whether the anchor line is bare or a list item, so that a format slip never needs a repair commit. | must-have | 1 |
| Hard limits cited by name (0000157) | US-005: As the human on the loop, I see every hard-limit citation name its rule, so that no agent mistakes the build-log rule for the Write-or-Edit rule. | must-have | 1 |
| Design critic on by default (0000122) | US-006: As the human on the loop, I see the design critic review P1 and P2 in every run mode by default, so that a fresh-context check catches drafting gaps before I read the artifacts. | should-have | 1 |
| Story split prompt (0000139) | US-007: As the human on the loop, I see an agent ask whether a requirement holds two concerns before it grows past three criteria, so that a requirement is split rather than packed. | should-have | 1 |
| No design from a non-regular file (0000143) | US-008: As the human on the loop, I rely on the write gate to treat a folder or FIFO at `design.md` as no design, so that neither one admits a `src/` write. | should-have | 1 |
| Permitted names inside enforcement paths (0000159) | US-009: As the human on the loop, I rely on the write gate to judge a permitted file name inside an enforcement folder like any other path, so that the name can't bypass the enforcement list. | should-have | 1 |
| Test runner clears the project dir (0000155) | US-010: As the human on the loop, I see `run-tests.sh` clear `CLAUDE_PROJECT_DIR` before any suite, so that a suite run inside Claude Code tests its fixture and not the real repo. | should-have | 1 |
| Escaped hook output (0000149) | US-011: As the human on the loop, I see every hook message escape the text it quotes, so that a crafted criterion or path can't forge or hide hook output. | should-have | 1 |

## Waves

| Wave | Features Included | Ships When |
|------|-------------------|------------|
| 1 | All eleven | Every acceptance criterion passes and the full suite passes on CI |

## Target Architecture

### Components

| Component | Type | New or Existing | Responsibility |
|-----------|------|-----------------|---------------|
| `planifest-framework` | component-pack | existing | Hooks, scripts, skills, standards, templates, migrations, and tests |
| `setup-hook-integration` | component-pack | existing | Setup integration docs, touched only if setup behaviour changes |

### Data Ownership

| Data Store | Owner Component | Shared With |
|------------|----------------|-------------|
| `plan/_migrations/` run records | `planifest-framework` (migrator skill) | orchestrator resume detection, read only |
| `plan/current/build-log.md` run-mode anchor | `planifest-framework` (orchestrator) | `run-mode.mjs`, read only |
| Installed copies under `.claude/` and other tool folders | `planifest-framework` (setup scripts) | skill drift check, read only |

### Integration Points

| From | To | Method | Contract |
|------|-----|--------|----------|
| `gate-write.mjs`, `ratchet-check.mjs`, `em-dash-guard.mjs` | `path-rules.mjs` | ES module import | `evaluateWrite`, `isAlwaysPermitted`, `isEnforcementPath`, `shown` |
| Orchestrator resume detection | skill drift check script | process run by the agent | exit code and a list of stale skills |
| Orchestrator resume detection | `run-mode.mjs` | process run by the agent | prints the run mode |

## Stack

| Concern | Decision |
|---------|----------|
| Language | JavaScript ES modules, Bash, PowerShell, Markdown |
| Runtime | Node (built-ins only in hooks) |
| Framework | none |
| Frontend | none |
| Database | none |
| ORM | none |
| Testing | Bash suites under `planifest-framework/tests/` |
| IaC | none |
| Cloud | none |
| Compute | none |
| CI | GitHub Actions |
| Build target | local |

## Scope Boundaries

### In Scope
- Backlog entries 0000158, 0000154, 0000160, 0000127, 0000157, 0000122, 0000139, 0000143, 0000159, 0000155, and 0000149.
- One re-run-setup migration that covers the setup-delivered changes in 0.33.0 and 0.34.0.

### Out of Scope
- Shell-guard parser entries 0000105, 0000108, 0000115, and 0000116. They wait on 0000118 and 0000119.
- The remaining 0000035 hardening entries: 0000140 to 0000142, 0000144 to 0000148, and 0000150 to 0000152.
- Renumbering the orchestrator or boot hard limits.
- Changing what setup copies or where it copies it.

### Deferred
- Nothing deferred.

## Non-Functional Requirements

| NFR | Target | Measurement |
|-----|--------|-------------|
| Hook latency | each hook call stays under 500 ms | existing suite timing |
| Drift check latency | under 1 s on this repo | suite timing |
| Hook constraints | Node built-ins only, no process spawn | suite source check |

## Constraints and Assumptions

### Constraints
- 0000035 ADR-001 and 0000032 ADR-004: hooks use Node built-ins only, with no process spawn.
- 0000003 ADR-005: hooks fail open on unexpected errors. US-008 narrows this for a non-regular `design.md` only.
- 0000033 ADR-009: Fast Path never admits an enforcement path.
- Every change goes through **Write** or **Edit**.

### Assumptions
- Setup copies each `SKILL.md` byte for byte, so a byte compare finds drift.
- `autonomous` keeps `design_critic` at `on`. Only the default outside `autonomous` changes.

## Scenario Paths

> Derived at P0 by the Scope Lock Challenge. See the P0 block of `build-log.md`.

## Acceptance Criteria

**US-001 (0000158)**
- [ ] A migration re-runs setup for 0.34.0. It names the setup-delivered changes in 0.33.0 and 0.34.0 and follows the 0.31.0 migration's sections.
- [ ] `standards/framework-update-policy.md` says that a release that changes a setup-delivered file ships a re-run-setup migration.
- [ ] A suite checks the migration's sections and the policy sentence.

**US-002 (0000154)**
- [ ] A Node script compares each source `SKILL.md` with its installed copy for the active tool. It lists each stale or missing copy and exits non-zero when it finds one. It ignores the folders that setup adds.
- [ ] Orchestrator resume detection runs the script at session start. If it reports drift, the orchestrator names the stale skills, loads their source copies, and recommends a setup run.
- [ ] A suite covers a match, a stale copy, and a missing copy.

**US-003 (0000160)**
- [ ] No commit subject template in any framework skill holds `{feature-id}`. The ID goes in the body.
- [ ] A suite fails if a skill's commit subject template holds a placeholder or exceeds 72 characters.

**US-004 (0000127)**
- [ ] `run-mode.mjs` accepts the anchor as a bare line or as one `- ` list item, and keeps every other rule.
- [ ] The orchestrator skill and the build-log template show the exact anchor line in a code block.
- [ ] A suite covers the list-item form and rejects an indented line, another prefix, and a line added in a later commit.

**US-005 (0000157)**
- [ ] Every citation of a hard limit names its rule as well as its number. No framework file cites a bare "Hard Limit 8".
- [ ] `standards/agent-dispatch-standards.md` states the Write-or-Edit rule in its dispatch template.
- [ ] A suite fails on a bare hard-limit citation.

**US-006 (0000122)**
- [ ] An absent `design_critic` key reads as `report-only` outside `autonomous`. `autonomous` still reads it as `on`.
- [ ] The loop runner Toggle Protocol, the toggles template, and the orchestrator skill state the new default.
- [ ] `test-0000033-req-003-gates-as-loops.sh` and its regression copy assert the new default.

**US-007 (0000139)**
- [ ] The spec agent, the design critic rubric, and the loop runner fix dispatch each carry a split step. Before a requirement passes three criteria, the step asks whether it holds two concerns.
- [ ] A suite checks that each of the three skills carries the step.

**US-008 (0000143)**
- [ ] A folder, FIFO, or other non-regular file at `plan/current/design.md` counts as no design. A `src/` write then blocks with exit 2 and a reason.
- [ ] The hook never opens a non-regular `design.md`, so a FIFO can't make it wait.
- [ ] A regular `design.md` that can't be read still fails open, and an ADR records the narrowed rule.

**US-009 (0000159)**
- [ ] A permitted file name inside an enforcement path gets no shortcut and takes the normal route.
- [ ] A permitted file name outside enforcement paths behaves as before.
- [ ] A suite covers both cases with and without `design.md`.

**US-010 (0000155)**
- [ ] `run-tests.sh` clears `CLAUDE_PROJECT_DIR` before it runs any suite.
- [ ] The four gate-related suites that lack it clear the variable for a standalone run.
- [ ] A suite checks both.

**US-011 (0000149)**
- [ ] `ratchet-check.mjs` and `em-dash-guard.mjs` print quoted text through `shown()`.
- [ ] `shown()` never cuts an escape sequence in half at its length cap.
- [ ] Suite cases cover each output with a control character, U+202E, and an over-long value.
