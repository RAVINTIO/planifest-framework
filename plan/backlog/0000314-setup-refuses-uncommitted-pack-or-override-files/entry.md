---
title: "Backlog Entry: 0000314 - setup refuses uncommitted pack or override files"
summary: "Setup fails, copying nothing, when the pack folder or ravintio-overrides/ holds uncommitted changes."
status: "open"
---
# Backlog Entry: 0000314 - setup refuses uncommitted pack or override files

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Change Pipeline. `setup.sh` and `setup.ps1` are enforcement paths, so Fast Path can't make this change.
**Related:** 0000288, 0000302

---

## Context

A review of RAVINTIO Zero on 2026-10-31 compared what each pack's setup copies. Framework is a tool that agents use in validated work. Change control over that tool means only reviewed, versioned configuration reaches the agent.

## Problem

- `setup.sh` copies whatever sits in `ravintio-framework/` and `ravintio-overrides/`, committed or not.
- Setup uses git only to set `core.hooksPath` (`setup.sh` line 748). It never checks for uncommitted files.
- An unreviewed edit to a hook, skill, or override then reaches the agent's tool folder with no record. `setup.ps1` has the same gap.

## Zero's design

Zero backlog 0000299 (`zero/plan/backlog/0000299-setup-blocks-uncommitted-pack/entry.md`) proposes this check:

- Before setup copies anything, it runs `git status --porcelain` on the pack folder and `ravintio-overrides/`.
- If either holds modified, staged, or untracked files, setup fails, lists each file, and copies nothing.
- The check has no bypass flag. A commit or a discard is the only way past it.
- Setup skips files that git ignores.

## Suggested Action

- Add the same check to `setup.sh` and `setup.ps1`, before any copy.
- Give it no bypass flag.
- Decide at pickup how setup behaves outside a git repository. Zero's entry proposes a failure with a clear message.
- Have the getting-started guide say to commit the pack before the first setup run.

## Wanted outcome

Setup installs only committed pack and override files. Tests check these conditions:

- An uncommitted change under `ravintio-framework/` makes setup fail, name the file, and copy nothing.
- An untracked file under `ravintio-overrides/` does the same.
- An ignored file doesn't block setup.
- Both scripts behave the same way.

## Why Deferred

The human asked for it on 2026-10-31 after the Zero comparison review. It changes both setup scripts, which are enforcement paths.
