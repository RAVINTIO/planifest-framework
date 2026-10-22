# Design-Critic Verdict (P2, iteration 2)
**Phase:** P2 (combined P1 and P2 set)
**Mode:** on
**Mechanical check:** clean
**Overall:** APPROVE

```
node planifest-framework/scripts/consistency-check.mjs plan/current
consistency-check: clean
```

The check prints no warning. Every requirement holds exactly 3 checkbox criteria. `stream-reconcile.mjs plan/current` also exits 0.

All nine iteration 1 findings are resolved. The fresh review found 0 critical, 0 major, and 3 minor findings. None blocks the gate. Each minor is a drift between two artifacts, and each has a one-line fix.

## Iteration 1 findings

| Finding | Status | Evidence |
|---------|--------|----------|
| M1 acceptance-criteria limit has no owner or ADR | resolved | `adr/ADR-012-acceptance-criteria-limit-and-warning.md` records the limit of 10, the 4 to 10 warning band, both human instructions (line 20), and four alternatives (lines 38 to 41). `build-log.md` line 159 records the P1 deviation. `scope.md` line 63 and `design.md` line 43 cite both. The ADR's claims match the code: `consistency-check.mjs` lines 69 to 72, `feature-brief.template.md` line 27, and `test-0000016-pipeline-governance.sh` lines 200 and 235. |
| m1 ADR-002, ADR-010, and ADR-017 cite no requirement | resolved | ADR-002 line 20 cites req-001. ADR-010 line 24 cites req-002 and req-008. ADR-017 line 20 cites req-007 FR-007.4 and req-010. |
| m2 ADR-001 "Five new suites" | resolved | ADR-001 line 55 reads "Six new suites". |
| m3 one-way parity check | resolved | req-009 line 74 and ADR-004 line 38 both state set equality in both directions. ADR-004 line 60 now holds. |
| m4 ADR-016 cites a missing suite case | resolved | req-007 line 131 adds the `plan/_migrations/x.md` case with no sentinel and no design, expecting exit 0. ADR-016 line 81 now matches it. |
| m5 "from a scan run here" contradicts FR-010.1 | resolved, with new drift | req-010 lines 29 to 33 define the `**Target:**` line check as the scan for the two downstream-only migrations. Both files hold that line on line 3. The story text and AC-010.1 now read true. ADR-019 and the glossary weren't updated to match. See n1. |
| m6 stream-01 consumer for the marker rule | resolved | `streams/stream-01-gate-rules.md` line 45 says the artifact feeds req-005 through `resolveRoot`. |
| m7 hyphen form in `discovery.md` | resolved | `discovery.md` lines 28 and 31 to 40 use `0000032 ADR 004` and the same form throughout. A search of `plan/current/` finds no `{feature} ADR-nnn` or `{feature}-ADR` form outside the critic and log files. |
| m8 mixed ADR status | resolved | All 16 ADRs read `status: "accepted"` on line 4. The fix took `accepted` in place of the suggested `proposed`. The ADR template allows either, and the verdict asked only for one status. |

## ADR coverage

| Requirement or decision | ADR |
|-------------------------|-----|
| req-001 | ADR-002, ADR-003 |
| req-002 | ADR-010 |
| req-003 | ADR-005 |
| req-004 | ADR-006 |
| req-005 | ADR-007 |
| req-006 | ADR-008 |
| req-007 | ADR-015 to ADR-018 |
| req-008 | ADR-011 |
| req-009 | ADR-004 |
| req-010 | ADR-019 |
| Acceptance-criteria limit (P1 deviation) | ADR-012 |
| Stack and no-spawn rule | ADR-001 |

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Each criterion names an exit code, a file value, or a source check. Examples: req-003 line 69 (exit 2 with cause, 500 ms), req-005 line 52 (import and no `process.cwd()` outside the fallback), and req-008 line 65 (newline injection, byte-identical file). |
| 2 Traceability | pass | Each requirement names its story on line 11. The ten stories in `feature-brief.md` lines 21 to 30 each map to one requirement. The one change with no story, the criteria limit, has ADR-012 and a build-log deviation at line 159. `scope.md` line 63 cites both. |
| 3 ADRs record real decisions | pass | Each of the 16 ADRs names two or more real alternatives with reasons. Examples: ADR-012 lines 38 to 41, ADR-005 lines 43 to 47, and ADR-017 lines 34 to 36. |
| 4 Consequences honest | pass | Each ADR has a negative that would hurt. Examples: ADR-012 line 56 (a fold of 12 into 3 still passes), ADR-002 line 67 (no review before the write), and ADR-008 line 58 (a real repo under `pause.md` loses root status). |
| 5 Scope boundaries | pass | `scope.md` lines 67 to 74 exclude plausible work. Examples: seeding from `_done/` (line 70), relaxing the root-file gate (line 71), and removing an enforcement path (line 73). |
| 6 Risks specific and mitigated | pass with minor | R-001 to R-020 are specific, and each mitigation is an action. Examples: R-012 (`risk-register.md` line 31) and R-020 (line 39). The assumption IDs differ between two files (n2). |
| 7 NFRs measurable | pass | NFR-001 to NFR-005 (`execution-plan.md` lines 38 to 42) each give a number or a deterministic check. |
| 8 Internal consistency | pass with minors | No requirement contradicts an ADR in what P3 builds. ADR-006 line 32 matches req-004 lines 30 to 32. ADR-004 line 38 matches req-009 line 74. Wording drift remains in n1 and n3. |

