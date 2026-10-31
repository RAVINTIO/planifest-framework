---
title: "Backlog Entry: 0000355 - regulated strategy and amendments from the Zero review"
summary: "Record of the owner's strategy stated on 2026-10-31, the decisions it forces, the amendments the Zero review found for existing entries, and a suggested order."
status: "open"
---
# Backlog Entry: 0000355 - regulated strategy and amendments from the Zero review

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31

**Suggested route:** none. This entry records decisions and edits. It isn't a pipeline run.
**Related:** 0000279, 0000292, 0000295, 0000297 to 0000354

---

## Context

On 2026-10-31, the owner compared Framework with RAVINTIO Zero and stated Framework's strategy. This entry records that strategy for the human. It also lists the decisions the strategy forces and the amendments the review found for existing entries.

Zero and Framework number their phases differently. Zero has five phases, from Zero P0 Discovery to Zero P4 Ship. Framework has ten, from P0 Assess to P9 Ship. Every entry from this review uses Framework numbering, and cites Zero phases by name, such as "Zero P1 Plan".

## 1. Strategy

Framework differs from Zero in these ways:

- It focuses on compliant, regulated industries.
- Jira drives the workflow.
- It rejects uncontrolled development, such as Zero's initiatives.
- It builds one feature at a time, with controls that fit the risk.
- It supports GAMP 5 and other risk-averse frameworks.
- It ships no bundled third-party skills. Developers bring their own through overrides.
- It adopts Zero's postmortem approach and goes further.

## 2. Decisions needed

- **0000244 and 0000245.** These entries cover roadmap drafts and the chart, and roadmap run, advance, and delivery. They port Zero's initiative pattern, which conflicts with the strategy. The review recommends closing them or moving them to Zero.
- **0000292.** If 0000244 and 0000245 close, narrow this entry on building Framework with Zero to match.
- **0000279 section 2.** It moves 0000085 (postmortems) to RAVINTIO Insight. That conflicts with the strategy, which keeps postmortems in Framework.

## 3. Amendments to existing entries

| Entry | Amendment | Source |
|-------|-----------|--------|
| 0000295 | Record setup flags in `{tool-dir}/.ravintio-setup-flags`, not Zero's `plan/state/{tool}.md`. | Framework setup |
| 0000295 | Give the agent its own Atlassian account. Otherwise Jira credits the human with the agent's moves. | Zero review |
| 0000295 | At each approval, commit a snapshot of the approved Story content with its hash. | Zero review |
| 0000295 | Absorb 0000282 items 1, 2, 4, and 5. These cover source keys, a `Refs: {KEY}` commit trailer, the PR title key, and remote links at P9. | 0000282 |
| 0000295 | Add review statuses mapped to phase gates, with human-only transitions. | 0000352 |
| 0000295 | Add a Jira-unavailable outbox at `plan/current/jira-outbox.md`, with idempotent replay. | Zero review |
| 0000295 | Target Xray before Zephyr. Post results from CI with a secret that CI holds. | Zero review |
| 0000282 | Move item 3 to 0000353. | 0000353 |
| 0000283 | Target Xray Test issues first, and post results from CI. | Zero review |
| 0000284 | Target a Jira risk project with "mitigated by" links and an external ID column. | Zero review |
| 0000286 | Add a design-review reviewer independent of the stage under review (ISO 13485 7.3.5). | ISO 13485 |
| 0000286 | The design gate checks only that `design.md` exists. The agent writes `Human confirmed ... yes`. See `ravintio-framework/skills/ravintio-orchestrator/references/phase-0-assess-and-coach.md` near lines 228 to 252, and `ravintio-framework/hooks/enforcement/path-rules.mjs`. Approvals must come from a source the agent can't forge. `.ratchet-approve` and phase skips need the same fix. | Zero review |
| 0000287 | Make phase skips into waivers. Policy names the phases nobody can skip, at least P4 and P5. | Zero archive 0000252 |
| 0000287 | The orchestrator's skip protocol says "do not ask for justification", and the agent writes "skipped by human". Take eligibility rules from Zero archive 0000252. Its "P1 skips" mean Zero P1 Plan, which maps to Framework P1 and P2. | Zero archive 0000252 |
| 0000288 | Add guard widening. A change that widens a fail-closed hook needs its own approval. See 0000327. | Zero archive 0000252 |
| 0000289 | Add the Zero 0000266 checks: no time later than its commit, and every finished phase closed. Keep each failed attempt's log. See 0000312. | Zero 0000266 |
| 0000290 | Add postmortems, CAPAs, deviations, and periodic reviews to the export. | Zero review |
| 0000085 | Merge Zero 0000285's ship gate and tests. See 0000330 to 0000332. | Zero 0000285 |
| 0000097 | Add Zero 0000173 workflow governance metrics. These use `Rework:`, `Blocked:`, `Requirement change:`, and `Gate revised:` markers, with thresholds at ship. Let policy set the thresholds. A breach needs a rationale or a waiver. | Zero 0000173 |
| 0000110 | 0000300 supersedes this entry in scope. | 0000300 |
| 0000145 | Add the Zero 0000287 and 0000288 fail-closed visibility when a hook is missing. | Zero 0000287, 0000288 |
| 0000268 | Port Zero's Gherkin ratchet (4bbd90b) and consistency checks 6 to 8. Raise its priority, because stable criterion IDs feed traceability. | Zero 4bbd90b |
| 0000271 | Zero `reserve-id.mjs` (b567016, with `--commit` from 3260b73) is the fix. Copied entries take a local ID and name the source repo and ID. | Zero b567016, 3260b73 |
| 0000276 | Point at Zero `scripts/check-attribution.mjs` (d759b95) and its test. | Zero d759b95 |
| 0000278 | Cite Zero 0b194a0 (Zero 0000196). | Zero 0b194a0 |
| 0000294 | Add a Stop hook warning, and the rule "never report compliance with a standing rule". | Zero review |
| 0000020 or 0000236 | Add Zero's skill-targeted overrides, with `target: {skill}` frontmatter. Add size caps that exclude overrides. | Zero archives 0000245, 0000242 |
| `standards/agent-dispatch-standards.md` | An `Agent` call without `model` inherits the parent tier. Fix the Fast Path wording too. | Zero 5b62e0b |

## 4. New entries filed from the review

- Urgent controls: 0000297 to 0000299.
- Skills: 0000301, 0000302.
- Controls and setup: 0000300, 0000303 to 0000329.
- Postmortem and CAPA: 0000330 to 0000336.
- GAMP 5: 0000337 to 0000347.
- Other frameworks: 0000348 to 0000351.
- Jira: 0000352 to 0000354.

## 5. Suggested order

1. Urgent controls: 0000297, 0000298, and 0000299.
2. 0000272 and 0000301.
3. Base controls: 0000288, 0000286, and 0000289, with 0000303 and 0000305.
4. 0000296 and 0000295.
5. 0000348 and 0000337.
6. 0000339, 0000338, 0000340, 0000341, and 0000342.
7. Postmortem and CAPA: 0000330 to 0000332.
8. The remaining items.

## Why Deferred

The owner stated the strategy on 2026-10-31. The decisions in section 2 need the human, and each amendment lands when its entry next changes.
