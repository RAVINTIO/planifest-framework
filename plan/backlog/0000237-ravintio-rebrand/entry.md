---
title: "Backlog Entry: 0000237 - Rename to RAVINTIO Framework"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future discovery run."
status: "open"
---
# Backlog Entry: 0000237 - Rename to RAVINTIO Framework

**Source feature:** none (human request)
**Source phase:** none (human request)
**Deferral source:** human request
**Date filed:** 2026-10-24

---

## Problem

The GitHub org is now `RAVINTIO`, and the ecosystem names this product RAVINTIO Framework. This repo still uses Planifest everywhere: the `planifest-framework/` pack, `planifest-overrides/`, the `planifest-*` skills, `PLANIFEST_*` variables, marker files, prose, and the repo name `planifest-framework`.

## Suggested Action

Rename as RAVINTIO Zero did. Prose uses RAVINTIO in block capitals, identifiers use lowercase `ravintio`. Ship a consumer migration that moves the old pack to a backup instead of deleting it. Bump the major version. After merge, run `gh repo rename ravintio-framework`.

## Reference

RAVINTIO Zero did the same rename in feature 0000160 (v1.0.0, PR #25 in `RAVINTIO/ravintio-zero`). Its ADRs and build report are in `plan/_archive/0000160-ravintio-rebrand-2026-10-24/` in that repo. Lessons from that run:

- Protect history ids, sibling repo names, and split literals such as `"planifest""-framework"` from the bulk replace.
- Leave `plan/_archive/`, `plan/changelog/`, and applied migrations as written.
- Add a brand guard test with a path and line allowlist.
- Run the Bash suites under Bash 5 or in CI. macOS Bash 3.2 hides lines from `done < <(grep ...)` loops.