## Findings (severity-ordered)

- [minor] n1 `adr/ADR-019-records-come-from-scans-never-seeded.md` lines 28 and 40, and `domain-glossary.md` line 45: they don't match the m5 fix in req-010.
  - req-010 lines 32 and 33 now say the `**Target:**` line check is the scan for the two downstream-only migrations. They say "from a scan run here" covers all eight.
  - ADR-019 line 28 still says P3 writes those two records "without running them". Line 40 rejects an alternative whose stated gain is "Every record comes from a scan". req-010 now claims that gain.
  - The glossary "Scan" entry (line 45) doesn't cover the target check.
  - Fix: on ADR-019 line 28, write "without running their Migrator Instructions. P3 reads each file's `**Target:**` line, and this target check is the scan for these two."
  - Fix: on ADR-019 line 40, change the Pros cell to "Every record comes from a full scan".
  - Fix: on glossary line 45, add "For a downstream-only migration in this repo, the scan is the `**Target:**` line check (req-010)."

- [minor] n2 `execution-plan.md` lines 108 to 110 and `risk-register.md` lines 47 to 50: the same assumption IDs name different assumptions.
  - In the execution plan, A-002 is the git-state reader and A-003 is the older scans.
  - In the risk register, A-002 is the older scans, A-003 is "no existing records", and A-004 is Node 18. The git-state assumption is missing.
  - ADR-019 line 61 cites A-002 for the older scans, which is right in the register and wrong in the execution plan.
  - Fix: in `execution-plan.md`, renumber the scans row from A-003 to A-002. Give the git-state row a new ID, A-005.
  - Fix: add A-005 to the `risk-register.md` assumptions table with the same text and impact, cross-referenced to R-007.

- [minor] n3 `adr/ADR-012-acceptance-criteria-limit-and-warning.md` lines 18 and 52, against `requirements/req-002-product-yml-in-p7.md` lines 53 to 61: the fold that ADR-012 describes is still in place.
  - ADR-012 line 18 says the limit of 3 rewarded a fold into sub-bullets. Line 52 claims each criterion now stays visible as its own checkbox line.
  - req-002 AC 1 still folds eight cases under one checkbox line. req-008 AC 1 (line 64) folds one more. The counter reads 3 for each.
  - ADR-012 line 56 already admits that a fold still passes, so the record is honest. It doesn't say that this feature keeps one.
  - Fix: add one Negative line to ADR-012 after line 57: "This feature's req-002 AC 1 keeps its eight-case fold, so the counter reads 3 for it." Or promote the eight sub-bullets under req-002 line 53 to checkbox lines. That adds lines only, so the ratchet allows it, and the check then prints a warning.

## Notes, not findings

- ADR-015 rejects `git mv` (line 45) because the shell guard passes git commands, yet it uses `git rm` (line 32). The difference holds. `git rm` deletes and writes no content, and **Write** can't delete a file. It needs no action.
- `design.md` line 30 and brief line 134 still say the Fast Path commit deletes the record. `execution-plan.md` line 92, `scope.md` line 51, and ADR-002 line 51 record the sharpening, so the trail is complete.
- All 16 ADRs read `accepted` before the P2 gate. The human on the loop confirms them at that gate whatever the field says.
- ADR IDs 009, 013, and 014 are unused. The stream id-blocks reserve them (stream-01 line 9, stream-02 line 9).
