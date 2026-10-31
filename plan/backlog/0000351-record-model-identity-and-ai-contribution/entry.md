---
title: "Backlog Entry: 0000351 - record model identity and AI contribution"
summary: "Record the exact model ID, provider, and agent role behind each artefact, and which records a human wrote, in the evidence trail rather than in commits."
status: "open"
---
# Backlog Entry: 0000351 - record model identity and AI contribution

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31

**Suggested route:** Change Pipeline
**Related:** 0000289, 0000276, 0000290, 0000344

---

## Problem

The build log records only a model tier for each agent. It doesn't name the exact model, the provider, or the role the agent played. It also doesn't mark which records a human wrote.

A regulated audit may need AI contribution on record. These sources ask for it:

- EU AI Act Article 4 literacy evidence
- computer software assurance (CSA) tool records
- ISO 27001 A.8.30, for outsourced development

## Suggested Action

- For each artefact, record the exact model ID, the provider, and the agent role, such as test-writer or design critic.
- Mark each record a human wrote, such as a gate approval or a waiver.
- Keep these records in the evidence trail, alongside the audit trail in 0000289.
- Keep AI attribution out of commit messages and PRs. That stays consistent with the `commit-msg` hook and with 0000276.
- Add the records to the evidence export (0000290).

## Wanted outcome

For any artefact in a run, a reader can name the model and role that wrote it, or the human who did. Tests check these conditions:

- The build log names an exact model ID for each dispatched agent.
- No commit message or PR body carries AI attribution.

## Why Deferred

Filed from the Zero comparison review on 2026-10-31. It needs a decision on where the records live, and it depends on 0000289.
