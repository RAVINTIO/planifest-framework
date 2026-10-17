---
title: "ADR 003: Blocking context clear after P9"
summary: "After P9 the orchestrator asks for /clear or a new session and refuses new work in the same session. The auto-trigger hook tells the next session no run is active and to triage first. Handover notes route every next step through a track."
status: "accepted"
version: "0.1.0"
---
# ADR-003 - Blocking context clear after P9

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000032-governance-continuity-and-write-gate-scope
**Component:** planifest-framework
**Date:** 2026-10-17

## Context

0000015 ADR-002 chose an advisory message after P9. Ship Step 12 recommends a new session with a `⚡` line and says "do not block". That ADR argued a block adds friction and can be bypassed.

Backlog 0000077 shows the cost of that choice. A downstream run finished P9 and then took new work in the same session. The agent cut a new branch and committed plan changes with no triage, P0, sentinel, `discovery.md`, or build log. A P9 handover note had said the next code change needed no P0. The note also pointed to a runbook that pushed straight to `main`.

Under ADR-002 the sentinel is gone once the P9 marker step commits. The auto-trigger hook then fires on the next prompt. Its current message claims the orchestrator "has not been loaded yet", which is false mid-session, so the agent learns to ignore it.

At P0 the human on the loop confirmed a blocking Step 12. The build log records this under "P0 exchange (post-P9 context)".

## Decision

- **Ship Step 12:** The step asks the human on the loop to run `/clear` or the host tool's equivalent, or to start a new session. If a new request arrives in the same session, the orchestrator refuses that work and repeats the request. It starts no triage, P0, or edit for the new request in that session. The step drops "do not block" and the `⚡` line.
- **Orchestrator Context Hygiene:** The Phase 9 clear point matches Step 12. If the host has no programmatic context clear, the orchestrator still refuses new work until the human on the loop confirms a cleared context or a new session.
- **Routing Directive:** Every request is triaged before any action, including every request after P9, whether or not a run is active.
- **Auto-trigger hook:** With `planifest-framework/` present and no sentinel, the message says these things:
  - No Planifest run is active.
  - The agent loads the `planifest-orchestrator` skill before it responds.
  - The agent triages the request as Fast Path, Change Pipeline, or Feature Pipeline before acting.

  The message no longer claims the skill isn't loaded. The hook still never exits 2.
- **Handover notes:** A ship Hard Limit requires any P9 handover note, next-steps list, or runbook pointer to route each next step through a track. The note never says a code change needs no P0, and never points to a runbook that pushes to `main`. If the Step 11 confirmation lists next steps, each names its track.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Keep 0000015 ADR-002's advisory message | No friction for a human who wants to continue | Backlog 0000077 shows agents take new work after P9 with no triage | The failure it allowed has now happened downstream |
| Keep the sentinel after P9 so hooks keep gating | Hooks enforce instead of skill text | The run never ends, and the next run inherits a stale sentinel | Conflicts with ADR-002's deletion before the tag |
| Fix only the hook message, with no Step 12 block | Smallest change | The message reaches only the next prompt, and the agent can still act in a full context | Leaves the same-session path open |
| Block only Feature Pipeline work after P9 | Allows small fixes to continue | The agent decides the track itself, and the downstream run skipped triage entirely | A partial block still lets work skip triage |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | Ship Step 12 becomes blocking and gains a handover-note Hard Limit. The orchestrator's Context Hygiene, Phase 9, and Routing Directive sections change. `auto-trigger-orchestrator.mjs` changes its message. A new suite covers the hook and both skills. |

## Consequences

**Positive:**
- Work after P9 starts in a clean context and goes through triage.
- The auto-trigger message is true in every state, so the agent has no reason to ignore it.
- Handover notes no longer route code changes around the pipeline.

**Negative:**
- A human on the loop who wants to continue must clear context or open a new session first.
- The block lives in skill text. A human can still re-prompt past it, which is the bypass 0000015 ADR-002 named.

**Risks:**
- An agent with a long context may drop the Step 12 rule. The auto-trigger message in the next session is the backstop.
- Hosts without a `/clear` equivalent depend on the human confirming a new session.

## Related ADRs

- ADR-002 - depends-on. The sentinel is absent after the P9 marker step, so the hook message "no run is active" holds.
- 0000009 ADR-003 (auto-trigger hook plus fallback) - related-to. Only the message text changes.
- ADR-001 - related-to

## Supersedes

- 0000015 ADR-002 (new session recommendation, not block)

## Superseded By

- None
