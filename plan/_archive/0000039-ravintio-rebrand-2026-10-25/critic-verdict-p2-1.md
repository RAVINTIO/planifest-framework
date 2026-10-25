# Design-Critic Verdict (P2 iteration 1)
**Mode:** on
**Phase:** P2, combined P1 and P2 set (ADR-001 to ADR-010, req-001 to req-010, design.md, feature-brief.md, execution-plan.md, scope.md, risk-register.md, domain-glossary.md)
**Mechanical check:** clean (exit 0). Output, with the two U+2014 characters in the tool text replaced by a comma because a hook blocks them:

```
  ⚠ req-002-runtime-names.md: 4 acceptance criteria (aim for 3, consider splitting the story)
  ⚠ req-006-consumer-migration.md: 5 acceptance criteria (aim for 3, consider splitting the story)
consistency-check: clean
```

The two warnings feed rubric item 9.

**Overall:** REJECT

Two major contradictions sit between the ADRs, the requirements, and the design. The mechanical check does not catch either.

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Every AC in req-001 to req-010 states an observable outcome with a `Verified by:` tag. Weak spots: req-010 AC2 names no command (m3), and req-001 AC3 conflicts with its own FR exception (m2). |
| 2 Traceability | pass | All requirements carry `Source:` US-001 to US-004. design.md Skill Map lists REQ-001 to REQ-010. execution-plan.md directory lists all ten. |
| 3 ADRs record real decisions | pass | Each ADR names at least two genuine alternatives with rejection reasons. Examples: ADR-005 (delete behind guards, cites RAVINTIO Zero 0000160 ADR 003), ADR-006 (sort last, rewrite bodies, order by version), ADR-009 (rewrite history, rewrite changelogs only, separate repo), ADR-008 (Edit-only fan-out, two commits, sanctioned script). ADR-001 and ADR-010 are thinner but their alternatives are plausible. |
| 4 Consequences honest | pass | Every ADR lists a hurting negative. Examples: ADR-003 (minor bump hides a break from version-only tools), ADR-005 (a forgotten backup and a warning-only branch protection note), ADR-008 (precedent for breaching Hard Limit 8, a 590-file diff). |
| 5 Scope boundaries | pass | scope.md Out of Scope excludes `external-skills/` text, `_reference/` documents, the major bump, sibling repos, and other backlog entries. Each is something a builder might plausibly touch. |
| 6 Risks | pass | R-001 to R-021 are specific. Mitigations are actions. R-011 and R-016 rely on the marker behaviour that finding M1 shows is contradictory. |
| 7 NFRs | pass | NFR-001 to NFR-004 each hold a number or a deterministic command. |
| 8 Internal consistency | fail | Findings M1 and M2, plus m1 and m4. |
| 9 Split step | pass | req-002 (4 ACs) and req-006 (5 ACs) carry `Split step: keep` notes naming one concern. The build log holds matching Decision lines ("split step for req-006 at five criteria: keep", "split step for req-002 at four criteria: keep"). req-004 now has 3 ACs. |

## Findings (severity-ordered)

- [major] M1 design.md step 3, ADR-004, ADR-005 step 5, ADR-010, req-002, req-005, req-006, risk-register R-011 and R-016: the old marker files are both read by setup and removed before setup runs. The consumer order is helper, then setup (ADR-005, req-006). req-006 step 5 has the helper remove `.claude/.planifest-setup-flags`, `.claude/skills/.planifest-manifest`, and `.planifest-session`. ADR-004 and req-002 AC1 have setup read `.planifest-setup-flags` once to carry flags forward, and read `.planifest-manifest` once to prune old skill copies. After the helper runs, setup finds neither file, so the flags are lost and the old skills are never pruned (R-016's mitigation fails). Decide which step owns the read and which owns the removal, and align the design, ADRs, req-002 AC1, req-006 step 5, and the risks.
- [major] M2 ADR-006, req-009 AC2, req-006 FR (Applies when): the `applied` record cannot happen. req-006 sets `Applies when:` to "`planifest-framework/` or `planifest-overrides/` exists". The consumer runs the helper by hand first, which moves both. The condition is then false, so req-009's own rule records `not applicable`. ADR-006 and req-009 AC2 instead promise a no-op rerun and an `applied` record. Pick one outcome, or change the condition (for example, key on the absence of the `ravintio-overrides` result or on the backup).
- [minor] m1 ADR-004 "Exactly these old names" and design.md: the list omits `.planifest-manifest` (design) and the `.planifest-session` deletion in `archive-current.mjs` (req-005 row 275, req-006 step 5). The design, ADR-004, scope.md Deferred, and req-005 disagree on the closed list. Align them so the brand guard allowlist matches one list.
- [minor] m2 req-001 AC3 vs FR: the AC demands no `D` plus `A` pair for the workflow and hook file. The FR and R-021 expect small files to fall below the 50% threshold. Add the logged exception to the AC.
- [minor] m3 req-010 AC2: "no live file names 1.0.0 as the current release" has no command. ADR-003 and the migration body must mention 1.0.0, so a bare grep fails. Name the pattern.
- [minor] m4 ADR-009 vs NFR-003: ADR-009's measurement command omits the `plan/backlog/*/_reference/` glob that NFR-003 includes. Use one command.
- [minor] m5 ADR-007 and req-007: "the allowlist covers the suite and its regression copy" combined with a stale-entry failure means a regression-only entry is stale until ship promotes the suite. Say that one regex covers both paths. Also, "any other old-name read that stays through 0.x" and "entries filed during this feature" are open-ended, which conflicts with ADR-007's "closed list".
- [minor] m6 risk-register R-012: cites req-006 for the setup stop. req-002 owns it.
