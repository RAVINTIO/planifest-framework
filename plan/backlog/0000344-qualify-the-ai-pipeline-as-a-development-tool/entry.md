---
title: "Backlog Entry: 0000344 - qualify the AI pipeline as a development tool"
summary: "An intended-use statement, LLM failure-mode risk assessment, pinned model and Framework versions, and a qualification pack built from the test suite."
status: "open"
---
# Backlog Entry: 0000344 - qualify the AI pipeline as a development tool

**Source feature:** none (GAMP 5 gap analysis)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Feature Pipeline
**Related:** 0000119, 0000180, 0000289, 0000317, 0000351

---

## Problem

A regulated company must justify every tool that builds or tests a GxP system. Auditors ask first for the tool's intended use. Framework offers no intended-use statement and no risk assessment of itself or of the agent.

Model identity drifts too. `ravintio-framework/standards/agent-dispatch-standards.md` picks models by tier alias, such as `sonnet` or `haiku`. No artefact records the exact model ID or Framework version that produced it.

`ravintio-framework/tests/` holds a wide suite, but nobody has packaged it as qualification evidence. Known limits, such as the shell guard heuristic in 0000119, appear only in backlog entries.

## Suggested Action

- Write an intended-use statement for Framework and the agent. Start it early, because auditors ask for it first.
- Write a risk assessment that lists known LLM failure modes and the control that answers each. Examples include invented APIs, skipped steps, and estimated timestamps.
- Base the approach on these sources, and check each against the source text at pickup:
  - GAMP 5 Appendix D9 on tools
  - ISO 13485 clause 4.1.6 on QMS software validation
  - FDA Computer Software Assurance guidance
- Pin the model ID and Framework version, and record both on each artefact. 0000351 carries the record format.
- Package `ravintio-framework/tests/` as a qualification pack with a known limitations list.
- Require requalification when the model, tool, or Framework major version changes.

Framework supplies qualification evidence. The regulated company's quality unit decides whether the tool is fit for its intended use.

## Wanted outcome

- A reader finds the intended-use statement and risk assessment at fixed paths in the pack.
- Every artefact names the model ID and Framework version that wrote it.
- A version change flags the qualification pack as stale until someone reruns it.

## Open questions

- How does setup provenance in 0000180 feed the pack?
- Can the audit trail in 0000289 serve as the run record for qualification?

## Why Deferred

The human asked for the GAMP 5 gap analysis findings to reach the backlog. It needs its own design and links to five open entries.
