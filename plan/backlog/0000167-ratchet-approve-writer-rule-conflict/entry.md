---
title: "Backlog Entry: 0000167 - ratchet-approve-writer-rule-conflict"
summary: "The boot template says agents must never write .ratchet-approve, but the loop runner and 0000017 ADR 001 let an agent write it on explicit human instruction."
status: "open"
---
# Backlog Entry: 0000167 - ratchet-approve-writer-rule-conflict

**Source feature:** 0000036-pipeline-friction-and-gate-fixes
**Source phase:** P2
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-22

---

## Problem

Two framework texts give opposite rules for who may write `plan/current/.ratchet-approve`:

- `ravintio-framework/templates/standard-boot.md:32` and the root `CLAUDE.md:32` say the line must be human-written and that "Agents must never write that marker."
- `ravintio-framework/skills/ravintio-loop-runner/SKILL.md:19` lets an agent write it on explicit, in-the-moment instruction from the human on the loop. That rule follows 0000017 ADR 001, which amended 0000016 ADR 004.

`docs/decisions-index.md` records 0000017 ADR 001 as accepted. The boot text still states the older 0000016 ADR 004 rule. An agent that reads only the boot file refuses an instruction the loop runner allows. An agent that reads only the loop runner may write a marker that the boot file forbids.

0000036 req-007 repeats the boot wording ("Agents never write that marker"). 0000036 ADR-011 cites 0000017 ADR 001 instead.

## Suggested Action

Decide which rule stands, then align the boot templates and the loop runner with it. If 0000017 ADR 001 stands, reword the boot bullet to "written by the human on the loop, or by an agent on their explicit instruction".

## Why Deferred

The boot ratchet bullet is outside 0000036's scope. Changing who may write the marker is a security decision that needs its own ADR, not a text fix inside stream 03.
