---
title: "Backlog Entry: 0000311 - set read-only token permissions in the consumer CI template"
summary: "hooks/ravintio.yml sets no permissions, so consumer repos run it with the default GITHUB_TOKEN scope."
status: "open"
---
# Backlog Entry: 0000311 - set read-only token permissions in the consumer CI template

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Change Pipeline. `hooks/ravintio.yml` is an enforcement path, so Fast Path can't make this change.
**Related:** 0000276

---

## Context

A review of RAVINTIO Zero on 2026-10-31 compared the CI workflows each pack installs in consumer repos. Least privilege for CI tokens is a common control in regulated settings.

## Problem

- `hooks/ravintio.yml` sets no `permissions:` key. Consumer repos therefore run it with their default `GITHUB_TOKEN` permissions. Depending on repo and organisation settings, those can include write access.
- Framework's own workflow, `.github/workflows/ravintio.yml`, sets `permissions: contents: read` on each job. The template doesn't follow the pack's own practice.
- Zero commit d759b95 (feature 0000169) set top-level `permissions: contents: read` in Zero's consumer template.

## Suggested Action

- Add a top-level `permissions: contents: read` to `hooks/ravintio.yml`.
- If a later job needs more, grant it on that job alone and say why in a comment.
- Add a test that fails if the template loses the top-level key.

## Wanted outcome

The consumer template never runs with more than read access by default. Tests check these conditions:

- `hooks/ravintio.yml` has a top-level `permissions:` key set to `contents: read`.
- Any job-level grant beyond read carries a comment that gives the reason.

## Why Deferred

The human asked for it on 2026-10-31 after the Zero comparison review. It changes an enforcement path.
