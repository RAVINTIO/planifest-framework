---
title: "Backlog Entry: 0000145 - hook commands use relative paths"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000145 - hook commands use relative paths

**Source feature:** 0000035-write-gate-scope-and-path-hardening
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-22

---

## Problem

`.claude/settings.json` runs hooks with relative paths, such as `node ".claude/hooks/enforcement/gate-write.mjs"`. Claude Code may start a hook in the session's current folder after a `cd`. If it does, the hook may not be found, or a planted copy in that folder may run instead. Nobody has checked this. It relates to 0000118, which asks whether Claude Code passes `CLAUDE_PROJECT_DIR` to hooks.

## Suggested Action

Confirm where Claude Code starts a hook after a `cd`. If it uses the current folder, anchor each hook command on `$CLAUDE_PROJECT_DIR` in `setup.sh`, `setup.ps1`, and the wiring templates.

## Why Deferred

The risk is unverified and needs a live session to check. The fix changes hook wiring for every tool, which is outside 0000035.
