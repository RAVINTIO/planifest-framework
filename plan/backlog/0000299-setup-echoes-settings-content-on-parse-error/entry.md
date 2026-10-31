---
title: "Backlog Entry: 0000299 - setup echoes settings content on a JSON parse error"
summary: "setup.sh and setup.ps1 print the V8 parse error, which quotes part of the settings file, so a secret in a malformed file reaches the terminal and agent context."
status: "open"
---
# Backlog Entry: 0000299 - setup echoes settings content on a JSON parse error

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Priority:** urgent
**Suggested route:** Change Pipeline
**Related:** 0000300

---

## Context

A review of the sibling repo RAVINTIO Zero on 2026-10-31 found a fix that Zero made and Framework lacks. Framework targets regulated industries, such as those that follow GAMP 5. Hard Limit 6 says no credential may enter agent context.

## Problem

When a settings file isn't valid JSON, setup prints the parser's message:

- `readSettings` in `SETTINGS_JS_HELPERS`, `ravintio-framework/setup.sh` line 35
- the hook clean-up step, `setup.sh` line 641
- `readSettings` in `ravintio-framework/setup.ps1` line 154
- the hook clean-up step, `setup.ps1` line 693

Each line includes `e.message`. V8 quotes an excerpt of the input in that message, for example `Unexpected token 'P', "{"k": PLANTED-se"... is not valid JSON`. Settings files often hold tokens in an `env` block. If such a file is malformed, part of the secret reaches the terminal. An agent that runs setup then holds it in context, against Hard Limit 6.

## Suggested Action

- Replace each message with one fixed line that names only the file, for example `! .claude/settings.json is not valid JSON - left unchanged`.
- Add a fixture with a planted value and a test that the value never appears in setup output, for `setup.sh` and `setup.ps1`.

Zero fixed this in commit `2ac5a4e` (0000039 req-001) and commit `c5bfcaa` (0000041 ADR-003). Its fixture is `ravintio-zero/tests/fixtures/0000039-setup-hardening/invalid-settings.json`.

## Wanted outcome

No setup error message quotes the content of a user file.

## Why Deferred

The human asked for it on 2026-10-31. It changes `setup.sh` and `setup.ps1`, which are enforcement paths, so it needs the Change Pipeline.
