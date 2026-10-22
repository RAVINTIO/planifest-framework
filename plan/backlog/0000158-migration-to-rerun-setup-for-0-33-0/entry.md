---
title: "Backlog Entry: 0000158 - Migration to re-run setup for 0.33.0"
summary: "0.33.0 changes installed hooks and both boot templates, but no migration tells a downstream project to re-run setup."
status: "open"
---
# Backlog Entry: 0000158 - Migration to re-run setup for 0.33.0

**Source feature:** 0000035-write-gate-scope-and-path-hardening
**Source phase:** P6
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-22

---

## Problem

Feature 0000035 changes files that reach a project only through a setup run:

- `planifest-framework/hooks/enforcement/path-rules.mjs`, `gate-write.mjs`, `ratchet-check.mjs`, and `shell-write-guard.mjs`
- the `Sanctioned scripts:` sentence in `planifest-framework/templates/standard-boot.md` and `cursor-boot.md`

Boot files are build outputs (0000029 ADR-001), and installed hooks are copies. A downstream project that updates `planifest-framework/` keeps its old hooks and its old Hard Limit 8 text until it re-runs setup. Its ship agent then runs `set-product-release.mjs` at P7 under a boot file that doesn't sanction it.

The 0.31.0 release handled the same gap with `planifest-framework/migrations/migrate-0.31.0-rerun-setup-for-shell-write-guard.md`. No 0.33.0 migration exists, and `planifest-framework/standards/framework-update-policy.md` doesn't mention setup. This repo's own `CLAUDE.md` also lacks the sentence, which req-008 accepts until the next setup run.

## Suggested Action

Add a 0.33.0 migration that tells a downstream project to re-run setup, following the 0.31.0 migration. Or add a general rule to `framework-update-policy.md` that every framework update re-runs setup.

## Why Deferred

The P6 docs agent found the gap during drift checks. A new migration is a framework change outside the P6 docs scope, and 0000035 req-008 covers only the templates.
