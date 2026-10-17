---
title: "Feature Brief - Governance continuity and write-gate scope"
summary: "Keep Planifest governing a session through P9 and after it, and stop gate-write blocking paths outside the repository."
status: "draft"
version: "0.1.0"
---
# Feature Brief - Governance continuity and write-gate scope

**Feature ID:** 0000032-governance-continuity-and-write-gate-scope

> Drafted by the orchestrator from backlog entries 0000077 and 0000084. The human on the loop confirms or edits each section during P0.

## Business Goal

A downstream product's run lost Planifest governance at P7, not after P9. The agent then took on new work in the same session with no triage, no P0, and no build log. This feature keeps a run governed until P9 ends, and makes every request after P9 go through triage. It also stops `gate-write.mjs` blocking files outside the repository, and makes its block reasons visible to the agent.

## Problem

### From backlog 0000077 (governance lapses after P7 removes the sentinel)

1. The ship skill deletes `plan/.orchestrator-active` in P7 Step 6, before P8 and P9 run. From that point, nothing marks the run as active.
2. `auto-trigger-orchestrator.mjs` then says "the orchestrator has not been loaded yet for this session" on every prompt. The skill is loaded, so the message is false and the agent learns to ignore it.
3. Requests after P9 skipped the Routing Directive. The agent cut a new branch and committed plan changes with no P0, sentinel, `discovery.md`, or build log.
4. A P9 handover note said the next code change needed no P0, and followed a runbook that pushed straight to `main`.
5. `setup.sh` registers `gate-write.mjs` and `ratchet-check.mjs` on **Write** and **Edit** only. In auto mode the agent wrote nearly every file through Bash, which neither hook sees.
6. `gate-write.mjs` blocked a **Write** to the agent's memory folder, outside the repository.

### From backlog 0000084 (gate-write blocks paths outside the repository)

1. When the target isn't under `cwd`, `relTarget` becomes the raw absolute path. It matches no permitted prefix, so the hook blocks it, with or without a design.
2. The hook writes its block reason to stdout and exits 2. Claude Code reads a PreToolUse block reason from stderr, so the agent sees only `No stderr output`.

### Source entries

The full text of both entries is in git history at commit `0935aeb`, under `plan/backlog/0000077-governance-lapses-after-p7-removes-the-sentinel/entry.md` and `plan/backlog/0000084-gate-write-blocks-paths-outside-the-repository/entry.md`.

## Features

| Feature | User Stories | Priority | Wave |
|---------|-------------|----------|------|
| Run lifecycle | As the human on the loop, I want the orchestrator sentinel to stay in place until P9 ends, so that hooks treat P8 and P9 as part of the run. | must-have | 1 |
| Post-run triage | As the human on the loop, I want every request after P9 triaged into a track before any work starts, so that no code change escapes the pipeline. | must-have | 1 |
| Write-gate scope | As an agent, I want `gate-write` to ignore paths outside the repository and to show its block reason, so that I can act on a block without reading the hook's source. | must-have | 1 |
| Shell-write guard | As the human on the loop, I want writes under `src/` through Bash held to the same design gate as **Write** and **Edit**, so that auto mode cannot bypass the gate. | should-have | 1 |

> At P2 the human on the loop split these four stories into 12 requirements, each with at most 3 criteria, all in one build. See `plan/current/requirements/`.

## Target Architecture

### Components

| Component | Type | New or Existing | Responsibility |
|-----------|------|-----------------|---------------|
| planifest-framework | component-pack | existing | Skills, hooks, templates, and setup scripts |

### Data Ownership

| Data Store | Owner Component | Shared With |
|------------|----------------|-------------|
| `plan/.orchestrator-active`, `plan/.orchestrator-ack`, `plan/.run-mode` | planifest-framework (orchestrator and ship skills) | enforcement hooks, read only |

## Stack

| Concern | Decision |
|---------|----------|
| Language | JavaScript (ES modules), Bash, PowerShell, Markdown |
| Runtime | Node |
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

## Acceptance Criteria

### Run lifecycle

- [ ] AC-1: The ship skill deletes `.orchestrator-active`, `.orchestrator-ack`, and `.run-mode` after P8 completes and before the Step 9 tag. It commits the deletions, then tags. Push and PR stay optional per the project's settings and the human's choice, so the tag and any later push never carry the markers. The P7 Step 7 commit and the Step 9b check no longer refer to them.
- [ ] AC-2: Resume Detection step 2a reads the feature ID from the sentinel and picks the latest `plan/_archive/{feature-id}-*` directory. With no `build-report.md` there, it resumes at P8. With one, it resumes at the P9 marker deletion. With no matching archive, it stops and asks the human on the loop.

### Post-run triage

