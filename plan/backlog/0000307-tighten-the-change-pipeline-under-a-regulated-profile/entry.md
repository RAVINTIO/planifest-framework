---
title: "Backlog Entry: 0000307 - tighten the Change Pipeline under a regulated profile"
summary: "Under a regulated profile, give the Change Pipeline a security review, a fresh-context checker, human review before archive, and no new components."
status: "open"
---
# Backlog Entry: 0000307 - tighten the Change Pipeline under a regulated profile

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Feature Pipeline
**Related:** 0000286, 0000348

---

## Context

A review of RAVINTIO Zero on 2026-10-31 compared how each pack controls smaller changes. Framework targets regulated work, such as GAMP 5. In that setting, every change to a validated system needs proportionate controls. The Change Pipeline gives a change fewer controls than the Feature Pipeline, but its route still admits wide changes.

## Problem

The Change Pipeline takes on more scope than its controls cover.

- **Wide routing.** The orchestrator routing table sends three kinds of work to the Change Pipeline (`skills/ravintio-orchestrator/SKILL.md` lines 184 to 186). These are a fix to one or two components, a new component, and fewer than three new user stories.
- **New components built inline.** The change-agent scaffolds a new component itself and doesn't hand off to codegen (`skills/ravintio-change-agent/SKILL.md` lines 109 to 113). It escalates only above three user stories or for new stack choices.
- **No security review.** The change-agent runs Domain Context, Targeted Change, Validate, ADR and Migration Check, Update Documentation, and Archive. None of these is a P5 security review.
- **No fresh-context checker.** The same agent writes the change, validates it, and judges it complete. No design critic or reviewer with a fresh context checks its work.
- **Archive before review.** The change-agent's Phase 6 archives `plan/current/` (`skills/ravintio-change-agent/SKILL.md` lines 93 to 103). The workflow then lists human review as a later step (`workflows/change-pipeline.md` lines 35 to 39). The human therefore reviews work that the agent has already filed as complete.

## Suggested Action

Under a regulated profile (0000348), make these changes:

- Require a P5 security review for every Change Pipeline run.
- Require a fresh-context checker, such as the design critic or a separate reviewer subagent, before the human sees the change.
- Move human review ahead of the archive step. Archive only after the human accepts the change, and record that acceptance as an attributable approval (0000286).
- Route any change that adds a component to the Feature Pipeline.

Outside a profile, the current behaviour can stay as it is.

## Wanted outcome

Under a regulated profile, a Change Pipeline run can't skip security review or independent checking. Tests check these conditions:

- The change-agent runs a P5 security review and a fresh-context check under the profile.
- The archive step refuses to run until a recorded human acceptance exists.
- The orchestrator routes a request for a new component to the Feature Pipeline under the profile.

## Why Deferred

The human asked for it on 2026-10-31 after the Zero comparison review. It changes routing and phase order, so it needs its own design.
