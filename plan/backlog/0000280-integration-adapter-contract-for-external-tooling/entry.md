---
title: "Backlog Entry: 0000280 - one adapter contract for external SDLC tooling"
summary: "Define how Framework reads from and writes to external tools, such as CI/CD, Jira, test management, and risk trackers, before building any single integration."
status: "open"
---
# Backlog Entry: 0000280 - one adapter contract for external SDLC tooling

**Source feature:** none (human request)
**Source phase:** none (human request)
**Deferral source:** human request
**Date filed:** 2026-10-26

---

## Problem

Regulated teams record their SDLC work in external tools. Framework reads none of them and writes to none of them, apart from `gh`. Entries 0000281 to 0000284 each need an integration. Built one by one, each would pick its own way to authenticate, record provenance, and handle a missing tool.

The strategy sets rules that every integration must follow:

- Credentials never enter the agent's context (boot Hard Limit 6).
- Framework uses the tool's output as evidence and doesn't replace the tool.
- A missing source reads as missing, never as a pass.
- Integrations consume exported artefacts, not private internals.

## Suggested Action

Write one adapter contract and one reference adapter before the tool-specific entries.

- **Transport:** prefer an MCP server or the tool's official CLI. The host tool holds the credential, not the agent.
- **Configuration:** declare each adapter in a repo file under `ravintio-overrides/`, with its tool, base URL, project key, and allowed operations. 0000288 protects this file.
- **Read and write modes:** read-only by default. Each write operation, such as creating an issue or posting a result, needs its own allowlist entry.
- **Provenance:** every record Framework takes in carries its source system, record ID, URL, retrieval time, and a content hash.
- **Outcomes:** an adapter returns `found`, `not found`, `unreachable`, or `not configured`. Gates treat the last three as unknown, and unknown never passes.
- **Offline fallback:** when no adapter is set, Framework keeps its local artefacts and records that the external link is absent.

Start with a GitHub adapter, since `gh` is already a dependency. Then add Jira, which most regulated teams use.

## Wanted outcome

A new integration needs only a new adapter file that meets the contract. A test proves that an unreachable or unconfigured adapter makes the gate read unknown, not pass.

## Why Deferred

Filed from the 0000279 differentiation review. The contract needs its own ADRs, covering transport, credential handling, and the outcome model.
