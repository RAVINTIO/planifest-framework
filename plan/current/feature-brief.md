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
