---
title: "Backlog Entry: 0000260 - Rename the GitHub repo and update origin after merge"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000260 - Rename the GitHub repo and update origin after merge

> Path: `plan/backlog/0000260-rename-github-repo-after-merge/entry.md`

**Source feature:** 0000039-ravintio-rebrand
**Source phase:** P6
**Deferral source:** deliberate scope decision
**Date filed:** 2026-10-25

---

## Problem

Feature 0000039 points every repo link at `github.com/RAVINTIO/ravintio-framework`. The repo still carries the old name, so those links do not resolve until the rename runs. The local `origin` remote also still points at the old URL.

## Suggested Action

After the human on the loop merges the PR, run `gh repo rename ravintio-framework`. Then run `git remote set-url origin` with the new URL. Check that the links in `README.md` and `docs/` resolve. Report any failure.

## Why Deferred

The rename needs the merged PR first, and only the human on the loop merges. See the Deferred section of `plan/current/scope.md` for feature 0000039.
