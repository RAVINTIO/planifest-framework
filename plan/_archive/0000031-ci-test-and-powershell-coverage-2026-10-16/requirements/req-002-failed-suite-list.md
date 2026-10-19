---
title: "Requirement: req-002 - failed-suite-list"
summary: "run-tests.sh names each failed suite before its summary."
status: "active"
version: "0.1.0"
---
# Requirement: req-002 - failed-suite-list

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000031-ci-test-and-powershell-coverage
**Source:** US-001
**Priority:** must-have

## User Story

As the human on the loop, I see CI fail a pull request when `run-tests.sh` fails on Linux or macOS, so that a broken suite can't merge.

## Functional Requirements
- `run-tests.sh` records the file name of each feature suite and each regression suite that fails.
- Before the summary block, it prints a `Failed suites:` heading followed by one file name per line. Regression suites carry a `regression/` prefix.
- When no suite fails, it prints no `Failed suites:` heading.
- The exit code and the existing summary lines stay unchanged.

## Acceptance Criteria
- [ ] With one failing feature suite and one failing regression suite, the output lists both file names under `Failed suites:`, and the script exits 1.
- [ ] With every suite passing, the output has no `Failed suites:` heading, and the script exits 0.
- [ ] The `Feature suites:` and `Regression suite:` summary lines keep their current wording.

## Dependencies
- None.
