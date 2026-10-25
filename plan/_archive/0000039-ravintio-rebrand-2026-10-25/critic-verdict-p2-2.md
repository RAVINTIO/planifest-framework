# Design-Critic Verdict (P2 iteration 2)
**Mode:** on
**Phase:** P2, combined P1 and P2 set (ADR-001 to ADR-010, req-001 to req-010, design.md, feature-brief.md, execution-plan.md, scope.md, risk-register.md, domain-glossary.md)
**Mechanical check:** clean (exit 0). Output:

```
  ⚠ req-002-runtime-names.md: 4 acceptance criteria (aim for 3, consider splitting the story)
  ⚠ req-006-consumer-migration.md: 5 acceptance criteria (aim for 3, consider splitting the story)
consistency-check: clean
```

**Overall:** REJECT

Iteration 1 findings M2, m1 to m4 and m6 are fixed. M1 is fixed in the design, ADR-004, req-002, req-006 and scope.md, but three artifacts still say the helper removes all old markers.

## Iteration 1 findings

| Finding | Status | Evidence |
|---------|--------|----------|
| M1 marker read vs removal | partly fixed | design.md step 3 sub-line, ADR-004 Decision, req-006 step 5 and scope.md now say the helper removes only `.planifest-session`. ADR-005 step 5, ADR-010 Context and R-011 still say the helper or migration removes the old marker files (see N1, N2). |
| M2 `applied` record impossible | fixed | `Applies when:` names the backup in req-006, req-009, ADR-006 and design.md step 7. |
| m1 closed marker list | fixed | design.md, ADR-004, scope.md Deferred list `.planifest-manifest`. `.planifest-session` is covered in ADR-004. |
| m2 req-001 AC3 exception | fixed | req-001 FR defines the build-log exception to AC3. |
| m3 req-010 AC2 command | fixed | req-010 FR names the `git grep` command and pass rule. |
| m4 ADR-009 vs NFR-003 | fixed | ADR-009 and NFR-003 use the same command with the `_reference` glob. |
| m5 allowlist wording | partly fixed | req-007 adds the shared regex and a correction line. ADR-007 Regression tag section still says only "covers the suite and its regression copy" (N3). |
| m6 R-012 owner | fixed | R-012 cites req-002 as owner. |

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Every AC in req-001 to req-010 states an observable outcome with a `Verified by:` tag. req-010 AC2 now has a command. |
| 2 Traceability | pass | All requirements carry `Source:` US-001 to US-004. design.md Skill Map lists REQ-001 to REQ-010. |
| 3 ADRs record real decisions | pass | Each ADR has at least two genuine alternatives with rejection reasons. Examples: ADR-005 (delete behind guards, cites RAVINTIO Zero 0000160 ADR 003), ADR-006 (sort last, rewrite bodies, order by version), ADR-004 (fallback for all, warn, no fallback). |
| 4 Consequences honest | pass | Every ADR lists a hurting negative. Examples: ADR-005 (forgotten backup, warning-only branch protection), ADR-006 (hand-run helper required), ADR-007 (allowed-line edits break the suite). |
| 5 Scope boundaries | pass | scope.md Out of Scope and Deferred exclude `external-skills/` text, history, sibling repos and the 1.0.0 removal. |
| 6 Risks | pass | R-001 to R-021 are specific with action mitigations. R-011 wording is stale (N2). |
| 7 NFRs | pass | NFR-001 to NFR-004 hold a number or a command. |
| 8 Internal consistency | fail | N1 to N3. |
| 9 Split step | pass | req-002 (4 ACs) and req-006 (5 ACs) carry `Split step: keep` notes. The build log holds matching Decision lines from P1. |

## Findings (severity-ordered)

- [major] N1 ADR-005 Decision, helper step 5 "Remove the old marker files", and Context bullet "the old marker files": this contradicts ADR-004, design.md step 3, req-006 step 5 and scope.md. Those say the helper removes only `.planifest-session` and leaves `.planifest-setup-flags` and `.planifest-manifest` for setup. ADR-005 governs req-006 and the helper, so a reader of it alone builds the helper that destroys the flags. Add a clarifying sub-line to step 5 naming `.planifest-session` as the only removal.
- [minor] N2 risk-register R-011 mitigation "The migration removes the old marker files" and ADR-010 Context "removes old markers": same stale wording. Add a clarifying clause naming the split between the helper (`.planifest-session`) and setup (the other two).
- [minor] N3 ADR-007 Regression tag: say that one path regex, `^ravintio-framework/tests/(regression/)?test-0000039-req-007-brand-guard\.sh$`, covers the suite and its copy, as req-007 does.
