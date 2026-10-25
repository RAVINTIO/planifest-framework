---
title: "Backlog Entry: 0000276 - harness attribution slips past the AI attribution rule"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000276 - harness attribution slips past the AI attribution rule

**Source feature:** 0000039-ravintio-rebrand
**Source phase:** P9
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-25

---

## Problem

AI attribution has come back in PR descriptions and in one commit. The earlier fix still stands. Feature 0000025 (ADR-001, from old backlog 0000039) turned off the ship-agent PR footer by default, and `ravintio-ship-agent/SKILL.md` still omits it.

The new source is the Claude Code harness. Its system prompt tells the agent to end each commit message with `Co-Authored-By: Claude ...` and a `Claude-Session:` link. It also tells the agent to end each PR description with `🤖 Generated with [Claude Code](...)` and a session link. The agent sometimes follows the harness over `CLAUDE.md`.

Evidence:

- PRs #66, #67, and #69 end with the `Generated with [Claude Code]` footer and a `claude.ai/code/session_...` link. PR #66 merged.
- On 2026-10-25 the human on the loop removed the same footer and session link from PR #71 by hand. They said: "Neither is needed or wanted. I pay for Claude and it has no write to market itself via our repository or frameworks."
- Commit 5c7859a9 on `main` (the squash merge of PR #61) carries a `Claude-Session:` trailer.

The rule has these gaps:

- `ravintio-framework/hooks/commit-msg` blocks `Co-Authored-By: ... Claude` but not a `Claude-Session:` trailer or a `claude.ai/code/session` link.
- `ravintio-framework/hooks/commit-msg` doesn't see a squash-merge message, because GitHub writes it on the server.
- Nothing checks PR descriptions. The ship skill omits its own footer but doesn't strip a footer the harness adds.
- `CLAUDE.md` and `commit-standards.md` §3 name commit messages only. Neither says the rule overrides a harness instruction or covers PR text.

## Suggested Action

1. Extend `commit-msg` to block `Claude-Session:` trailers and `claude.ai/code/session` links.
2. Extend the generated `CLAUDE.md` rule and `commit-standards.md` §3 to cover PR titles and descriptions. State that the rule overrides any tool or harness attribution instruction.
3. Add a ship-agent step that checks the PR body for attribution before `gh pr create` and `gh pr edit`.
4. Consider documenting the Claude Code `attribution` setting in `.claude/settings.json`, so setup can turn the harness text off at source.

## Why Deferred

Out of scope for 0000039, which renames the framework. The fix touches an enforcement hook, so it needs the Change or Feature Pipeline rather than Fast Path.
