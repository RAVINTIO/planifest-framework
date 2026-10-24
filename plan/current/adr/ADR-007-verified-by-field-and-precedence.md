---
title: "ADR 007: Verified by field with six values and indented-line precedence"
summary: "Each acceptance criterion names its test type in a Verified by field with six allowed values. The indented line governs, non-enum inline text reads as unspecified, and no existing or archived file is rewritten."
status: "accepted"
version: "0.1.0"
---
# ADR-007 - Verified by field with six values and indented-line precedence

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000037-green-ci-before-ship
**Component:** planifest-framework
**Date:** 2026-10-24

## Context

Untested requirements surface at P4 today. req-006 asks each criterion to name its test type at P1, so the P3 and P4 scans can check that a test of that type exists.

Two constraints shape the field:

- The ratchet check blocks changes to existing criterion lines while a loop is active. A P1 fix agent therefore adds an indented line under a criterion rather than editing the criterion.
- The critic found that a same-type rule between inline and indented forms flags 9 of 11 requirement files (critic J2).

Requirement files already exist in `plan/current/` and in `plan/_archive/`. None carries the field.

## Decision

- **Enum:** The field takes one of six values: `unit`, `integration`, `contract`, `e2e`, `execution`, `manual`. The first four come from `planifest-framework/standards/testing-standards.md`. `execution` covers P4 verify by execution. `manual` covers a check no test can run and needs a one-line reason.
- **Two valid forms:** Either `- [ ] {criterion}. Verified by: {type}` on the criterion line, or an indented line `  - Verified by: {type} - {detail}` directly under it. The ` - {detail}` part is optional free text. The scans read only the type.
- **Precedence:** When an indented `Verified by:` line exists, it governs. The P3 and P4 scans ignore inline `Verified by` text on that criterion.
- **Inline text:** Inline text counts only when no indented line exists and only in the form `Verified by: {type}` with a type from the enum. Any other inline form reads as `unspecified`.
- **Legacy files:** A file without the field stays valid. The P3 scan and the P4 coverage table don't fail it, and the table reports `unspecified`. Nothing rewrites an existing or archived requirement file.
- **Template and spec agent:** `requirement.template.md` shows the field with the six values. The spec-agent skill tells the spec agent to fill it for every new criterion.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Require both forms to name the same type | No precedence rule to learn | Flags 9 of 11 files (critic J2) | Fails on files the field was meant to help |
| Inline form only | One place to look | The ratchet blocks edits to existing criterion lines | A P1 amendment can't add the field |
| Indented form only | One place to look | Longer files and a harder write for new criteria | Inline is the shorter form for new criteria |
| Free-text type names | No enum to maintain | The scan can't match a type to a test | Scans need a closed set |
| Rewrite existing files to add the field | Full coverage at once | Edits archived files and trips the ratchet | req-006 forbids rewriting |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | Changes the requirement template and the spec-agent, codegen-agent, and validate-agent skills |

## Consequences

**Positive:**
- A missing test of the named type surfaces at P3 rather than P4.
- Precedence lets a P1 amendment add the field without editing a protected line.
- Legacy files keep working, so no migration of existing requirements is needed.

**Negative:**
- Authors learn two forms and one precedence rule.
- A criterion with the wrong inline text reads as `unspecified` and skips the type check without warning.

**Risks:**
- A criterion marked `manual` could hide a testable check. The one-line reason makes this visible in review.

## Governs

- req-006 (verified-by-and-p3-scan), the `Verified by` field section

## Related ADRs

- ADR-008 - related-to (the P3 scan reads this field)

## Supersedes

- None.

## Superseded By

- None.
