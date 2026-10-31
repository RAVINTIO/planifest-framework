---
title: "Backlog Entry: 0000357 - control what data the agent sends to the model provider"
summary: "Record and limit what enters the agent's context, because every ISO 27001 auditor asks what leaves the network."
status: "open"
---
# Backlog Entry: 0000357 - control what data the agent sends to the model provider

**Source feature:** none (human request)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Feature Pipeline
**Related:** 0000291, 0000344, 0000345, 0000351, 0000356

---

## Problem

Everything the agent reads goes to the model provider. That covers source code, test fixtures, logs, and any file the agent opens. Framework sets no rule on what may enter the agent's context. Hard Limit 6 covers credentials only.

An ISO 27001 auditor asks first what data leaves the network through an AI coding tool. The relevant controls include Annex A 5.23 (cloud services), 5.34 (privacy and personal data), and 8.12 (data leakage prevention). 0000291 classifies data in the built system, not data that leaves through the agent. 0000345 assesses how the provider handles data but doesn't limit what Framework sends.

## Suggested Action

- At P0, record a data statement in `design.md`. It states what classes of data the agent may read for this feature.
- Add exclusion rules for sensitive paths in `ravintio-overrides/`, such as production data extracts or customer fixtures. A hook blocks the agent's reads of excluded paths, as `gate-write` blocks writes.
- Record the provider, its data retention terms, and whether it trains on inputs, with a link to the 0000345 assessment.
- Flag personal data in test fixtures at P1, with a pointer to 0000291.

## Wanted outcome

- Every run records what data classes the agent could read.
- A read of an excluded path fails, and a test proves it.
- The evidence export (0000290) includes the data statement and provider terms.

## Open questions

- Can every supported tool block reads, or only Claude Code?
- Should the default exclusion list ship empty or with common patterns such as `*.env` and `*.pem`?

## Why Deferred

The owner asked about ISO 27001 on 2026-10-31, and this was the one gap no filed entry covers. It needs its own design.
