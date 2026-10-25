# Design-Critic Verdict (P2 iteration 3)
**Mode:** on
**Phase:** P2, combined P1 and P2 set (ADR-001 to ADR-010, req-001 to req-010, design.md, feature-brief.md, execution-plan.md, scope.md, risk-register.md, domain-glossary.md)
**Mechanical check:** clean (exit 0). Output:

```
  ⚠ req-002-runtime-names.md: 4 acceptance criteria (aim for 3, consider splitting the story)
  ⚠ req-006-consumer-migration.md: 5 acceptance criteria (aim for 3, consider splitting the story)
consistency-check: clean
```

**Overall:** APPROVE

## Iteration 2 findings

| Finding | Status | Evidence |
|---------|--------|----------|
| N1 ADR-005 helper step 5 | fixed | ADR-005 step 5 sub-line: the helper removes only `.planifest-session` and leaves `.planifest-setup-flags` and `.planifest-manifest` for setup. Context bullet and the ADR-010 related-to line agree. |
| N2 R-011 and ADR-010 Context | fixed | R-011 mitigation names the helper (`.planifest-session`) and setup (the other two). ADR-010 Context says the helper removes the old `.planifest-session` marker. |
| N3 ADR-007 Regression tag | fixed | ADR-007 Regression tag states one path regex `^ravintio-framework/tests/(regression/)?test-0000039-req-007-brand-guard\.sh$` covers the suite and its copy. |

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Every AC in req-001 to req-010 states an observable outcome with a `Verified by:` tag. req-010 FR names the `git grep` command and pass rule. |
| 2 Traceability | pass | Each requirement carries `Source:` US-001 to US-004. design.md Skill Map lists REQ-001 to REQ-010. |
| 3 ADRs record real decisions | pass | ADR-001 has three genuine alternatives (Node helpers, codemod tool, Node test) with rejection reasons. ADR-004 to ADR-006 and ADR-010 also list distinct rejected options. |
| 4 Consequences honest | pass | ADR-001 (logic duplicated in two shells), ADR-008 (Hard Limit 8 precedent, 590-file diff), ADR-009 (greps still find hits in history) each list a hurting negative. |
| 5 Scope boundaries | pass | design.md Scope Out and Deferred exclude history, sibling repos, the clone folder path and the 1.0.0 removal. |
| 6 Risks | pass | R-001 to R-021 are specific with action mitigations. R-011 now matches the design. |
| 7 NFRs | pass | NFR-001 to NFR-004 hold a number or a command. |
| 8 Internal consistency | pass | Marker removal split is the same in design.md step 3, ADR-004, ADR-005, ADR-010, req-006 step 5 and R-011. `Applies when:` condition matches in design.md step 7, req-006 and req-009. |
| 9 Split step | pass | req-002 (4 ACs) and req-006 (5 ACs) carry `Split step: keep` notes. The build log holds the matching Decision lines. |

## Findings (severity-ordered)

- None remaining.
