---
title: "ADR 003: CI job security posture"
summary: "New jobs use the pull_request trigger, read-only contents permission, no secrets, and a 10-minute timeout."
status: "accepted"
version: "0.1.0"
---
# ADR-003 - CI job security posture

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000031-ci-test-and-powershell-coverage
**Component:** repository CI
**Date:** 2026-10-16

## Context

The new jobs run code from the pull request, including `setup.ps1` and every suite. The repository is public, so a pull request can come from a fork. The existing jobs set no `permissions` block, so they get the repository's default token access.

## Decision

- The new jobs keep the `pull_request` trigger. They never use `pull_request_target`.
- Each new job sets `permissions: contents: read`.
- No new job reads a secret.
- Each new job sets `timeout-minutes: 10`.
- The existing jobs stay as they are. A change to their permissions is out of scope.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Workflow-level `permissions` block | One line covers every job | Changes the existing jobs too | Out of scope. The existing jobs keep their current behaviour. |
| `pull_request_target` | Runs with secrets on fork PRs | Runs fork code with a write token | No job needs secrets, and the trigger is a known attack path |

## Affected Components

| Component | Impact |
|-----------|--------|
| repository CI | New jobs hold the least token access they need. |

## Consequences

**Positive:**
- Fork code running in the new jobs can read the repository but can't write to it.
- A runaway job stops after 10 minutes.

**Negative:**
- The existing jobs keep default token access until a later change narrows it.

**Risks:**
- A later job that needs write access must declare it explicitly.

## Related ADRs

- ADR-001 - related-to

## Supersedes

- None

## Superseded By

- None
