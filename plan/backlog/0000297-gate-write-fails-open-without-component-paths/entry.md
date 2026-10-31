---
title: "Backlog Entry: 0000297 - gate-write fails open when design.md has no component paths"
summary: "An unparseable or unreadable design.md lets every write through, including writes to enforcement paths such as .claude/settings.local.json."
status: "open"
---
# Backlog Entry: 0000297 - gate-write fails open when design.md has no component paths

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Priority:** urgent
**Suggested route:** Change Pipeline
**Related:** 0000288, 0000179, 0000119

---

## Context

A review of the sibling repo RAVINTIO Zero on 2026-10-31 compared its write gate with Framework's. Framework targets regulated industries, such as those that follow GAMP 5. In that setting, an agent must never switch off its own controls.

## Problem

`evaluateWrite` in `ravintio-framework/hooks/enforcement/path-rules.mjs` fails open in two design states:

- **Unparseable design.** At line 897, `extractComponentPaths` returns `null` when `plan/current/design.md` has no parseable `## Component Paths` list. Line 898 then returns `{ allowed: true, warning }`.
- **Unreadable design.** At line 895, `design.kind === "unreadable"` returns `{ allowed: true }`, following 0000003 ADR-005.

`isEnforcementPath` runs only inside `scopeVerdict` (line 728), which is the route for a missing, non-regular, or oversize design. Neither fail-open state reaches it. So with any design present but unparseable, the agent can write every path on `FAST_PATH_ENFORCEMENT_PATHS`:

- `.claude/settings.local.json`, whose `disableAllHooks` key switches off every hook
- `ravintio-framework/hooks/` and `**/hooks/enforcement/`
- `ravintio-framework/scripts/`, `setup.sh`, and `setup.ps1`

One malformed heading in `design.md` is enough to open all of these.

## Suggested Action

- Check `isEnforcementPath` in `evaluateWrite` before the component-path check, so it applies in every design state.
- Under a regulated profile, block writes when the design is unparseable or unreadable, and say why. Keep the current warning only outside that profile, if at all.
- Add a test: with a `design.md` that has no `## Component Paths` section, a write to `.claude/settings.local.json` is blocked.
- Add a matching test for an unreadable `design.md`.

## Wanted outcome

No design state lets an agent write an enforcement path. A regulated install never fails open on a design it can't read.

## Open questions

- Should a parsed design that lists an enforcement path as a component path still admit it? This repo's own components cover `ravintio-framework/`, so the answer affects the pack's own work.

## Why Deferred

The human asked for it on 2026-10-31. It changes an enforcement hook, so it needs the Change Pipeline and its review.
