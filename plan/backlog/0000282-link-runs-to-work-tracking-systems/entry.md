---
title: "Backlog Entry: 0000282 - link runs to work-tracking and change-record systems"
summary: "Read the feature brief and stories from tools such as Jira or Azure Boards, tie requirement IDs to issue keys, and record the run against the organisation's change ticket."
status: "open"
---
# Backlog Entry: 0000282 - link runs to work-tracking and change-record systems

**Source feature:** none (human request)
**Source phase:** none (human request)
**Deferral source:** human request
**Date filed:** 2026-10-26

---

## Problem

Regulated teams record SDLC work in a tracker such as Jira, Azure Boards, Linear, or GitHub Issues. Changes to controlled systems also need a change record, such as a ServiceNow change request or a change advisory board (CAB) approval. Framework keeps its work only in `plan/`. Auditors can't follow a line from an issue to a requirement, a commit, a test, and a release without someone copying the links by hand.

## Suggested Action

Through the 0000280 adapter contract:

1. **Intake at P0:** read an epic or story by its key and draft the feature brief from it. Record the key in `discovery.md` and in `design.md`.
2. **Traceability:** let each requirement name its source issue key. The consistency check reports a requirement with no source when policy requires one.
3. **Change record:** before P9, check that a linked change record exists and is approved, when policy requires one. If it isn't approved, stop and record why. Framework never approves a change record.
4. **Write-back (opt-in):** when the allowlist permits it, post links to the PR, the tag, and the evidence export (0000290) on the issue. Move the issue's status only when policy names the transition.
5. **Commit and PR links:** put the issue key in the PR title or body in the form the tracker's development panel reads.

## Wanted outcome

From one Jira issue, a reader can reach the requirements, ADRs, PR, tag, and evidence for that change. A test proves that P9 stops when policy requires an approved change record and the adapter reports none.

## Why Deferred

Filed from the 0000279 differentiation review. It depends on 0000280.
