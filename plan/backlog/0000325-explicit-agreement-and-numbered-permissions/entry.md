---
title: "Backlog Entry: 0000325 - explicit agreement and numbered permissions"
summary: "Treat short or misspelt replies as unclear, number each permission and act only on those named, and use the host's choice tool for closed decisions."
status: "open"
---
# Backlog Entry: 0000325 - explicit agreement and numbered permissions

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31

**Suggested route:** Change Pipeline
**Related:** 0000286, 0000059

---

## Problem

Framework has no rule for reading a human reply as approval. An agent can take "Ok", "2.", or a typo such as "Ues" as consent, and act on it.

- `skills/ravintio-orchestrator/SKILL.md` has no rule about how to read a reply.
- `ravintio-framework/standards/formatting-standards.md` section 5, Choice Prompts, sets how options name the actor. It says nothing about how the agent reads the answer.

A request can also bundle several permissions, such as "push, raise the PR, and file the entries". A short "yes" then leaves unclear which permissions the human gave.

21 CFR Part 11 expects an approval to be attributable. An approval must be unambiguous before anyone can attribute it.

RAVINTIO Zero backlogs 0000259 and 0000306 cover the same gap. This entry is the conversational layer under the approval records in 0000286.

## Suggested Action

- Treat a short reply, a bare number, or a misspelt word as unclear at a gate. Ask for an explicit reply, such as "Yes, I agree to option 2".
- Number each permission in a request. Act only on the permissions the reply names.
- Use the host's choice tool for closed decisions where one exists, such as `AskUserQuestion` in Claude Code. A choice from that tool counts as explicit.
- Record the exact reply text with each approval.

## Wanted outcome

- At a gate, "Ok", "2.", and "Ues" each lead to a follow-up question, not an action.
- An agent given permissions 1 and 3 never acts on permission 2.
- Each approval record holds the reply text.

## Why Deferred

The human asked for it on 2026-10-31 after the Zero comparison review. It changes how every gate reads a reply, so it needs its own design.
