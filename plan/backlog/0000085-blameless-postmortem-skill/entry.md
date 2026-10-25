---
title: "Backlog Entry: 0000085 - Add a blameless postmortem skill with 5 whys and CAPA"
summary: "A pipeline skill that turns a failed deploy, CI run, or escaped defect into a root cause and filed corrective, preventive, and detective actions."
status: "open"
---
# Backlog Entry: 0000085 - Add a blameless postmortem skill with 5 whys and CAPA

**Source feature:** the `ovelunor` product's `0000043-mock-contact-endpoint` run (a downstream consumer of this framework)
**Source phase:** P9
**Deferral source:** human request
**Date filed:** 2026-10-11

---

## Problem

The pipeline fixes a failure and moves on. Nothing asks why the earlier phases let it through, so the same class of failure returns.

In `ovelunor` 0000043, P9 needed three SIT deploys:

1. The build stopped on a Hugo deprecation. The deploy builds with `--panicOnWarning`, but the P3 test built without it, so P4 passed.
2. The next deploy went live, and then its new post-deploy check failed. The check made one attempt before the new Worker reached every edge.

The build-assessment agent at P8 reports efficiency, not failure causes. The validate agent's self-corrections fix symptoms and record no root cause.

## Proposed change

Add a `ravintio-postmortem` skill:

- **Trigger:** any P4 self-correction that a P3 test should have caught, any failed deploy, CI failure, rollback, or escaped defect, or a human request.
- **Method:** blameless rules, a timeline with evidence, and 5 whys that stop at a gap in a process, check, standard, or tool, not a person or agent.
- **Output:** CAPA, with corrective, preventive, and detective actions. Each action names its owner, where it lives, its status, and what verifies it.
- **Filing:** each action goes to the product backlog, the product's instructions, or the framework backlog.
- **Record:** `plan/postmortems/`, outside `plan/current/`, so it survives P7.

Also:

- Have the orchestrator invoke it under continuous runs, after the failure is fixed and before the P9 report.
- Have P8's build report list the run's postmortems.

`ovelunor`'s version, at `ravintio-overrides/capability-skills/blameless-postmortem/SKILL.md` in that repository, is a starting point.

## Related

- `gate-write` blocks `ravintio-overrides/` once P7 removes the sentinel, so a product can't install a capability skill after a run without a design. 0000077 covers governance lapsing after P7.
- 0000084: `gate-write` also blocked this entry's write to the framework repository.
