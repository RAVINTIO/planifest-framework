---
title: "ADR 001: Stack unchanged"
summary: "The feature removes code and keeps the declared stack: Bash, PowerShell, Node .mjs hooks, Markdown, and GitHub Actions."
status: "accepted"
version: "0.1.0"
---
# ADR-001 - Stack unchanged

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000030-context-mode-and-telemetry-mcp-removal
**Component:** all
**Date:** 2026-10-14

## Context

The confirmed design declares Bash, PowerShell, Node `.mjs` hooks, and Markdown, with GitHub Actions as CI and a local build target. This feature only removes code and adds clean-up logic to existing setup scripts.

## Decision

Keep the stack exactly as declared. The new clean-up logic lives in the existing setup scripts. It uses Node for JSON edits, as setup already does, and the PowerShell setup uses its native JSON support. No new language, runtime, or dependency is added.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Write the clean-up as a separate Node script called by both setup scripts | One implementation instead of two | PowerShell setup would gain a Node dependency it doesn't have today for this path | Breaks the existing parity pattern, where each setup script owns its own logic |
| Use `jq` in `setup.sh` | Short, readable JSON edits | `jq` isn't always installed, and 0000017-ADR-002 removed the `jq` requirement | Reintroduces a dependency the framework removed |

## Affected Components

| Component | Impact |
|-----------|--------|
| `planifest-framework` | None beyond the deletions in ADR-002 |
| `setup-hook-integration` | Clean-up logic added in Bash with Node, and in PowerShell |

## Consequences

**Positive:**
- No new dependency for downstream projects.

**Negative:**
- The clean-up exists twice, once per setup script, and the two copies can drift.

**Risks:**
- PowerShell drift goes unseen locally, because `pwsh` isn't installed (R-004).

## Related ADRs

- 0000017-ADR-002 - related-to (Node-only hooks, no `jq`)

## Supersedes

- None

## Superseded By

- None
