# Design-Critic Verdict (P2, iteration 2)
**Mode:** on (autonomous default, approach 1)
**Mechanical check:** clean. `consistency-check: clean`, exit 0. Three criteria-count warnings remain (req-003, req-004, req-006). Each carries a `Split step: keep` note.
**Overall:** REJECT

## Iteration 1 findings

| Finding | Status | Evidence |
|---------|--------|----------|
| 1 Cross-feature ADR tokens | fixed | ADR-004, ADR-005, ADR-007 use prose. The mechanical check is clean. |
| 2 Hung suite hidden | fixed | ADR-004 rule 6a adds the `INT` and `TERM` trap with no timeout. |
| 3 Suite marker clash | fixed | ADR-004 rule 6b. |
| 4 Model test scope | fixed | ADR-003 rule 5 states the exact pattern and reads `pipeline-reference.md`. |
| 5 Migration list | fixed | ADR-007 rule 2 drops `pipeline-reference.md`. |
| 6 FAIL as test data | fixed | ADR-004 risks limit the change to printed text. |
| 7 Skipped P0 read | fixed in intent, but see finding 1 below. |

## Constraint check
No ADR or requirement weakens a gate, hook, critic, review, TDD loop, or assertion. ADR-006 exempts nine fresh-context roles. ADR-004 makes quiet mode stricter than default. ADR-005 keeps 200 ms and bans retries.

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Every AC states an observable outcome with a Verified by tag. |
| 2 Traceability | pass | Source fields resolve to US-001 to US-007. |
| 3 Real alternatives | pass | Each ADR holds four or five alternatives with reasons. |
| 4 Honest consequences | pass | Each ADR names a negative that hurts. |
| 5 Scope boundaries | pass | scope.md excludes the ship-agent split and other-tool tiers. |
| 6 Risks and mitigations | pass | R-001 to R-010 name actions. |
| 7 NFRs measurable | pass | 41,500 bytes, 200 ms, byte-identical output. |
| 8 Internal consistency | fail | Finding 1. |
| 9 Split step | pass | Keep notes in req-003, req-004, req-006. |

## Findings (severity-ordered)
1. [major] `adr/ADR-002-orchestrator-reference-files.md`: rule 4a adds a checklist item to the `Phase 0 to Phase 1 Gate Checklist`. That heading sits at `SKILL.md` line 563, inside the Phase 0 span (lines 239 to 588) that rule 1 and req-004 require to move byte for byte. The edit breaks the byte-identical test, or the block stops matching commit `5966840`. Place the checklist item and log line outside the moved block (for example the pointer section or Phase Conventions), or state that the byte test excludes that one named line.
2. [minor] `adr/ADR-002-orchestrator-reference-files.md`: the 1,600 byte margin must also cover the item from finding 1. Restate the margin after the fix.
