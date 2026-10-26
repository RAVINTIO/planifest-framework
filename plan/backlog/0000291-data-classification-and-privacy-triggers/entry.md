---
title: "Backlog Entry: 0000291 - data classification and privacy triggers"
summary: "At P0 and P1, classify the data a change touches, and require a privacy impact step when it handles personal or regulated data."
status: "open"
---
# Backlog Entry: 0000291 - data classification and privacy triggers

**Source feature:** none (human request)
**Source phase:** none (human request)
**Deferral source:** human request
**Date filed:** 2026-10-26

---

## Problem

Framework enforces data ownership by component (boot Hard Limit 5), but it never asks what kind of data a change handles. A change that touches personal, health, payment, or other regulated data follows the same path as one that doesn't. Laws such as the GDPR require a data protection impact assessment for some processing. The P5 security review doesn't ask whether one exists.

## Suggested Action

- Let the organisation supply data classes in policy, such as public, internal, confidential, personal, and special category.
- At P0, record the classes each affected component holds. At P1, tag each requirement that reads, writes, or moves classified data.
- When policy says a class needs a privacy impact assessment, P1 records a link to it, or the run stops. Framework never writes the assessment's conclusion.
- Give the P5 security review the classes, so it checks retention, redaction, logging of personal data, and cross-border transfer.
- Let the component manifest record the data classes each component owns.

## Wanted outcome

Every run records the data classes it touches. A test proves that a run touching a class that needs an assessment stops when no assessment link exists.

## Why Deferred

Filed from the 0000279 differentiation review. It needs a P0 decision on where classes live and which classes stop a run by default.
