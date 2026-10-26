---
title: "Backlog Entry: 0000281 - take CI/CD, test, and scanner results as gate evidence"
summary: "Gates should read results from the CI/CD pipeline and from external scanners, with provenance, instead of trusting an agent's local run or its own report."
status: "open"
---
# Backlog Entry: 0000281 - take CI/CD, test, and scanner results as gate evidence

**Source feature:** none (human request)
**Source phase:** none (human request)
**Deferral source:** human request
**Date filed:** 2026-10-26

---

## Problem

Most gate evidence today comes from the agent itself. P4 runs the checks locally and reports the result. P5 is an agent review. The ship skill's Step 10c reads `gh pr checks`, but only as pass or fail. An auditor wants evidence from the system of record, not an agent's account of it. The strategy says "an agent declaring completion is not proof of completion".

Regulated pipelines already produce machine-readable evidence that Framework ignores:

- test reports, such as JUnit XML
- coverage reports
- static analysis and security findings in SARIF
- dependency and licence results, and an SBOM in CycloneDX or SPDX
- secret scanning results, such as gitleaks
- build provenance, such as SLSA attestations

Framework also maintains its own credential scanner (0000216, 0000217, 0000253). The strategy says Framework doesn't own scanners.

## Suggested Action

Through the 0000280 adapter contract:

1. Read CI run results for the PR head commit, with run ID, URL, commit SHA, and time.
2. Parse the standard formats above into evidence records. Keep the difference between a missing check, a failed check, and a passed check.
3. Let P4 and P5 gates require named evidence from CI, set by policy. A local run stays useful for the agent's own loop, but it doesn't satisfy a gate that policy marks as CI-only.
4. Use an external secret scanner as the main path. Keep `credential-scan.mjs` as a minimal fallback when none is set.
5. Tie each evidence record to the requirement or control it supports (0000285), and export it (0000290).

## Wanted outcome

A gate summary lists each piece of evidence with its source system and link. A test proves that a gate fails or reads unknown when the CI evidence it needs is missing, even when a local run passed.

## Why Deferred

Filed from the 0000279 differentiation review. It depends on 0000280.
