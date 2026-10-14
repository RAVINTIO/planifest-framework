---
title: "Backlog Entry: 0000084 - gate-write blocks paths outside the repository, with no visible reason"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000084 - gate-write blocks paths outside the repository, with no visible reason

**Source feature:** the `ovelunor` product's `0000037-go-live` run (a downstream consumer of this framework)
**Source phase:** after the run's archive, before the next P0
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-10

---

## Problem

`planifest-framework/hooks/enforcement/gate-write.mjs` blocked an Edit to Claude Code's auto-memory file, `~/.claude/projects/<project>/memory/cloudflare-account-state.md`. That file sits outside the repository. Two faults combined.

### 1. A path outside the working directory falls through to the design check

When the target isn't under `cwd`, `relTarget` becomes the raw absolute path. It matches no always-permitted prefix. With no `plan/current/design.md`, the hook exits 2. With a design, the path still matches no component and the hook blocks. The hook governs `src/`, so a path outside the repository should pass.

### 2. The block reason never reaches the agent

The hook writes its reason to stdout and exits 2. Claude Code reads a PreToolUse hook's block reason from stderr, so the agent saw only `No stderr output`. It had to read the hook's source to learn why.

## Suggested Action

1. Exit 0 when the resolved target is outside `cwd`.
2. Write every block reason to stderr, in this hook and its siblings.
3. Add tests for an absolute path outside the repository, with and without a design.

## Why Deferred

The fix belongs in the framework repository, not the product's run.
