---
title: "Backlog Entry: 0000079 - consistency-check cannot resolve an archived ADR"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000079 - consistency-check cannot resolve an archived ADR

**Source feature:** the `ovelunor` product's 0000005-launch-readiness
**Source phase:** P1
**Deferral source:** discovered mid-flight
**Date filed:** 2026-09-20
**Moved:** from the `ovelunor` product's backlog entry 0000104 on 2026-10-10, because the fix belongs in this framework

---

## Problem

`ravintio-framework/scripts/consistency-check.mjs` resolves an `ADR-nnn` reference only against
`plan/current/adr/`. Every ADR from a shipped feature lives in `plan/_archive/{feature}/adr/`, so
any artifact citing an inherited decision is reported as referencing an ADR that does not exist.

Feature 0000005's P1 artifacts drew 13 such findings for ADR-004, ADR-013, ADR-019, ADR-022,
ADR-025, ADR-026, and ADR-030. All seven exist and are accepted. Feature 0000004 cited ADR-004
through ADR-016 the same way, so this has been firing since at least that run.

The effect is not cosmetic. A non-zero exit is an automatic REJECT for the design critic, so a
correct artifact set is rejected on a false signal, and a real finding has to be picked out of the
noise by hand.

## Suggested Action

Build the known-ADR set from `plan/current/adr/` and every `plan/_archive/*/adr/` directory, so an
inherited decision resolves. Keep reporting a reference that resolves nowhere, because that is the
fault the check exists to catch.

While there, consider whether the three-acceptance-criteria cap should stay a hard finding. Every
feature since 0000001 has exceeded it, 0000004's requirements ran to four, five, and six criteria
and shipped, and the cap has never once been treated as binding. Either the cap earns enforcement
or it should warn rather than fail.

## Why Deferred

Feature 0000005 is about launching the magazine, not about the framework's own tooling. The false
findings were identified and set aside by hand for this run, with the reasoning recorded in the
P1 build log block.
