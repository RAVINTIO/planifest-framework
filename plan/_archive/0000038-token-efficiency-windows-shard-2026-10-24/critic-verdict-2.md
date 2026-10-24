# Design-Critic Verdict (iteration 2)
**Mode:** on (autonomous default, approach 1)
**Mechanical check:** clean (exit 0). Three warnings only: req-003 has 6 criteria, req-004 has 8, req-006 has 4. Each carries a `Split step: keep` note.
**Overall:** APPROVE

## Iteration 1 findings

| Finding | Status | Evidence |
|---------|--------|----------|
| [critical] req-005 bare ADR token | fixed | `grep ADR-003` finds no hit in `design.md` or `requirements/`. The mechanical check is clean. |
| [critical] design.md bare ADR token | fixed | Orchestrator reworded it. Build log Decision line records the reason. |
| [major] req-004 baseline and search strings | fixed | AC4 names blob `5966840`, which exists and is an ancestor of HEAD. Lines 239 and 768 hold the two H2 headings there. AC5 names five strings. All five exist at that commit. |
| [major] req-006 role exemptions | fixed | Functional requirements and AC4 name nine exempt roles and bar any removal of a maker-checker split or TDD step. |
| [major] req-003 signal, timeout, FAIL with exit 0 | fixed | Functional requirements and AC4 cover both cases. |
| [minor] req-003 AC3 two concerns, unit versus integration | fixed | AC5 (integration, NFR-005) and AC6 (unit) split the two checks. |
| [minor] req-004 AC3 three checks | fixed | AC6, AC7 and AC8 split them. |
| [minor] req-006 stale `CLAUDE.md` copy | fixed | Functional requirements say a setup re-run refreshes it. The migration covers it. |

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Every criterion names an observable outcome and a method. req-004 AC4 and AC5 give a baseline and exact strings. |
| 2 Traceability | pass | Each req Source (US-001 to US-007) matches `design.md` Product Layer and `feature-brief.md`. The execution plan directory lists all seven. |
| 3 ADRs | n/a | No ADRs at P1. |
| 4 Consequences | n/a | No ADRs at P1. |
| 5 Scope boundaries | pass | `scope.md` Out of Scope excludes the ship-agent split, timing-limit changes and tier changes. Someone could plausibly build each. |
| 6 Risks | pass | `risk-register.md` R-001 to R-010 carry action mitigations. R-002 names failing and crashing suites. R-010 covers gate weakening. |
| 7 NFRs | pass | NFR-001 to NFR-005 carry numbers or deterministic checks. NFR-006 is a deferred post-release comparison. |
| 8 Consistency | pass | No requirement contradicts `design.md`. Quality-gate constraint holds (below). |
| 9 Split step | pass | Each req over three criteria has a `Split step: keep` note naming one concern. Extra criteria refine existing ones. |

## Quality-gate constraint
No requirement weakens a gate, hook, critic, review, TDD loop or assertion. req-001 removes the best-of-three retry and keeps 200 ms, so it is stricter. req-003 adds failure detection. req-004 moves assertions with their text and adds an absence test. req-006 exempts every fresh-context role. req-005 leaves the after-P9 block unchanged.

## Findings (severity-ordered)
- [minor] `plan/current/build-log.md`: Decision line "split step for req-001 to req-007: keep" still says "three criteria". It is stale for req-003, req-004 and req-006. Lines for req-003 and req-006 name no split-step keep.
- [minor] `plan/current/design.md`: "21 acceptance criteria" no longer matches the 29 in the requirements. The build log records the deviation.
- [minor] `plan/current/requirements/req-004-phase-scoped-orchestrator.md`: ACs 4 to 8 repeat ACs 1 to 3 by design under the ratchet. Merge them when no loop is active.
- [info] `plan/current/build-log.md`: commit `0411efd` edited req-005 through Bash and bypassed `ratchet-check`. The orchestrator must raise it with the human on the loop.
