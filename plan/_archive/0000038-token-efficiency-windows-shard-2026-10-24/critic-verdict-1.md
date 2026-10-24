# Design-Critic Verdict (iteration 1)
**Mode:** on (autonomous default, approach 1)
**Mechanical check:** 2 findings (exit 1)
- `requirements/req-005-context-reset-at-gates.md`: references ADR-003 but no such file exists in adr/
- `design.md`: references ADR-003 but no such file exists in adr/
**Overall:** REJECT

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | fail | req-004 AC1 says "match their original text word for word" but names no baseline (a stored hash or a git ref) that a unit test can compare against. req-004 AC2 "none of the moved text" does not say which strings the test searches for. req-006 floor wording "many tool calls" has no threshold, but its ACs only grep for presence, so they pass. |
| 2 Traceability | pass | Each req Source field (US-001 to US-007) resolves to `design.md` Product Layer. The execution plan directory lists all seven. |
| 3 ADRs | n/a | No ADRs at P1. |
| 4 Consequences | n/a | No ADRs at P1. |
| 5 Scope boundaries | pass | `scope.md` Out of Scope excludes ship-agent split and tier changes, which someone might plausibly build. |
| 6 Risks | pass | `risk-register.md` R-001 to R-010 carry action mitigations. R-002 names a crashing-suite test. |
| 7 NFRs | pass | `execution-plan.md` NFR-001 to NFR-005 carry numbers or deterministic checks. NFR-006 is a post-release comparison and is deferred. |
| 8 Consistency | fail | The mechanical ADR-003 failure. req-006 floor risks weakening named-role dispatches (see findings). |
| 9 Split step | pass | Every req has three criteria and a `Split step: keep` note. The build log holds the matching Decision line. |

## Points tested
- **Best-of-three removal in req-009:** correct. Best-of-three takes the minimum of three runs, so it is a retry that makes the check more lenient. One warm-up plus one timed call is stricter, not weaker. The spec keeps the 200 ms limit and names the retry removal. Keep it.
- **US-001 limit:** req-001 AC2 and AC3 keep 200 ms with no retry. Pass.
- **US-003 hiding failures:** req-003 AC2 covers a non-zero suite with no FAIL line. It does not cover a suite killed by a signal or one that exits 0 after printing FAIL lines. See findings.
- **US-004 word-for-word and removal from SKILL.md:** intent is right. Verification is under-specified (see findings).

## Findings (severity-ordered)
- [critical] `requirements/req-005-context-reset-at-gates.md`: mechanical check fails on the bare `ADR-003` token. Write "feature 0000032, blocking reset after P9" without the token, or have the orchestrator decide how to handle the same failure in the confirmed `design.md`.
- [critical] `design.md`: the same ADR-003 mechanical failure. The critic can't edit it. The orchestrator must rule (exempt archived-feature references or reword).
- [major] `requirements/req-004-phase-scoped-orchestrator.md`: AC1 needs a named baseline for "word for word", such as a sha256 of each moved section taken from the pre-move file or a git ref. AC2 must name the search strings, such as the two H2 headings plus a sample line from each section.
- [major] `requirements/req-006-decomposition-size-floor.md`: the floor must say that fresh-context role dispatches (design critic, security review, cross-model review, reversal assessor, test-writer and implementer) stay as they are. Today only critics and Scope Lock drafts are protected, so the floor can erode the TDD loop and review gates.
- [major] `requirements/req-003-quiet-test-output.md`: AC2 must also cover a suite ended by a signal or timeout and a suite that exits 0 after printing a FAIL line. Without these, "never hides a failed or crashed suite" is only partly tested.
- [minor] `requirements/req-003-quiet-test-output.md`: AC3 joins two concerns (unchanged default output, skill wording). It also says "unit" while NFR-005 says integration. Split the AC or align the method.
- [minor] `requirements/req-004-phase-scoped-orchestrator.md`: AC3 joins three checks (P0 load, resume reload, size). Split them so a failure names its cause.
- [minor] `requirements/req-006-decomposition-size-floor.md`: the project `CLAUDE.md` copy of custom-002 text goes stale. Say whether setup refreshes it.
