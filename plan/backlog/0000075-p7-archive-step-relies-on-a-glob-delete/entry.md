---
title: "Backlog Entry: 0000075 - P7 archive step relies on a glob delete that Claude Code blocks"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000075 - P7 archive step relies on a glob delete that Claude Code blocks

**Source feature:** discovered during the `ovelunor` product's `0000016-ads-in-one-switch` ship (a downstream consumer of this framework)
**Source phase:** P7
**Deferral source:** process defect
**Date filed:** 2026-10-03

---

## Problem

The ship agent's P7 Step 6 archives `plan/current/` by copy, then delete. It tells the agent to delete the folder's contents, including dotfiles. The natural command is a glob removal such as `rm -rf plan/current/* plan/current/.[!.]*`.

Claude Code's built-in safety check refused that command. It cannot resolve a relative glob after a `cd`, so it treats the removal as possibly unbounded. Only a person can approve it, and in an unattended or continuous run nobody does. The whole compound command failed, so nothing in it ran, including the copy that came before the delete.

The agent recovered by archiving with `git mv` per named item and `git rm` for the sentinels. That worked, but the skill gave no such path, so the recovery depended on the agent improvising.

## Suggested Action

Rewrite Step 6 so it needs no glob delete:

- Archive with `git mv plan/current/<item> plan/_archive/<dir>/<item>` for each tracked item, which moves without deleting.
- Remove the sentinels with `git rm` on their explicit paths.
- Delete any untracked leftovers by explicit path only, never by glob.
- Keep each step a separate command, so a refused step does not take the earlier ones with it.

Consider a small script in `planifest-framework/scripts/` that performs the archive and prints what it moved.

## Why Deferred

Filed from a downstream product's session. The fix belongs in the framework's ship-agent skill.
