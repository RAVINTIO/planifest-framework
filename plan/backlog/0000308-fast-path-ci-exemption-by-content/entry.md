---
title: "Backlog Entry: 0000308 - grant the Fast Path CI exemption by content, not commit subject"
summary: "Pre-push and CI exempt any branch whose commit subjects all start fix(fast-path):. CI should judge the changed paths instead."
status: "open"
---
# Backlog Entry: 0000308 - grant the Fast Path CI exemption by content, not commit subject

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Change Pipeline. `hooks/ravintio.yml` is an enforcement path, so Fast Path can't make this change.
**Related:** 0000288, 0000298

---

## Context

A review of RAVINTIO Zero on 2026-10-31 compared how each pack checks a branch before merge. In Framework, a commit subject alone decides which check a branch gets. Anyone who writes the subject can choose the weaker check.

## Problem

- **Exemption by subject.** The pre-push hook exempts a branch when every commit subject starts `fix(fast-path):` (`hooks/pre-push` lines 16 to 32). The consumer CI template does the same (`hooks/ravintio.yml` lines 20 to 33).
- **Weak exempt check.** An exempt branch needs only a `component.yml` or a `plan/changelog/` file in its diff. Neither check looks at which paths changed or how many.
- **No enforcement list in CI.** `hooks/enforcement/path-rules.mjs` defines `FAST_PATH_ENFORCEMENT_PATHS`, which Fast Path may never touch. Neither pre-push nor CI reads it. A branch that edits a hook under a `fix(fast-path):` subject passes both checks.
- **Advisory pre-commit.** The pre-commit hook warns but always exits 0 (`hooks/pre-commit` line 16).
- **Presence checks only.** Every check tests whether a file exists in the diff. None tests whether the file's content matches the change.

## Suggested Action

- In CI, decide the Fast Path exemption from the diff, not the commit subjects.
- Fail an exempt branch that touches any path on the enforcement list.
- Re-check the Fast Path criteria by path class, for example file count and whether the change touches `src/`, contracts, or schema.
- Share the enforcement list with CI from one source, so the hook and CI can't drift apart.
- Make the same change in `hooks/pre-push`, as a local early warning.

## Wanted outcome

A commit subject can't buy a weaker check. Tests check these conditions:

- A `fix(fast-path):` branch that edits a file under `hooks/enforcement/` fails CI.
- A `fix(fast-path):` branch that breaks a Fast Path criterion fails CI.
- A branch that meets every criterion passes, whatever its commit subjects say.

## Why Deferred

The human asked for it on 2026-10-31 after the Zero comparison review. It changes an enforcement path and the consumer CI template.
