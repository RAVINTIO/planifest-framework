---
title: "Backlog Entry: 0000288 - protect policy configuration from agent changes"
summary: "An agent can edit ravintio-overrides/loop-toggles.yml and other override files, so it can switch off its own gates. Policy changes need a protected path and an approval record."
status: "open"
---
# Backlog Entry: 0000288 - protect policy configuration from agent changes

**Source feature:** none (human request)
**Source phase:** none (human request)
**Deferral source:** human request
**Date filed:** 2026-10-26

---

## Problem

Framework reads its gate policy from repo files:

- `ravintio-overrides/loop-toggles.yml` turns the design critic, the cross-model review, and other loops on or off.
- `ravintio-overrides/instructions/` holds standing overrides, such as push permission.

Neither path is on `FAST_PATH_ENFORCEMENT_PATHS` in `ravintio-framework/hooks/enforcement/path-rules.mjs` (checked on 2026-10-26). `gate-write` permits writes outside `src/`. So an agent can weaken its own gates, and the only trace is a diff a reviewer may miss.

The strategy lists "trusted policy configuration, with protected changes" as a minimum control. It also says the implementation agent must not quietly weaken its own acceptance policy.

## Suggested Action

- Gather policy into named files: toggles, run-mode limits, approval roles (0000286), control catalogue (0000285), and adapter allowlists (0000280).
- Add those paths to the enforcement list, so `gate-write` blocks agent writes to them.
- Let a policy change land only with a human approval record, in the same way `.ratchet-approve` works.
- At P0, record a hash of the policy in force. Each gate checks it again. A change mid-run stops the run.
- Suggest a `CODEOWNERS` entry for the policy files in consumer repos.

## Wanted outcome

An agent can't change gate policy without a human approval record. A test proves that `gate-write` blocks an agent write to `ravintio-overrides/loop-toggles.yml`.

## Why Deferred

Filed from the 0000279 differentiation review. It touches the enforcement list, so it takes the Change or Feature Pipeline.
