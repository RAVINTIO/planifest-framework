---
title: "Backlog Entry: 0000272 - setup manifest lists folders it did not install"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000272 - setup manifest lists folders it did not install

**Source feature:** 0000039-ravintio-rebrand
**Source phase:** P4
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-25

---

## Problem

`ravintio-framework/setup.sh` writes `.ravintio-manifest` from every folder under the tool's skills folder, at the "Write manifest listing all installed skill directories" block. That includes folders the pack didn't install, such as a person's own skill. On the next setup run, the re-run prune deletes every listed folder. So a second setup run deletes the person's own skill folder.

The 0000039 re-verification at HEAD showed this on a 0.36.0 consumer. A user folder named `my-own-skill` was deleted the same way, so the fault predates 0000039. It also makes the migration helper rewrite the manifest on a rerun after setup, because the helper's strict name rule drops some of those folders. Check whether `setup.ps1` builds its manifest the same way.

Backlog 0000255 covers a related gap: the prune trusts each listed path. This entry covers what goes into the list.

## Suggested Action

List only the folders that this setup run copied: pack skills, external skills, and capability skills. Leave out any folder that was already there and isn't one of them. Add a test that plants a user skill folder, runs setup twice, and checks that the folder survives.

## Why Deferred

Out of scope for 0000039, and older than it. It changes setup's install bookkeeping in both shells, so it needs its own design and parity tests.
