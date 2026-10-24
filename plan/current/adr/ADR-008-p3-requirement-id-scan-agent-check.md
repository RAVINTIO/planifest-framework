---
title: "ADR 008: P3 requirement-ID scan runs as a codegen agent check"
summary: "The codegen agent scans requirement IDs against test files before P3 closes. It is an agent check, not a script, and mirrors the P4 scan at validate-agent step 1."
status: "accepted"
version: "0.1.0"
---
# ADR-008 - P3 requirement-ID scan runs as a codegen agent check

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000037-green-ci-before-ship
**Component:** planifest-framework
**Date:** 2026-10-24

## Context

The validate agent maps requirement IDs to tests at P4 step 1. That scan is an agent check. An unmapped requirement therefore surfaces after P3 has closed, which costs a return trip to P3.

req-006 moves an equivalent scan to the end of P3. The design adds no new hook, so the question is whether the scan is a script or an agent check.

## Decision

- **Agent check:** The codegen agent runs the scan before it commits P3 and reports it complete. No script is added. This mirrors P4, which runs the same match by agent today.
- **Input:** The agent reads every file in `plan/current/requirements/`. For each requirement ID, it looks for that ID in test descriptions or structured comments in the test files. This is the same match as P4 step 1.
- **Type check:** For each criterion, the agent checks that a test of the type in its `Verified by` field exists, under the precedence rule in ADR-007. The agent compares the declared type with a header comment in the mapped test, not with a judgement of what the test does:
  - Each new suite carries one comment line near the top, `# Verified by: {type}`, naming the type its author claims. A suite that covers criteria of two types carries one line per type.
  - The check passes when the mapped suite's header names the criterion's declared type.
  - `execution` and `manual` need no header. P3 logs them as `deferred to P4`, and P4 verify by execution or the human on the loop confirms them.
  - A mismatch, or a mapped suite with no header, blocks P3 as an unmapped criterion does.
  - An existing suite without a header is never rewritten. A criterion mapped only to such a suite reads as `unspecified` for the type check.
  - Rejected: telling types apart by what the test does. The critic found that rule conflicts with the labels in req-001 to req-006, where text-reading suites carry both `unit` and `integration`. A criterion that reads as `unspecified`, or has no field, skips the type check and keeps the ID check.
- **Blocking:** An ID with no mapped test blocks P3 closing. The agent runs the TDD loop for the missing test under the existing attempt limit. In `autonomous`, the approach rules apply, and a requirement unmapped after 3 approaches becomes an exception-list item.
- **Log line:** The agent writes `Requirement-ID scan (P3): {N} requirements, {M} unmapped`.
- **P4 unchanged:** The P4 scan stays as it is. The P3 scan adds an earlier check and replaces nothing.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| A Node script run at P3 | Deterministic and testable | A second implementation of a match that P4 does by agent. Needs a new file and its own tests. | The two scans could drift apart |
| A commit-time hook | Blocks without agent action | The design lists no new hook. A hook can't tell when P3 closes. | Out of scope and a poor fit |
| Move the scan from P4 to P3 | One scan | P4 loses its independent check on the final tree | The P4 scan covers changes made after P3 |
| No scan before P4 | No change | Untested requirements keep surfacing late | req-006 asks for the earlier check |
| Tell types apart by what the test does | No header to maintain | Conflicts with the labels in req-001 to req-006, where text-reading suites carry both `unit` and `integration` | A mismatch would block P3 on about 14 correct criteria |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | Changes the codegen-agent skill and the validate-agent skill (the coverage table reports `unspecified`) |

## Consequences

**Positive:**
- Untested requirements surface before P4, while the TDD loop is still open.
- The scan uses the same match as P4, so the two agree on what counts as mapped.
- No new script or hook adds to the maintenance surface.

**Negative:**
- An agent check depends on the agent following the skill text, so it is less deterministic than a script.
- The match logic now lives in two skill files and must change in both.
- The `# Verified by:` header is self-declared. The check catches a missing or mismatched label, not a wrong one, so a suite can claim a type it doesn't test.

**Risks:**
- A requirement with no natural test, such as a docs-only one, blocks P3 (R-018). The `manual` value with a reason limits this.

## Governs

- req-006 (verified-by-and-p3-scan), the requirement-ID scan section

## Related ADRs

- ADR-007 - depends-on (the scan reads the `Verified by` field under its precedence rule)

## Supersedes

- None.

## Superseded By

- None.
