---
title: "Requirement: req-006 - verified-by-and-p3-scan"
summary: "Each acceptance criterion names its test type at P1, and the codegen agent runs the requirement-ID scan before P3 closes."
status: "draft"
version: "0.1.0"
---
# Requirement: req-006 - verified-by-and-p3-scan

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000037-green-ci-before-ship
**Source:** US-006
**Priority:** should-have

## User Story

As the human on the loop, I see each acceptance criterion name its test type at P1, and P3 run the requirement-ID scan before it closes, so that untested requirements surface before P4.

## Functional Requirements

### "Verified by" field in the requirement template

- `planifest-framework/templates/requirement.template.md` adds a `Verified by:` field to each line in `## Acceptance Criteria`. The line form is:
  - `- [ ] {{criterion}}. Verified by: {{unit | integration | contract | e2e | execution | manual}}`
- The values come from the test types in `planifest-framework/standards/testing-standards.md`, plus `execution` for P4 verify by execution and `manual` for a check no test can run. A `manual` value needs a one-line reason after it.
- The spec agent fills the field for every new criterion. Its Functional requirements rules in `planifest-framework/skills/planifest-spec-agent/SKILL.md` say so.

### Requirement-ID scan before P3 closes

- Before the codegen agent commits P3 and reports it complete, it scans every file in `plan/current/requirements/`.
- For each requirement ID, it looks for that ID in the test descriptions or structured comments of the test files. This is the same match the validate agent makes at P4 step 1.
- For each criterion, it checks that a test of the type named in `Verified by` exists. A criterion with no `Verified by` field skips the type check and keeps the ID check.
- A requirement ID with no mapped test blocks P3 closing. The codegen agent runs the TDD loop for the missing test. The existing attempt limit applies. In `autonomous`, the existing approach rules apply, and a requirement still unmapped after 3 approaches becomes an exception-list item.
- The agent writes one build-log line: `Requirement-ID scan (P3): {N} requirements, {M} unmapped`.
- The P4 scan stays as it is. The P3 scan adds an earlier check and replaces nothing.

### Existing requirement files

- A requirement file without `Verified by` stays valid. Neither the P3 scan nor the P4 coverage table fails it for the missing field.
- The P4 coverage table reports the type for such a criterion as `unspecified`.
- Nothing rewrites an existing requirement file. This holds for archived files and for files in `plan/current/` written before this release.

## Acceptance Criteria
- [ ] `requirement.template.md` shows `Verified by:` on its criterion lines with the six allowed values, and the spec-agent skill tells the spec agent to fill it. Verified by: unit (a text test over the template and the skill).
- [ ] The codegen agent scans `plan/current/requirements/` for unmapped requirement IDs before P3 closes, blocks closing on a gap, and writes `Requirement-ID scan (P3): {N} requirements, {M} unmapped`. Verified by: integration (a fixture requirement set with one unmapped ID).
- [ ] A requirement file with no `Verified by` field passes both the P3 scan and the P4 coverage table, and the table reports its type as `unspecified`. Verified by: integration (a fixture file without the field).

## Split step: keep

Three criteria, so the split step does not trigger. The three describe one outcome: an untested requirement surfaces before P4. The field, the scan and the legacy rule all serve it.

## Dependencies
- `planifest-framework/standards/testing-standards.md` for the test type names.
- `planifest-framework/skills/planifest-validate-agent/SKILL.md` step 1 (the P4 scan this requirement mirrors, and the coverage table that reports `unspecified`).
- Files P3 changes: `planifest-framework/templates/requirement.template.md`, `planifest-framework/skills/planifest-spec-agent/SKILL.md`, `planifest-framework/skills/planifest-codegen-agent/SKILL.md`, `planifest-framework/skills/planifest-validate-agent/SKILL.md`.
