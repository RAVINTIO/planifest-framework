---
title: "Backlog Entry: 0000118 - verify hook assumptions in a live Claude Code session"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000118 - verify hook assumptions in a live Claude Code session

**Source feature:** 0000032-governance-continuity-and-write-gate-scope
**Source phase:** P6
**Deferral source:** tech debt
**Date filed:** 2026-10-17

---

## Problem

0000032 rests on three assumptions about Claude Code that no test has checked against a live session. Every hook suite feeds JSON to the hook on stdin, so none of them shows what Claude Code itself does.

- A-001: Claude Code shows a PreToolUse block reason from stderr when a hook exits 2. If this is wrong, req-007 fixes nothing for Claude Code.
- A-002: Claude Code passes the Bash command as `tool_input.command`. If this is wrong, `shell-write-guard.mjs` never sees a command and always passes.
- A-003 (execution plan numbering): the root walk starts at `CLAUDE_PROJECT_DIR`. The hooks assume Claude Code sets that variable for hook processes. If it doesn't, a session that changes folder falls back to the `cwd` walk.

The 0000032 security report lists A-001 to A-003 as open because they can't be tested offline. The risk register uses A-003 for a different assumption (gitignored markers), so check both meanings at pickup.

## Suggested Action

After re-running setup at 0.31.0, start a Claude Code session in a project with no `design.md`. Try a **Write** and a Bash write to `src/`, and record what the agent sees. Then repeat from a subfolder with `CLAUDE_PROJECT_DIR` set and unset. Record the results in the risk register and close or reopen each assumption.

## Why Deferred

The check needs a live Claude Code session, which the pipeline's test suites can't drive. See the Tech Debt table in the 0000032 `recommendations.md` and the Risk Register Cross-Check in its `security-report.md`.
