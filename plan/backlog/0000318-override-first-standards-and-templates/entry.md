---
title: "Backlog Entry: 0000318 - override-first standards and templates"
summary: "Resolve ravintio-overrides/standards/ and ravintio-overrides/templates/ before the pack copy, so organisations can use their own SOP templates without relaxing an enforced rule."
status: "open"
---
# Backlog Entry: 0000318 - override-first standards and templates

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31

**Suggested route:** Feature Pipeline
**Related:** 0000285, 0000288, 0000348

---

## Problem

A regulated organisation writes its controlled documents to its own SOP templates. Framework gives it no supported way to use them. Agents read standards and templates from `ravintio-framework/` only.

Library standards are the one exception. `ravintio-codegen-agent` and `ravintio-validate-agent` check `ravintio-overrides/library-standards/{language}/prefer-avoid.md` before the pack copy. No other standard or template works this way.

An organisation that edits the pack copy loses its changes on the next pack update. It also leaves no record of what it changed.

RAVINTIO Zero backlog 0000305 plans override-first lookup for the same reason.

## Suggested Action

- Resolve `ravintio-overrides/standards/{file}` and `ravintio-overrides/templates/{file}` before the pack copy, wherever a skill or setup reads one.
- Let a constraint override only tighten a gate. An override may add a check or raise a threshold. It may not remove a check or lower one.
- Never let an override relax a rule that a hook enforces. The hook reads the pack rule, so an override can't weaken it.
- Log each override in use at P0, so the run records which documents it followed.
- Leave out Zero's archetype catalogue. It ships bundled content, and Framework ships no bundled third-party content.

## Wanted outcome

- A template in `ravintio-overrides/templates/` replaces the pack template for every agent that reads it.
- An override that tries to relax a hook-enforced rule has no effect, and P0 reports it.
- P0 lists each override the run uses.

## Why Deferred

The human asked for it on 2026-10-31 after the Zero comparison review. It needs a design for the tighten-only rule and for how P0 detects a relaxing override.
