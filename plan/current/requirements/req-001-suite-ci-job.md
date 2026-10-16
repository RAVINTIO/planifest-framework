---
title: "Requirement: req-001 - suite-ci-job"
summary: "CI runs the framework test suite on Linux and macOS."
status: "active"
version: "0.1.0"
---
# Requirement: req-001 - suite-ci-job

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000031-ci-test-and-powershell-coverage
**Source:** US-001
**Priority:** must-have

## User Story

As the human on the loop, I see CI fail a pull request when `run-tests.sh` fails on Linux or macOS, so that a broken suite can't merge.

## Functional Requirements
- `.github/workflows/planifest.yml` has a job that runs `bash planifest-framework/tests/run-tests.sh` from the repository root.
- The job runs as a matrix over `ubuntu-latest` and `macos-latest`, with `strategy.fail-fast: false`.
- The job fails when `run-tests.sh` exits non-zero.
- The job sets `permissions: contents: read`, uses no secrets, and sets `timeout-minutes: 10`.
- The job runs on the same `pull_request` trigger as the existing jobs.
- The consumer copy at `planifest-framework/hooks/planifest.yml` stays unchanged.

## Acceptance Criteria
- [ ] On a pull request to `main`, the suite job runs on `ubuntu-latest` and on `macos-latest`.
- [ ] If `run-tests.sh` exits non-zero, that matrix leg fails, and the other leg still runs to completion.
- [ ] Both legs pass on this feature's pull request, each in under 10 minutes.
- [ ] `planifest-framework/hooks/planifest.yml` has no diff against `main`.

## Dependencies
- REQ-002 for readable failure output. REQ-001 works without it.
