---
title: "Feature Brief - token efficiency and Windows shard fix"
summary: "Cut the context cost of Claude Code sessions in this repo, and fix the flaky Windows timing check that failed PR #64."
status: "approved"
version: "0.1.0"
---
# Feature Brief - token efficiency and Windows shard fix

**Feature ID:** 0000038-token-efficiency-windows-shard

## Business Goal

Context drives 78.4% of the estimated cost of Claude Code sessions in this repo. Opus takes 87.6% of cost, and subagents take 53.8%. Backlog 0000230 holds the one-week profile and six changes to cut that cost. None of them may weaken a quality gate.

PR #64 merged with Windows shard 1 red. A hook call took 203 ms against a 200 ms test limit. The fix keeps the limit and removes the timing noise.

## Features

The human on the loop chose to build all seven stories in one run, against the three-story rule (P0, 2026-10-24).

| Feature | User Stories | Priority | Wave |
|---------|-------------|----------|------|
| Stable Windows timing checks | As the human on the loop, I see CI fail only when a hook is slow, so that a red check means a real fault | must-have | 1 |
| Model tiers take effect | As the human on the loop, I see subagents run on the tier the framework names, so that cheap work stops running on Opus | must-have | 1 |
| Quiet test output | As an agent running the suite, I get only failures and totals, so that each run adds little context | must-have | 1 |
| Phase-scoped orchestrator | As an agent past P0, I don't carry the P0 and Adoption Modes text, so that each request carries less context | should-have | 1 |
| Context reset at phase gates | As the human on the loop, I get a reset prompt after each passed gate, so that long sessions stop growing | should-have | 1 |
| Decomposition size floor | As an agent, I dispatch a subagent only for work that needs its own reads, so that small units don't pay a fresh context | should-have | 1 |
| Partial reads of large files | As an agent, I search or read a section of a file over about 20 KB, so that one read doesn't add 75 KB | should-have | 1 |

## Waves

| Wave | Features Included | Ships When |
|------|-------------------|------------|
| 1 | All seven | P9 raises the PR with green checks |

## Target Architecture

### Components

| Component | Type | New or Existing | Responsibility |
|-----------|------|-----------------|---------------|
| `planifest-framework` | component-pack | existing | Skills, standards, templates, tests, and the test runner |

### Data Ownership

| Data Store | Owner Component | Shared With |
|------------|----------------|-------------|
| `plan/current/` | `planifest-framework` | none |

### Integration Points

| From | To | Method | Contract |
|------|-----|--------|----------|
| skills | Claude Code Agent tool | `model` parameter | accepts `sonnet`, `opus`, `haiku`, or `fable` |

## Stack

Unchanged: Bash, PowerShell, Node ES module hooks and scripts, Markdown, GitHub Actions. Build target: local.

## Scenario Paths

Not filled in. The orchestrator derives them.

## Source

Backlog 0000230 (`plan/backlog/0000230-token-efficiency-from-claude-code-usage-profile/entry.md`) holds the evidence, the six changes, and the measures. PR #64 CI run `40090446386` holds the Windows failure.
