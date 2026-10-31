---
title: "Backlog Entry: 0000322 - tag the release on main after merge"
summary: "Move the release tag from the feature-branch head to the merge commit on main, so the release record names the commit that shipped."
status: "open"
---
# Backlog Entry: 0000322 - tag the release on main after merge

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31

**Suggested route:** Change Pipeline
**Related:** 0000289, 0000199

---

## Problem

The release tag names a commit that never reaches `main`.

- `skills/ravintio-ship-agent/SKILL.md` Step 9 (lines 282 to 302) runs `git tag v{version}` on the feature-branch head before the PR exists.
- Step 10c pushes the tag (lines 332 and 478). If CI fix commits land, it moves the tag to the new branch head first.
- Pull requests in this repo land as squash merges in practice, for example #71 and #72. The squash creates a new commit on `main`, and the tagged branch commit stays off `main`.

On 2026-10-31, `git merge-base --is-ancestor` showed that `v0.36.0`, `v0.37.0`, and `v0.37.1` are not ancestors of `origin/main`.

A regulated release record must name the commit that shipped. Today the tag names a commit that `main` never contains.

RAVINTIO Zero fixed this in feature 0000169 (req-005 and req-006). `ravintio-zero/scripts/release-tag.mjs` runs in a `release-tag` CI job on push to `main`. It tags the merge commit with the product version, and it skips a tag that already exists.

## Suggested Action

- Stop tagging in ship Step 9. Ship records the version it expects in the PR body and the final report.
- Add a CI job that runs on push to `main`. It reads the version from `product.yml`, tags the merge commit, and pushes the tag. If the tag exists, it skips.
- Combine this with signed tags (0000289), so the CI job signs the tag it creates.
- Migrate or annotate the existing off-`main` tags.

## Wanted outcome

- Every release tag is an ancestor of `main`.
- A second push of the same version creates no tag and fails nothing.
- Ship never runs `git tag`.

## Why Deferred

The human asked for it on 2026-10-31 after the Zero comparison review. It changes the ship skill and CI, and it needs a decision on the old tags.
