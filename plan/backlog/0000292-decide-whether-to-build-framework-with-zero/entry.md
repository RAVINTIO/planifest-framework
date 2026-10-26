---
title: "Backlog Entry: 0000292 - decide whether to build RAVINTIO Framework with RAVINTIO Zero"
summary: "The human on the loop is weighing Zero as the build tool for this repository. Trial it on one bounded change, and test Framework on separate consumer repositories."
status: "open"
---
# Backlog Entry: 0000292 - decide whether to build RAVINTIO Framework with RAVINTIO Zero

**Source feature:** none (human request)
**Source phase:** none (human request)
**Deferral source:** human request
**Date filed:** 2026-10-26

---

## Problem

This repository builds Framework with Framework. The human on the loop is weighing a switch to Zero, raised during the 0000279 differentiation review.

Reasons for the switch:

- Most open entries harden hooks, setup, and CI. Framework's full pipeline is more ceremony than that work needs. Zero's question, "How can we build this with minimal ceremony?", fits it.
- Framework enforces itself while it changes itself. Its hooks gate edits to its own enforcement files, and its migrations run against its own source (0000136, 0000180). A separate build tool removes that loop.
- Recent features started in Zero and reached Framework as ports, such as 0000244, 0000263, and 0000268.

Reasons against:

- Building with Framework is the main source of evidence about Framework. P8 build reports, loop-precision data (0000048), and token measurements (0000234) all come from runs in this repository.
- The governance features in 0000279 need a run to prove them. Without Framework runs here, only consumer projects such as `ovelunor` would exercise them.
- Both packs use the same layout. Each installs `CLAUDE.md`, `plan/` with `backlog/`, `_archive/`, and `changelog/`, `ravintio-overrides/`, and hooks in `.claude/settings.json`. Installed side by side, they would compete for the boot file, the hooks, and the backlog ID sequence.
- `ravintio-framework/` here is both the product source and the installed pack. Under Zero, it would become source only, and the repository would need another way to test an install.

## Suggested Action

Treat it as a decision with a trial, not a switch:

1. Separate product from tooling. Test Framework by installing it into fixture or consumer repositories, rather than relying on this repository's own install. That also matches what users have.
2. Trial Zero on one bounded change, such as a batch of setup or Windows CI entries. Compare it with a similar past Framework run on time, tokens, rework, and defects found after merge.
3. Keep at least one real Framework run per release on a consumer repository. Use it for the governance features in 0000279 and for P8 evidence.
4. Before installing Zero here, decide which pack owns `CLAUDE.md`, the hooks, and the backlog sequence. Migrate this repository's history if Zero takes over.
5. Record the decision as an ADR, whatever the trial shows.

## Wanted outcome

A recorded decision, based on one measured trial, on which tool builds this repository. Framework still gets at least one real run per release, wherever it runs.

## Why Deferred

The human on the loop raised the idea and said it may or may not be a good one. It changes how the repository builds itself, so it needs a decision before any setup change.
