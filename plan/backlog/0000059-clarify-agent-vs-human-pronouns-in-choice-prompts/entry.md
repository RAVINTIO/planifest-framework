---
title: "Backlog Entry: 0000059 - clarify agent-vs-human pronouns in choice prompts"
summary: "ravintio-ship-agent's P9 Step 10 push/PR decision options mix first-person framing inconsistently ('I push + create the PR' for the agent's own action vs 'Give me the PR title and description' addressing the human) — confusing at a glance about who does what."
status: "open"
---
# Backlog Entry: 0000059 - clarify agent-vs-human pronouns in choice prompts

**Source feature:** 0000027-backlog-batch-governance-tooling-fixes
**Source phase:** P9
**Deferral source:** discovered mid-flight
**Date filed:** 2026-08-08

---

## Problem

Rendering `ravintio-ship-agent/SKILL.md`'s Step 10 push/PR decision (`plan/current/design.md`-confirmed wording: "Should I push the branch and raise the PR, or will you do it yourself?") as a two-option choice surfaced a pronoun-consistency defect visible to the human: option 1 reads "I push + create the PR" (first-person from the agent's perspective, describing the agent's own action), while option 2 reads "Give me the PR title and description" (an imperative addressed to the agent, implying "me" = the agent, but requiring the reader to flip perspective mid-sentence from option 1's framing). Read together, a human has to work out which "I"/"me" refers to which party rather than seeing it at a glance. The human flagged this directly from a screenshot while reviewing this feature's own P9 step.

This is specific to `ravintio-ship-agent/SKILL.md`'s Step 10 text (`### Step 10 — Push/PR decision`), but the same inconsistent-pronoun-framing pattern may recur in other phase skills' human-facing choice prompts — worth a broader sweep, not just this one instance, when picked up.

## Suggested Action

Rephrase Step 10's two options to name the actor explicitly rather than relying on "I"/"me" pronouns, e.g.:
- "Agent pushes and creates the PR (git push + gh pr create)"
- "I'll push and create the PR myself — give me the title and description to use"

Then sweep other phase skills' `SKILL.md` files for the same recommend-then-confirm option pattern and check each pair of options reads unambiguously about who performs the action, without requiring the reader to track a shifting first-person referent across options.

## Why Deferred

Discovered live during this feature's own P9 run; a copy/wording fix to a skill file is out of scope for a docs/tooling-fix batch already in its ship phase. Small, low-risk — a future pickup can land it as a Fast Path or a small Change Pipeline item.
