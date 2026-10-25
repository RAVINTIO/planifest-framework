# Design-Critic Verdict (iteration 3)
**Mode:** on
**Mechanical check:** clean (exit 0). Output: three criteria-count warnings (req-002 has 4, req-004 has 4, req-006 has 5), then `consistency-check: clean`. The warnings feed rubric item 9.
**Overall:** APPROVE

Rubric items 3 and 4 are not applicable (no ADRs exist at P1).

## Iteration 2 findings

| Finding | Status | Evidence |
|---------|--------|----------|
| N1 staged deletions break the rerun | Fixed | req-006 stop condition 4 now runs `git diff --cached --quiet --diff-filter=ACMRT` and says staged deletions don't count. The resume FR names a run stopped right after step 6 with deletions still staged. |
| N2 split records | Fixed | req-006 keep note names one concern, and build-log line 98 records "keep at five criteria". req-002 has one coherent note, and line 99 records the keep. req-004 moves its fourth criterion and the version clause to req-010, and line 101 records the deferred move because the ratchet is active. |
| N3 req-004 AC3 and short form | Mostly fixed | The short-form rule is now defined (first use "RAVINTIO Framework", later uses "RAVINTIO"). The "after ship" clause stays in the AC (ratchet) but the FR assigns it to req-010, which tests it after P6. See m1. |
| N4 helper failure message, fresh consumer | Fixed in FR | req-006 FR requires the helper to name the failed step and the moved files, and the fifth AC's resume test asserts it. req-009 FR covers the fresh consumer `not applicable` record. See m2. |
| N5 old-install fixture | Fixed | req-008 FR defines the fixture: 0.36.0 install, old `core.hooksPath`, `@planifest` plugin. |
| N6 scope and design | Fixed with residue | scope.md lines 27 and 28 clarify the version and setup mappings. design.md Out gains a sub-line on brand-word edits. See m3. |
| F10 req-006 split record | Fixed | See N2. |

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Every AC in req-001 to req-010 carries a `Verified by:` tag and an observable outcome. req-004 AC3 and req-006 AC2 hold clauses that the FRs qualify (m1, m4). |
| 2 Traceability | pass | All requirements carry `Source:` US-001 to US-004. req-010 traces to US-004. design.md Skill Map has rows for REQ-008 to REQ-010. |
| 5 Scope boundaries | pass | scope.md Out of Scope excludes `external-skills/` text, `_reference/` documents, the major bump, and other backlog entries. |
| 6 Risks | pass | R-001 to R-021 are specific and each mitigation is an action. |
| 7 NFRs | pass | NFR-001 to NFR-004 each hold a number or a deterministic command. |
| 8 Internal consistency | pass | req-006, req-009, req-002, and R-008 agree on the old-pack and backup behaviour. The heredoc range conflict in req-004 is reconciled by a note (m5). |
| 9 Split step | pass | req-002 and req-006 have a recorded keep note naming one concern, with a matching `Decision` line. req-004 has a recorded pending move (build-log line 101) while the loop is active. |

## Findings (severity-ordered)
- [minor] m1 req-004 AC3: "`docs/about.md` shows 0.37.0 after ship" can't be seen at P3 to P6. The FR assigns it to req-010 (checked after P6). At the next loop-free moment, move the clause and AC4 to req-010 and record it in the build log.
- [minor] m2 req-009: no AC covers the fresh consumer `not applicable` record. Only the FR states it. Add an AC when the ratchet allows.
- [minor] m3 scope.md line 26 and line 27 still map the version bump to req-006 and req-004. Line 28 supersedes both. Delete lines 26 and 27 when the ratchet allows.
- [minor] m4 req-006 AC2 lists "an existing backup" as an unconditional non-zero exit. The FR exits 0 when the old pack is gone. Reword the AC when the ratchet allows.
- [minor] m5 req-004 AC3 cites lines 788 to 957, while req-005 and the FR say 811 to 958. Align the AC.
