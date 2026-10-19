---
name: planifest-loop-runner
description: Canonical loop mechanics for every pipeline loop: state file conventions, stop rules, escalation format, toggle protocol. Loaded by any phase agent entering a loop.
bundle_templates: [loop-state.template.md, loop-toggles.template.yml]
bundle_standards: []
hooks:
  phase: orchestrator
---

# Planifest - loop-runner

> You define how every loop in the pipeline behaves. Loops iterate; you make sure they iterate *boundedly*, *observably*, and *recoverably*. Any skill that loops (P0 completeness, design-critic, reversal protocol, verify-by-execution, cross-model review, P4 validate) loads this skill for its mechanics and defines only its own rubric and pass condition.

---

## Hard Limits

1. **Every loop has an armed stop rule before its first iteration.** No cap, no loop.
2. **Agents write `plan/current/.ratchet-approve` only on explicit human instruction, never on their own initiative.** The human must state the path, the reason, and the go-ahead in the same turn (0000017 ADR-001, superseding ADR-004's blanket prohibition). The line format is `path | reason | timestamp` with the human's exact reason text transcribed verbatim; note that a reason containing a `|` character invalidates the line (strict 3-field parse, fails closed). The write is committed immediately, in its own dedicated commit, before any further work proceeds: the hook's same-uncommitted-changeset backstop blocks the guarded edit with an explicit message if this step is skipped. Writing the marker without that explicit in-the-moment instruction remains a violation, not a workaround.
3. **Budget counters are never reset by an agent.** They live in the loop-state file, are git-tracked, and survive interrupt/resume (ADR-007). The `autonomous` approach counter is a budget counter too (0000033 ADR-005).
4. **Run-log records are append-only.** Never rewrite a prior iteration's record.

## Toggle Protocol (ADR-003)

Before arming any loop, read `planifest-overrides/loop-toggles.yml` (see `templates/loop-toggles.template.yml`):

- Absent file, absent key, or unreadable/invalid value → the loop is **off**. Emit a one-line warning only for an invalid value on a known key.
- `report-only` → run the loop, write findings/verdicts, block nothing, mutate nothing.
- `on` → verdicts gate progression per the owning skill's rules.

**`autonomous` default (0000033 ADR-004):** when the run mode is `autonomous`, an absent key reads as **on** for five keys:

- `design_critic`
- `verify_by_execution`
- `cross_model_review`
- `reversal_protocol`
- `parallel_streams`

An explicit value in `planifest-overrides/loop-toggles.yml` wins over the default. Outside `autonomous`, an absent key still reads as **off**, so behaviour doesn't change. `p0_completeness` keeps its default in every mode.

**Checker keys in `autonomous`:** an explicit `off` or `report-only` for `design_critic`, `reversal_protocol`, `verify_by_execution`, or `cross_model_review` blocks the `autonomous` choice at P0. P0 names the key and recommends removing it or setting `on`. `parallel_streams` stays free to set. See `standards/autonomous-run-standards.md` (Gates as loops).

**Toggle record:** at P1 start, the orchestrator writes every resolved toggle and its source to the P1 build-log block. The source is `file value`, `autonomous default`, or `absent default`.

**`parallel_streams` resolution (0000033 ADR-013):** this key is a dispatch setting, not a loop. It arms no loop-state file and no stop rule. It resolves in this order:

1. An explicit `on` or `off` wins in every run mode.
2. An absent file or absent key reads as `on` when `plan/.run-mode` reads `autonomous`, per the rule above. In other modes it reads as `off`.
3. Any other value, `report-only` included, reads as `off` with a one-line warning.

The framework never creates `planifest-overrides/loop-toggles.yml`; enabling a loop is always a deliberate human act.

## Loop State (per instance)

Create `plan/current/loop-state-{loop-id}.md` from `templates/loop-state.template.md` when the loop arms. Update and **commit after every iteration**: the state file is how an interrupted session resumes mid-loop (`Px: Resuming…` convention), and how budget counters survive resume.

While any loop-state file has `status: active`, the `ratchet-check.mjs` hook is armed for `plan/current/` artifact writes. Set `status: done` or `status: escalated` when the loop exits; never leave a dead loop armed.

## The Iteration Cycle

```
while state.status == active:
  1. ACT      : do one bounded unit of loop work (one critique pass, one fix, one verification)
  2. OBSERVE  : collect the evidence (findings, check output, observed behaviour)
  3. RECORD   : append one run-log record: action, observation, decision
  4. DECIDE   : continue | done | escalate | change-approach, per the stop rules below
```

One iteration = one record. Doing three passes and logging one record is a defect.

## Stop Rules

Armed on every loop, checked at every DECIDE:

| Rule | Trigger | Action |
|------|---------|--------|
| Pass | The owning skill's pass condition is met | `done`: set state, disarm |
| Iteration cap | iteration == cap (default **3**; P4 validate keeps its existing **5**; a skill may declare its own) | `escalate` |
| no-progress | The same gap/finding survives **2 consecutive iterations** without measurable change | `escalate`: do not spend the remaining cap restating the problem |
| Budget | The relevant budget counter (e.g. reversal budget 2/feature) is exhausted | `escalate`: always to the human, regardless of run mode |

In `autonomous`, the iteration cap and no-progress rules decide `change-approach` while the approach count is below 3. At the third approach's cap, they decide `escalate`. The table rows stay as they are for `interactive` and `continuous`. See `standards/autonomous-run-standards.md` (Changing approach).

Caps and budgets are enforced by orchestrator control flow reading the state file, not by this text (ADR-007).

## Escalation Format

On `escalate`, populate the state file's Escalation Context section (stop rule hit, outstanding finding, attempts summary, recommended next step) and emit:

```
Px: Blocked ({loop-id}): {one-line outstanding finding}
Escalation context: plan/current/loop-state-{loop-id}.md
```

In `autonomous`, write the escalation as an `Exception waiting` build-log line instead, then carry on with independent work. The `Px: Blocked` line stays for `interactive` and `continuous`.
