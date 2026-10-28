---
title: "Backlog Entry: 0000290 - export evidence in the shared RAVINTIO schemas"
summary: "Write requirements, policy, execution state, and evidence as versioned JSON, so RAVINTIO Accept, RAVINTIO Insight, and auditors can read a run without parsing Markdown."
status: "open"
---
# Backlog Entry: 0000290 - export evidence in the shared RAVINTIO schemas

**Source feature:** none (human request)
**Source phase:** none (human request)
**Deferral source:** human request
**Date filed:** 2026-10-26

---

## Problem

A run's record lives in Markdown under `plan/_archive/`. Another tool must parse prose to read it. The strategy proposes shared, versioned artefacts that every RAVINTIO product can use:

- `requirements`: stable IDs, criteria, scope, and constraints
- `policy`: version, gates, authorities, and exceptions
- `execution-state`: objective, progress, decisions, and next action
- `evidence`: source, check, outcome, time, and provenance

RAVINTIO Accept must verify a change against its requirements and evidence. It can't do that from Framework's output today. `ravintio-framework/schemas/` holds only `domain-document.schema.json` and `shared.schema.json`.

## Suggested Action

- Draft JSON schemas for the four artefacts. Version them, and keep them in a form Zero can also use. Don't build a mandatory shared runtime.
- At P7, write the exports next to the archive. Each evidence record keeps the outcome as `passed`, `failed`, or `missing`.
- Include control links (0000285), approvals (0000286), waivers (0000287), and external record links (0000281 to 0000284).
- Add a test that validates every export against its schema.

## Wanted outcome

Every archived run holds schema-valid exports that another tool can read without the Markdown. A test proves an export fails validation when a required field is missing.

## Why Deferred

Filed from the 0000279 differentiation review. It answers open question 1 in the strategy, whether Zero and Framework share a contract package or only compatible schemas.
