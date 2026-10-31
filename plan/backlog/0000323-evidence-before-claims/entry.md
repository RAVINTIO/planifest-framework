---
title: "Backlog Entry: 0000323 - evidence before claims"
summary: "Check PATH before claiming a tool is missing, list the commands behind each claim, and mark docs-only claims unverified so they never count as verified."
status: "open"
---
# Backlog Entry: 0000323 - evidence before claims

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31

**Suggested route:** Change Pipeline
**Related:** 0000118, 0000101

---

## Problem

Agents can report a fact they never checked, and the gate accepts it.

- `skills/ravintio-verify-by-execution/SKILL.md` (lines 36 to 40) offers three outcomes: `verified`, `failed`, and `not-verifiable`. None of them marks a claim drawn from docs alone.
- Neither that skill nor `ravintio-validate-agent` tells the agent to check `PATH` before it says a program is missing.

RAVINTIO Zero hit both failures. Zero retro 0000217 records two at step 12:

- The step reported no Codex program, but `/opt/homebrew/bin/codex` existed.
- The step said a hook was active in Codex, based on the docs alone.

Zero retro 0000195 records a similar docs-only claim. Zero fixed this in archived feature `0000249-check-path-before-missing-claims`.

A regulated record must rest on evidence. A claim with no command behind it isn't evidence.

## Suggested Action

- Before an agent claims a tool is missing, it runs `command -v` and checks common install folders, such as `/opt/homebrew/bin` and `/usr/local/bin`.
- Each claim in a verification report lists the commands that support it.
- A claim drawn only from docs gets the tag `unverified (docs only)`. That tag never counts as `verified`.
- The P4 gate summary names each unverified and `not-verifiable` claim.
- At P0, the agent checks each claim in a backlog entry against the code before it writes the brief. Zero builds 0000185 and 0000196 found entry claims that the code didn't support.

## Wanted outcome

- `ravintio-verify-by-execution` lists `unverified (docs only)` as a fourth outcome, and the gate never passes it as verified.
- A "missing program" claim with no `command -v` result fails review.
- P0 reports any backlog claim that the code contradicts.

## Why Deferred

The human asked for it on 2026-10-31 after the Zero comparison review. It changes the verification outcomes, which several skills share.
