---
title: "Backlog Entry: 0000286 - attributable approvals and separation of duties"
summary: "Record who approved each gate, when, and against which artefact hash, and stop an author or an agent from approving its own work."
status: "open"
---
# Backlog Entry: 0000286 - attributable approvals and separation of duties

**Source feature:** none (human request)
**Source phase:** none (human request)
**Deferral source:** human request
**Date filed:** 2026-10-26

---

## Problem

Gate approvals today are chat replies. The build log records lines such as `Gate accepted: P{N}`, but an agent writes them. The line names no approver, and it doesn't bind the approval to the artefacts the approver saw. If someone edits an artefact after approval, nothing shows it.

Regulated processes also expect separation of duties. The person or agent that wrote an artefact must not approve it. Framework has maker-checker splits between agents, but none between the human who asked for a change and the human who approves it.

## Suggested Action

- Write each approval as a record with approver identity, role, time, gate, and a hash of each approved artefact.
- Take the identity from a source the agent can't forge. Options include a signed commit by the approver, a PR review, or an approval in the linked tracker (0000282).
- Let policy name which gates need which roles, and how many approvers.
- Block an approval when the approver is the artefact's author, or when the approval came from the agent.
- At each later gate, check that approved artefacts still match their hashes. A changed artefact needs fresh approval.

## Wanted outcome

Every gate approval names a human, a role, and the exact artefacts approved. A test proves that an agent-written approval line doesn't pass a gate that policy marks as needing a human.

## Why Deferred

Filed from the 0000279 differentiation review. It needs an ADR on where approval identity comes from. It also bears on 0000190, 0000244, 0000245, and 0000274.
