---
title: "Backlog Entry: 0000078 - Upgrade continuous run to human-on-the-loop"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000078 - Upgrade continuous run to human-on-the-loop

**Source feature:** reported by the human from the `ovelunor` product (a downstream consumer of this framework), after its `0000036-nav-popular-categories` run
**Source phase:** P1 to P9
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-10

---

## Problem

The framework's `continuous` run mode only skips the per-phase confirmation at P1 to P6. The human is still in the loop at many other points. The `ovelunor` product has run P1 to P9 with no human interaction since 2026-10-04, through repo overrides. The framework should own that mode as a loop engineering feature, rather than each product patching around it.

### What `continuous` leaves in place

These points still wait for the human, or tell the agent to:

- The orchestrator's P7 gate is "always a confirmation stop", and `continuous_run: true` doesn't bypass it.
- The ship skill's P9 Step 10 asks whether the agent or the human pushes and raises the PR.
- The validate skill halts after 5 self-correct cycles and escalates to the human.
- `planifest-loop-runner`'s stop rules escalate to the human on the iteration cap and on no-progress.
- The codegen skill escalates to the human after 3 failed TDD attempts on one requirement.
- The Scope Lock Challenge needs a separate accept, edit, or reject per scenario path.
- Every phase skill says "one question at a time" and recommend-then-confirm, with no rule for a run in which the human isn't present.

### How `ovelunor` overrides it today

The product's `planifest-overrides/instructions/` holds these overrides:

| Override | What it does |
|----------|--------------|
| `autonomous-after-p0.md` | The human is available before and after a run, not during it. No phase gate stops. A failed check loops until it passes, and an escalation limit is a reason to change approach, not to stop. The agent makes every decision, records it in the build log, and updates the artifact it touches. A fix that would change scope takes the option closest to the design's intent and records a deviation. One report at the end of P9 |
| `p0-ask-only-real-forks.md` | P0 asks only questions that need judgement or change what gets built. Everything derivable goes into the design draft for one confirmation |
| `deploy-to-sit-at-p9.md` | P9 deploys to the candidate environment, records the version, then pushes and raises the PR without asking |
| `suggest-a-push-for-every-local-commit.md` | Any commit after the PR is pushed straight away |
| `contact-form-checks.md` | A check that needs a human input (a captcha) runs to that point, and the input is requested in the final report |
| `give-full-urls-for-review.md` | Pages for the human to review are listed as full links |

This works, but it fights the framework text at each point listed above. The agent has to weigh the override against the skill every time, and a fresh session can resolve the conflict the wrong way.

## Suggested Action

Upgrade `continuous` to a full loop engineering mode in which the human is on the loop rather than in it. The human sets intent at P0 and reviews outcomes after P9. Between the two, the human can watch and interrupt, but no gate waits for them.

1. **Run mode.** Add a mode, for example `autonomous`, that P0 records in `plan/.run-mode`. Keep `continuous` and `interactive` as they are.
2. **P0 front-loads every human dependency.** Ask every real fork together, and settle anything a later phase will need from the human, such as a credential, an account action, or a publisher run. Confirm the design, the Scope Lock batch, and the run mode in one turn.
3. **Gates become loops.** In this mode, no phase gate stops. Each gate's pass condition runs as a loop under `planifest-loop-runner`, with a fresh-context checker in place of the human:
   - The design critic at P1 and P2.
   - Verify-by-execution at P4.
   - The cross-model reviewer at the end of P6.
4. **Escalation changes approach, not ownership.** When a loop reaches its cap or makes no progress, the agent records the attempts and tries a different approach. It escalates to the human only for an exception in step 5.
5. **A declared exception list.** Only these wait for the human, and each product can extend the list in an override:
   - A rule the framework marks for human approval, such as a schema migration or a destructive operation. The agent writes the proposal, finishes every piece of work that doesn't depend on it, and raises it in the final report.
   - A gross deviation: a change that alters the confirmed problem, users, or scope, as opposed to a deviation that keeps the design's intent. The framework needs a rubric for "gross". The reversal protocol's *altering* classification is a starting point.
   - Human review of the running result, such as a website review on the candidate environment after implementation. The agent lists every page as a full link.
   - Promotion beyond the candidate environment, such as UAT or Production deploys.
   - A human-only input, such as a captcha. The agent runs the check to that point and asks in the final report.
   - An exhausted budget that cannot be worked around, such as the reversal budget.
6. **Decisions are recorded, not asked.** Every decision the agent makes without the human goes in the build log. It also goes in the requirement, ADR, or design it touches. Deviations carry a severity.
7. **P9 ships without asking.** It deploys to the candidate environment, pushes, and raises the PR. Any commit after the PR is pushed straight away. The human merges, which is the on-the-loop control point.
8. **One report.** The run ends with one report covering:
   - What shipped.
   - Every decision and deviation.
   - The candidate version.
   - The PR and its CI result.
   - Every exception waiting for the human.
9. **On-the-loop visibility.** The human can follow a run without being asked anything. Options: a short progress line per phase in the build log, a push notification at P9 and on any exception, and a status the human can query mid-run.
10. **Telemetry and assessment.** Count human touchpoints per run, so the P8 build report can flag a run that stopped for something outside the exception list.

## Why Deferred

Filed from a downstream product's session. The change touches the orchestrator, `planifest-loop-runner`, the validate, codegen, and ship skills, and the run-mode contract, so it needs its own design. Backlog 0000076 (P0 asks too many questions) and 0000077 (governance lapses after P7) overlap with steps 2 and 8 and should be considered alongside it.
