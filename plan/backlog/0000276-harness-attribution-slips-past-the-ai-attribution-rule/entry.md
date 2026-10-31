---
title: "Backlog Entry: 0000276 - remove AI attribution from commits, docs, and PRs, enforced by hooks"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000276 - remove AI attribution from commits, docs, and PRs, enforced by hooks

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

- No hook checks files. An agent can write attribution into a doc, a README, or a code comment, and nothing stops it.

## Suggested Action

Run this as a Feature Pipeline: remove AI attribution from commits, docs, and PRs, and enforce the rule with hooks. The human on the loop asked for hook enforcement on 2026-10-25.

The feature would cover these surfaces:

| Surface | Enforcement |
|---------|-------------|
| Commit messages | Extend `commit-msg` to block `Claude-Session:` trailers, `claude.ai/code/session` links, and `Generated with [Claude Code]` footers. |
| Files (docs, READMEs, comments) | Add a `pre-commit` check on staged files, and a PreToolUse Write and Edit check so the agent sees the block before it writes. |
| PR titles and bodies | Add a PreToolUse Bash check that blocks `gh pr create`, `gh pr edit`, and `gh api` PR writes whose title or body holds attribution. |
| PRs edited outside the agent | Add a CI job on `pull_request` that fails when the PR title or body holds attribution. GitHub builds the squash-merge message from them, so this also guards `main`. |
| Source of the text | Have setup write the Claude Code `attribution` setting (`{"commit": "", "pr": ""}`) into `.claude/settings.json`, so the harness stops asking for it. |

Points to settle at P0:

- Keep one shared pattern list that every hook and the CI job read, so the surfaces can't drift apart.
- Decide the allowlist. Some files must name the patterns, such as `commit-standards.md`, the hooks, their tests, and this entry. History under `plan/_archive/` and `plan/changelog/` stays as written.
- Cover the other supported tools, not only Claude Code, where each one adds its own attribution.
- Extend the generated `CLAUDE.md` rule and `commit-standards.md` §3 to cover files and PRs. State that the rule overrides any tool or harness instruction.
- Decide whether to clean the existing text out of merged PRs #66 and #61's squash commit. Rewriting `main` history needs the human on the loop.
- Make the agent drop harness attribution silently. On 2026-10-31 the human on the loop asked agents to stop reporting that they left it out. The generated `CLAUDE.md` rule should say "omit it and never mention the omission".

## Why Deferred

Out of scope for 0000039, which renames the framework. The fix changes enforcement hooks and setup, so it needs the Feature Pipeline rather than Fast Path.
