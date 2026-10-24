---
title: "Backlog Entry: 0000226 - adversarial input checklist for the P1 and P2 critics"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000226 - adversarial input checklist for the P1 and P2 critics

**Source feature:** 0000037-green-ci-before-ship
**Source phase:** P6
**Deferral source:** deliberate scope decision
**Date filed:** 2026-10-24

---

## Problem

The 0000037 P5 review needed six re-reviews and two approaches. Most findings came from git and filesystem semantics that the P1 and P2 critics never probed. Examples: `git commit -- {paths}` commits working-tree content (N-09), `--pathspec-from-file` reads lines as patterns so `a*.js` also matches `ab.js` (N-12), an empty pathspec file commits the whole index, and a `:`-led name reads as magic pathspec syntax (N-16). The held-back-file rule also had no owner across P7 to P9 commits (N-01, N-07, N-08).

The design critic checks each artifact for consistency. It has no checklist for hostile or awkward input to a commit, scan, or path rule.

## Suggested Action

Add a checklist to `planifest-design-critic` and `planifest-adr-agent`. Any requirement or ADR that stages, commits, or scans paths must name its fixtures for glob names, bracket names, `:`-led names, a tracked and modified file, an empty list, and a file that moves between steps. Require the ADR author to run a short git probe for each git behaviour the decision relies on, and to record the result in the ADR.

## Why Deferred

The change edits the critic and ADR skills, which sit outside the 0000037 scope. See `plan/current/recommendations.md` row REC-002 and `plan/current/security-report.md` (re-review history).
