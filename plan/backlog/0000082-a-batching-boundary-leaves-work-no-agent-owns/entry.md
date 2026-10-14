---
title: "Backlog Entry: 0000082 - A batching boundary leaves work no agent owns"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000082 - A batching boundary leaves work no agent owns

**Source feature:** the `ovelunor` product's 0000007-mastheads-in-motion
**Source phase:** P6
**Deferral source:** deliberate scope decision
**Date filed:** 2026-09-23
**Moved:** from the `ovelunor` product's backlog entry 0000109 on 2026-10-10, because the fix belongs in this framework

---

## Problem

Three consecutive features have produced work that no agent owned, and each time
the seam sat between two parallel batches.

- Feature 0000005 needed four orchestrator fixes after the run.
- Feature 0000006 shipped four masthead faces applied to no rule. The full suite
  stayed green. A browser found it.
- Feature 0000007 pulled in backlog 0000105 to add the missing assertion, and
  raised R-005 in `plan/current/risk-register.md` because its own wave 1 and
  wave 2 split creates a third boundary of the same shape.

Backlog 0000105 fixed one instance. It added a font-usage gate. It did not
change how the orchestrator decides what to batch, so the next boundary between
two batches is still unowned by design.

Backlog 0000105's own text names the underlying question and leaves it open:
whether the orchestrator should stop batching purely by file ownership.

## Suggested Action

Give one agent the rules that join one batch's output to another's, rather than
leaving the seam to neither. An alternative is a post-batch reconciliation step
that asserts every artifact one batch declares is consumed by something another
batch produces.

Whatever the mechanism, the test is this: would it have caught 0000006's four
unused faces without a human opening a browser?

## Why Deferred

It changes orchestrator behaviour across every feature, so it needs its own
design decision. Feature 0000007 mitigated the symptom inside its own run by
giving every wave 1 item a requirement id. That mitigation does not generalise.