- [ ] AC-3: When `planifest-framework/` exists and no sentinel exists, the auto-trigger hook says no Planifest run is active. It tells the agent to triage the request as Fast Path, Change Pipeline, or Feature Pipeline before acting. It keeps the instruction to load the skill, and it no longer claims the skill isn't loaded.
- [ ] AC-4: The ship skill requires any P9 handover note to route each next step through a track. The note never says a code change needs no P0.
- [ ] AC-5: Ship Step 12 asks the human on the loop to run `/clear` or start a new session. If a new request arrives in the same session, the orchestrator refuses that work and repeats the request. The orchestrator's Context Hygiene section matches.

### Write-gate scope

- [ ] AC-6: `gate-write.mjs` exits 0 for a target outside the repository root, with or without `design.md`. The root is `CLAUDE_PROJECT_DIR` when it names a folder. Otherwise it is the outermost folder above `cwd` that holds `planifest-framework/`, then the nearest that holds `.git`, or `cwd` when none does. A marker inside `plan/` or `docs/` never counts (ADR-004). Tests cover both cases, and a `..` path that leaves the root.
- [ ] AC-7: Every enforcement hook that exits 2 writes a plain-text reason to stderr. It keeps any existing stdout output, so the Windsurf adapter and `ratchet-check.mjs`'s JSON still work. Tests assert that stderr is not empty on each block path.

### Shell-write guard

- [ ] AC-8: A new Bash PreToolUse hook exits 2 with a stderr reason for a command that writes to a gated path. It detects these writers:
  - redirects (`>`, `>>`) and `tee`
  - in-place edits (`sed -i`, `perl -i`)
  - `cp`, `mv`, `install`, and `ln` targets
  - `rm`, `touch`, and `mkdir`

  When it can't parse a command, it writes a warning to stderr and allows it. Git commands that write files are a documented limit.
- [ ] AC-9: The Bash hook and `gate-write.mjs` share one module for path rules, so the gated paths match exactly. These are every repository path outside the always-permitted list. With no `design.md` it blocks, and with one it applies the component-path check. Read-only commands and writes outside the repository pass.
- [ ] AC-10: `setup.sh` and `setup.ps1` register the Bash hook for Claude Code. Running setup twice leaves exactly one registration. The setup tests assert both.
- [ ] AC-11: A 0.31.0 migration in `planifest-framework/migrations/` tells downstream projects to re-run setup, so they gain the Bash hook and the new hook messages.

## Scope Boundaries

### In Scope
- Ship skill: sentinel, ack, and run-mode deletion timing, the P9 handover-note rule, and the related commit and check steps
- Orchestrator skill: Resume Detection step 2a, and the post-P9 context clear before new work
- `auto-trigger-orchestrator.mjs` message
- `gate-write.mjs` scope, and stderr block reasons in every enforcement hook that exits 2
- A new Bash PreToolUse shell-write guard sharing `gate-write.mjs`'s path rules, registered by `setup.sh` and `setup.ps1` for Claude Code
- A 0.31.0 migration telling downstream projects to re-run setup
- Two ADRs superseding 0000015 ADR-001 (interrupted-run signal) and ADR-002 (advisory post-P9 message)
- Tests for each change, run by `run-tests.sh` and the 0000031 CI jobs

### Out of Scope
- Registering the shell-write guard for tools other than Claude Code
- Extending `ratchet-check.mjs` to shell writes
- Shell writes made by git commands, scripts, or variables the guard can't parse
- Fast Path writes through `gate-write` (backlog 0000081)
- Downstream product runbooks that push to `main`

### Deferred
- Nothing deferred

## Non-Functional Requirements

| NFR | Target | Measurement |
|-----|--------|-------------|
| Hook latency | Each changed or new hook completes in under 200 ms per call on the CI runners | Timed in the hook test suites |
| Fail-open | Every hook exits 0 on an unexpected error, per the existing enforcement ADR | Tests feed malformed stdin, JSON with no `command`, and a non-string `command` to each changed or new hook |
| Shell-guard false positives | Zero blocks on a fixed corpus of read-only commands that mention gated paths | Corpus test in the new hook's suite |
| Shell-guard detection | Blocks every command in a fixed corpus of AC-8 writer forms aimed at gated paths | Corpus test in the new hook's suite |

## Constraints and Assumptions

### Constraints
- No em dashes in Planifest artifacts. Write "human on the loop", not "user" or "developer".
- Hooks stay dependency-free Node ES modules that read stdin through `read-stdin.mjs`.
- The shell-write guard is a heuristic. It cannot see writes from inside an arbitrary script, so the boot file must also state that code changes go through **Write** or **Edit**.

### Assumptions
- Claude Code shows a PreToolUse block reason from stderr when the hook exits 2.
- Claude Code passes the Bash command as `tool_input.command` to a PreToolUse hook.
