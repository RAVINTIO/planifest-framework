---
title: "Backlog Entry: 0000326 - report context size at each gate"
summary: "Report the context size at each phase gate, recommend /clear past about 150,000 tokens, and record the figure with the approval."
status: "open"
---
# Backlog Entry: 0000326 - report context size at each gate

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31

**Suggested route:** Change Pipeline
**Related:** 0000286

---

## Problem

A long run fills the agent's context. Past a certain size, an agent follows its instructions less closely. The human approves each gate with no view of that condition.

Framework asks for `/clear` at two points only. `skills/ravintio-orchestrator/SKILL.md`, section Context Hygiene (line 235), sets them at P0 Start Actions step -1 and after P9. No gate in between reports the context size.

RAVINTIO Zero feature 0000151 req-009 added a context size report at each gate.

An auditor who reads an approval can't tell whether the agent ran under a heavy context. A recorded figure shows the conditions behind each approval.

## Suggested Action

- At each phase gate, the agent reports its current context size in tokens, where the host exposes it.
- Past about 150,000 tokens, the agent recommends `/clear` and a resume from the plan artifacts.
- The build log records the figure with the gate result.
- If the host doesn't expose a context size, the agent says so at the gate.

## Wanted outcome

- Every gate summary shows the context size, or says the host doesn't expose one.
- Above the threshold, the gate summary recommends `/clear`.
- The build log holds one context figure for each gate.

## Why Deferred

The human asked for it on 2026-10-31 after the Zero comparison review. The threshold and how each host exposes context size need their own design.
