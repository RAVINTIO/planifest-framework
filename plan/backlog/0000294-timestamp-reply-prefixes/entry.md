---
title: "Backlog Entry: 0000294 - put a 24-hour time before each phase prefix"
summary: "A human-requested change, filed for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000294 - put a 24-hour time before each phase prefix

**Source feature:** none (human request)
**Source phase:** none (human request)
**Deferral source:** human request
**Date filed:** 2026-10-28

---

## Problem

Every response starts with a phase prefix from the Response Prefix Convention in `ravintio-framework/skills/ravintio-orchestrator/SKILL.md`, such as `P0:` or `PC:`. The prefix carries no time. During a long run, the human can't tell when each response happened without checking git or the build log.

The human filed the same request in the `zero` repo as entry 0000257. That entry also covers the initiative stage prefixes, which this repo doesn't have.

## Suggested Action

- Put the local time in 24-hour `hh:mm` form before every phase prefix, as in `06:43 P0: ...` or `06:43 PC: ...`.
- An agent can't read the clock without a tool call. Have a UserPromptSubmit hook inject the current local time, so the agent copies it in place of guessing.
- Update the Response Prefix Convention and any hook or test that checks the prefix, so each accepts the timed form.

## Wanted outcome

Every response in a run starts with the local time in `hh:mm` form, followed by its phase prefix. Tests check these conditions:

- Any check that reads the prefix accepts `06:43 P0: x` and `06:43 PC: x`.
- That check still flags a response with neither a prefix nor a time.
- The UserPromptSubmit hook output holds the current local time in `hh:mm` form.

## Why Deferred

The human asked for it on 2026-10-28, while working in the `zero` repo. No run in this repo was active.
