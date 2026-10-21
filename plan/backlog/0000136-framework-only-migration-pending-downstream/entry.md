---
title: "Backlog Entry: 0000136 - Framework-only migration turns pending downstream"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000136 - Framework-only migration turns pending downstream

**Source feature:** 0000035-write-gate-scope-and-path-hardening
**Source phase:** P1
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-22

---

## Problem

`planifest-framework/migrations/retroactive-release-tags.md` tags historical commits of the framework repo with Planifest release versions. It only makes sense in the framework source repo.

Under req-007 of 0000035, the file returns from `_done/` to the top level, and no downstream project holds a record for it. After a refresh, every downstream project sees it as pending. The migrator then reads the project's own `git log` for Planifest version anchors and may propose tags on unrelated commits. The human on the loop confirms each batch, so nothing tags without consent, but the prompt is noise.

0000035 has no field for a migration to say which kind of project it targets. The two downstream-only migrations have the same gap in the other direction, and this repo records them `not applicable` by hand.

## Suggested Action

Add a `**Applies to:**` header line to the migration layout, with `framework source`, `downstream`, or `all`. The migrator then writes `not applicable` on its own when the project kind doesn't match.

## Why Deferred

The confirmed 0000035 design says each scan decides downstream. A targeting field needs its own design decision on how a project knows it is the framework source.
