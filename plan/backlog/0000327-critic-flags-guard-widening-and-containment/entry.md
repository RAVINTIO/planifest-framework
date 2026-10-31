---
title: "Backlog Entry: 0000327 - critic flags guard widening and missing containment"
summary: "Have the design critic and P1 spec flag any change that widens what a hook or guard allows, require separate approval for each, and add containment criteria for new write, delete, or git-ref paths at P1."
status: "open"
---
# Backlog Entry: 0000327 - critic flags guard widening and missing containment

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31

**Suggested route:** Change Pipeline
**Related:** 0000226, 0000288

---

## Problem

Nothing stops a spec from weakening a guard without anyone noticing. `skills/ravintio-design-critic/SKILL.md` has no check for a change that widens what a hook or guard allows. `skills/ravintio-security-agent/SKILL.md` runs a STRIDE review at P5, after the code exists.

RAVINTIO Zero shows both risks:

- **Guard widening.** Zero retro 0000195 (line 32) records a draft entry that widened a fail-closed guard. The human caught it at review. Zero archived feature `0000252-chart-rules` now requires a separate approval for each widening.
- **Late containment.** Zero builds 0000040 to 0000043, 0000151, and 0000160 added new write, delete, or git-ref paths. Each found missing containment or input validation only at security review.

A regulated change to a control needs its own approval and a record of what changed.

## Suggested Action

- The design critic and the P1 spec flag any change that widens what a hook or guard allows. The flag names the guard and lists each new form it would accept.
- The human approves each widening separately at the P1 gate. A blanket approval of the spec doesn't cover it.
- Any new write, delete, or git-ref path gets acceptance criteria for containment and input validation at P1.
- When a feature removes a human stop, a threat review runs at P1 or P2, before P3 Codegen.

## Wanted outcome

- The critic report lists each guard widening by name, with its new forms.
- The P1 gate records a separate approval for each widening.
- Every new write, delete, or git-ref path in a spec has a containment criterion.
- A feature that removes a human stop has a threat review before P3.

## Why Deferred

The human asked for it on 2026-10-31 after the Zero comparison review. It changes the critic, the spec agent, and the P1 gate, so it needs its own run.
