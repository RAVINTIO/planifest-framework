---
title: "ADR 001: Stack unchanged, credential-scan.mjs on Node built-ins only"
summary: "0000037 keeps the declared stack. The new credential-scan.mjs uses Node built-ins and the git command line. It adds no dependency and no package manifest."
status: "accepted"
version: "0.1.0"
---
# ADR-001 - Stack unchanged, credential-scan.mjs on Node built-ins only

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000037-green-ci-before-ship
**Component:** planifest-framework
**Date:** 2026-10-24

## Context

The design declares this stack:

- Bash and PowerShell scripts
- Node ES modules for hooks and scripts
- Markdown skills
- GitHub Actions

The design states "Stack unchanged". It declares no database, ORM, IaC, cloud, or compute.

Stream 01 adds one script, `planifest-framework/scripts/credential-scan.mjs`. The script reads staged content and files, applies the P8 patterns, and sets an exit code. It must run on macOS, Linux, and Windows.

## Decision

The feature keeps the declared stack. `credential-scan.mjs` imports Node built-ins only, such as `node:fs`, `node:path`, and `node:child_process`. It calls `git` and, when present, `gitleaks` as external programs. The feature adds no npm package and no `package.json`.

The other stream 01 changes are Markdown skill text, one override file, and Bash test suites. They need no stack decision.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Bash script with `grep` | No Node needed | GNU and BSD `grep` differ, and it does not run on Windows without Git Bash | Node gives one behaviour on all three systems |
| Node script with an npm secret-scanning package | Larger rule set | Adds a dependency and an install step to a framework that ships none | The P8 regex plus optional `gitleaks` is enough |
| Rely on `gitleaks` alone | No pattern list to maintain | Not installed by default, so the scan would not run | The regex must run when `gitleaks` is absent |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | Gains `scripts/credential-scan.mjs`. No change to its declared stack. |

## Consequences

**Positive:**
- The script runs wherever Node runs, with no install step.
- One pattern list serves the P8 guard, the Step 10b guard, and the PR text scan.

**Negative:**
- The regex list is small, so it finds fewer secret types than a dedicated scanner.
- The script spawns `git`, so a missing `git` makes the scan exit `2`.

**Risks:**
- A future need for a richer rule set pushes toward a dependency. A new ADR must then record that change.

## Related ADRs

- ADR-003 - depends-on (the script it describes)
- 0000036 ADR 001 - related-to (same no-dependency position)

## Governs

req-003, req-004

## Supersedes

- None

## Superseded By

- None
