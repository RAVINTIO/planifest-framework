---
title: "ADR 007: Brand guard with a path and line allowlist"
summary: "A Bash suite fails when the old brand name appears in a live tracked path or line unless an allowlist entry matches both the path and the line. A stale entry fails the suite."
status: "accepted"
version: "0.1.0"
---
# ADR-007 - Brand guard with a path and line allowlist

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000039-ravintio-rebrand
**Component:** ravintio-framework (renamed from planifest-framework)
**Date:** 2026-10-25

## Context

The rename removes the old name from most live files. Without a guard, the name returns through copied text and old habits. Some uses must stay. They include the `PLANIFEST_SESSION_ID` fallback, the 0.37.0 migration and its helpers, and the `planifest-docs` sibling links.

RAVINTIO Zero 0000160 ADR 004 solved the same problem with an allowlist suite. It also found that `done < <(...)` drops lines on macOS Bash 3.2. Risk R-006 and R-014 name both problems here.

This decision governs req-007. It also sets the allowlist shape that req-002, req-003, req-004, req-005, req-006, req-008, and req-009 rely on.

## Decision

Add the Bash suite `ravintio-framework/tests/test-0000039-req-007-brand-guard.sh`. It follows RAVINTIO Zero 0000160 ADR 004.

### Scan

- The suite reads `git ls-files`.
- It drops history paths: `plan/_archive/`, `plan/changelog/`, `plan/_migrations/`, and the bodies of migrations shipped before 0.37.0.
- It also drops `plan/current/`, because ship archives it and its files quote the old name.
- It fails on any remaining path or line that matches `planifest` in any case, unless an allowlist entry covers it.
- A failure prints the file and line number.

### Allowlist

- Each entry holds a path regex, a line regex, and a reason comment.
- Both regexes must match. A path-only entry would let a new line hide in an allowed file.
- The list is closed. It holds only the cases that req-007 names.
- A path match applies to a path check with no line, so a tracked path that holds the old name also needs an entry.

### Stale entries and the planted case

- An entry that matches no path or line fails the suite. The list cannot grow unnoticed.
- A second case plants the old name in a scratch copy of `README.md`. It expects a flag with the file and line number.

### Shell form

- The suite reads lines with `done <<< "$(...)"` and skips empty lines.
- It never uses `done < <(...)`.
- The macOS CI leg runs Bash 3.2 and checks this form.

### Regression tag

The suite carries `# REGRESSION-CANDIDATE:`. Ship offers it for promotion to `ravintio-framework/tests/regression/`. The allowlist covers the suite and its regression copy, because both must name the word to match it.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Path-only allowlist | Shorter list and simpler code | A new old-name line passes inside any allowed file | Weak guard. R-014 asks for a line regex on every entry |
| Grep step in CI with no allowlist | No test file to maintain | Cannot allow the fallbacks, so it fails at once or gets switched off. It also skips local runs | The allowed uses are real and need a reason on record |
| Node script | Regex handling is the same on every shell | Adds a second language to the test pack. The suites are Bash and the runner expects `.sh` | The stack stays unchanged (ADR-001). Bash covers the need |

## Affected Components

| Component | Impact |
|-----------|--------|
| ravintio-framework | Adds one suite, its allowlist, and a regression candidate. Later edits near allowed lines must update the list |
| setup-hook-integration | Setup lines that detect old markers sit on the allowlist. Edits to those lines need an allowlist update |

## Consequences

**Positive:**
- The old name cannot return to a live file without a visible allowlist change.
- The allowlist records the reason for every remaining use.
- The Bash 3.2 loop form removes a known cause of silent passes.

**Negative:**
- Any edit to an allowed line can break the suite. The person who makes the edit must update the entry.
- A line-level list takes more upkeep than a path-level one. Each new owner of a legacy line pays this cost.

**Risks:**
- The allowlist grows wide enough to hide real misses. The closed list, the reason comments, and the stale-entry check limit this.
- The scan passes on Bash 5 and misses lines on Bash 3.2. Run the suite under both before the first push.

## Related ADRs

- ADR-002 - depends-on: the guard enforces the rename map
- ADR-004 - depends-on: the old-name reads are allowlist entries
- ADR-006 - depends-on: the migrator mapping lines are allowlist entries
- ADR-009 - related-to: the history paths that the guard drops stay as written
- RAVINTIO Zero 0000160 ADR 004 - extends: reuses its guard model

## Supersedes

- None.

## Superseded By

- None.
