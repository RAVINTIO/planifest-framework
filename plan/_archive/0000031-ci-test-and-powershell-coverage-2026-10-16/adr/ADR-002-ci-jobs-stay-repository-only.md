---
title: "ADR 002: New CI jobs stay repository-only"
summary: "The suite and Windows jobs go in this repository's workflow only, never in the consumer workflow copy that setup installs."
status: "accepted"
version: "0.1.0"
---
# ADR-002 - New CI jobs stay repository-only

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000031-ci-test-and-powershell-coverage
**Component:** repository CI
**Date:** 2026-10-16

## Context

Setup installs `planifest-framework/hooks/planifest.yml` into downstream repos as their workflow. 0000019-ADR-001 kept `self-description-check` out of that copy, because it tests this repository rather than the consumer. The new jobs test the framework itself.

## Decision

The suite job and the Windows job go in `.github/workflows/planifest.yml` only. `planifest-framework/hooks/planifest.yml` stays unchanged. A comment above each new job states this, in the same way as the existing `self-description-check` comment.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Add the jobs to the consumer copy too | Consumers would notice a broken vendored framework | Consumers would pay for framework tests on every PR, including macOS minutes | Consumers don't change the framework, so the tests tell them nothing new |

## Affected Components

| Component | Impact |
|-----------|--------|
| repository CI | Gains the new jobs. |
| planifest-framework | Its consumer workflow copy stays unchanged. |

## Consequences

**Positive:**
- Consumer CI cost and behaviour stay the same.

**Negative:**
- The two workflow files drift further apart, so a reader has to know which one is which.

**Risks:**
- A future change could copy the jobs into the consumer file by mistake. The REQ-001 acceptance criterion checks for no diff.

## Related ADRs

- 0000019-ADR-001 - extends
- ADR-001 - related-to

## Supersedes

- None

## Superseded By

- None
