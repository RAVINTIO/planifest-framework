# Design-Critic Verdict (P2, iteration 1)
**Phase:** P2 (combined P1 and P2 set)
**Mode:** on
**Mechanical check:** clean
**Overall:** REJECT

```
node planifest-framework/scripts/consistency-check.mjs plan/current
consistency-check: clean
```

The check prints no warning. Every requirement holds exactly 3 checkbox criteria.

One major finding blocks the gate. An in-scope governance change has no requirement and no ADR. Eight minor findings follow. The three splits are clean, and every minor from `design-critic-p1-split.md` is resolved.

## Split check

| Check | Result | Evidence |
|-------|--------|----------|
| req-001 and req-009 | pass | req-009 line 22 states the ownership boundary. req-001 line 54 hands the enforcement list to req-009. Each has its own suite (req-001 line 84, req-009 line 23). |
| req-002 and req-008 | pass | req-008 line 22 states the boundary. req-002 line 70 says the req-008 suite owns the link case. req-008 AC 1 (line 64) holds it. |
| req-007 and req-010 | pass | req-007 lines 119 and 134 point to FR-010.1 and FR-010.2. req-007 line 142 retires the AC-007.3 ID. req-010 line 22 states the boundary. |
| ADR citations after the splits | partial | ADR-004 cites req-009 (line 29). ADR-011 cites req-008 (line 20). ADR-019 cites req-010 AC-010.1 (line 30). ADR-002, ADR-010, and ADR-017 cite no requirement. See m1. ADR-001 line 55 still counts five suites. See m2. |
| Streams and execution plan | pass | stream-01 line 7, stream-02 line 7, and stream-03 line 7 list the new requirements. execution-plan lines 23 to 32 and 82 to 83 match. |

## P1 split minors

| Minor | Status | Evidence |
|-------|--------|----------|
| m1 stream-02 lines 33 and 37 | resolved | Line 33 says the script serves req-002 and req-008. Line 37 lists `resolveRoot` as consumed. |
| m2 req-008 link case | resolved | req-008 line 35 and AC 1 line 64 own the link case. The req-002 suite list (lines 53 to 61) no longer holds it. |
| m3 US-008 outcome | resolved | The widened outcome appears in feature-brief line 28, design.md line 19, and req-008 line 18. |
| m4 req-001 split | resolved | req-009 now holds the enforcement list. |
| m5 req-007 split | resolved | req-010 now holds this repo's run. |

## ADR coverage

| Requirement | Decision | ADR |
|-------------|----------|-----|
| req-001 | Scope record, self-authorisation, visibility | ADR-002, ADR-003 (staleness) |
| req-002 | P7 step and `set-product-release.mjs` | ADR-010 |
| req-003 | Segment-by-segment resolution, fail-closed line | ADR-005 |
| req-004 | Root lookup from a deleted cwd | ADR-006 |
| req-005 | Ratchet on shared rules | ADR-007 |
| req-006 | Marker distrust under permitted names | ADR-008 |
| req-007 | Files never move, records, owner, pending rule | ADR-015 to ADR-018 |
| req-008 | Hard Limit 8 carve-out and sanctioned list | ADR-011 |
| req-009 | Enforcement list and precedence | ADR-004 |
| req-010 | Records from scans, no seeding | ADR-019 |
| none | Acceptance-criteria limit of 10 with a warning band | none. See M1. |

Cross-feature ADRs in `adr/`, `requirements/`, and `design.md` use the `0000032 ADR 004` form. `discovery.md` doesn't. See m7.

Each ADR names at least one positive and one negative consequence. ADR-017 has the fewest, with one negative (line 49), and it would hurt.

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Each criterion names an exit code, a file value, or a source check. Examples: req-001 line 105, req-009 line 78, req-010 line 46. See m3 for one test that proves less than its criterion. |
| 2 Traceability | fail | Each requirement names a `Source:` story on line 11. The ten stories in feature-brief lines 21 to 30 each map to a requirement. scope.md line 62 is in scope with no story and no requirement (M1). |
| 3 ADRs record real decisions | fail | Each of the 15 ADRs names two or more real alternatives with reasons. Examples: ADR-005 lines 43 to 47 and ADR-016 lines 56 to 60. The acceptance-criteria limit has no ADR (M1). |
| 4 Consequences honest | pass | Each negative would hurt. Examples: ADR-002 line 65 (no review before the write), ADR-003 line 62 (reftable repos lose Fast Path), and ADR-010 line 87 (a mismatch now stops P7). ADR-004 line 60 overstates a positive (m3). |
| 5 Scope boundaries | pass | scope.md lines 66 to 73 exclude plausible work. Examples: seeding from `_done/` (line 67) and relaxing the root-file gate (line 68). |
| 6 Risks specific and mitigated | pass | R-001 to R-020 are specific, and each mitigation is an action. ADR-016 line 81 cites a suite case that req-007 never specifies (m4). |
| 7 NFRs measurable | pass | NFR-001 to NFR-005 (execution-plan lines 38 to 42) each give a number or a deterministic check. |
| 8 Internal consistency | pass with minors | No ADR contradicts a requirement or the design. ADR-006 line 32 matches req-004 lines 30 to 32. ADR-007 line 23 matches req-005 line 23. ADR-019 lines 27 to 31 match req-010 lines 27 to 40. Minor drift appears in m2, m5, and m6. |

## Findings (severity-ordered)

- [major] M1 `scope.md` line 62 and `design.md` line 43: the acceptance-criteria limit change has no requirement and no ADR.
  - Commits `c7e7642` and `bb2d692` already changed `consistency-check.mjs` and both governance suites. scope.md line 62 lists the change as In Scope.
  - No user story or requirement owns it, so rubric item 2 fails. It changes a gate that every later feature meets, so it is a significant decision. No ADR records the alternatives, such as keeping 3 and splitting stories (backlog 0000139).
  - Fix: write an ADR in a free ID, such as ADR-012. It records the limit of 10, the warning band of 4 to 10, the human instruction (build-log lines 124 and 146), and the rejected alternatives.
  - Fix: name an owner for the change. Either add a requirement with a source story, or record it in the build log as a P1 deviation outside the stories. Then cite the owner from scope.md line 62.

- [minor] m1 `adr/ADR-002-fast-path-scope-record-self-authorisation.md`, `adr/ADR-010-product-yml-set-in-p7-by-script.md`, and `adr/ADR-017-migration-records-owned-by-migrator.md`: none of them cites the requirement that owns its concern.
  - Fix: add "req-001 holds the record format, staleness, and the workflow step" to ADR-002 Context after line 20.
  - Fix: add "req-002 holds the P7 step and the script behaviour. req-008 holds its argument rules" to ADR-010 Context after line 22.
  - Fix: add "req-007 FR-007.4 holds the Record step, and req-010 writes this repo's records through it" to ADR-017 Context after line 18.

- [minor] m2 `adr/ADR-001-stack-unchanged-node-built-ins-no-spawn.md` line 55: "Five new suites" is stale. Stream 01 now adds six suites, one each for req-001, req-003 to req-006, and req-009.
  - Fix: change "Five new suites" to "Six new suites".

- [minor] m3 `requirements/req-009-fast-path-enforcement-paths.md` line 74 and `adr/ADR-004-fast-path-enforcement-path-list.md` lines 38 and 60: the parity check runs one way only.
  - It asserts that each `fast-path.md` entry appears in the constant. A constant entry missing from the doc passes.
  - AC 3 on line 80 says the two lists "match". ADR-004 line 60 says they "can't drift without a suite failure". Neither holds under a one-way check.
  - Fix: on req-009 line 74 and ADR-004 line 38, state that the source check asserts set equality in both directions.

- [minor] m4 `adr/ADR-016-per-project-migration-run-records.md` line 81: the mitigation cites a req-007 suite case that writes a record with no sentinel and no design. req-007 line 130 lists no such case, and AC-007.4 (line 140) doesn't require it.
  - Fix: add a case to req-007 FR-007.10 after line 130. It runs `gate-write.mjs` on a **Write** to `plan/_migrations/x.md` with no `plan/.orchestrator-active` and no design, and expects exit 0.

- [minor] m5 `requirements/req-010-migration-records-for-this-repo.md` line 44 and `feature-brief.md` line 144: "a record for each of the eight migrations, from a scan run here" contradicts FR-010.1 (line 29). The two downstream-only migrations get records without a scan. The same wording sits in the story on brief line 30, design.md line 21, and req-010 line 18.
  - Fix: on req-010 line 44 and brief line 144, write "from a scan run here for each of the six returning migrations, and a `not applicable` record for each downstream-only one". Leave the story text to the human on the loop, or apply the same change there.

- [minor] m6 `streams/stream-01-gate-rules.md` line 45: it says `path-rules-markedRoot-basename-distrust` feeds req-004. req-004 line 77 says the two changes land in either order, and req-006 line 55 says req-005 gains the rule.
  - Fix: on line 45, say the artifact feeds req-005 through `resolveRoot`.

- [minor] m7 `discovery.md` lines 31, 32, 35, and 40: cross-feature ADRs use the hyphen form, such as `0000032 ADR-004`, `0000033 ADR-009`, and `0000009-ADR-005`.
  - Fix: write `0000032 ADR 004`, `0000032 ADR 006`, `0000033 ADR 009`, and `0000009 ADR 005`.

- [minor] m8 ADR front matter, line 4 of each ADR: ADR-001 to ADR-011 read `status: "accepted"`, and ADR-015 to ADR-019 read `status: "proposed"`. Both sets wait on the same human gate.
  - Fix: use one status for all 15. `proposed` fits until the human on the loop confirms at the P2 gate.

## Notes, not findings

- req-007 holds the file layout and the run records in one requirement, with ADR-015 to ADR-018 behind it. The two concerns change together in every step, so a split would leave two requirements that can't ship apart. It needs no action.
- ADR-002 line 49 rejects "delete in the Fast Path commit" as the brief's wording. execution-plan line 92 and scope.md line 51 record that sharpening, so the trail is complete.
- ADR IDs 009 and 012 to 014 are unused. The stream id-blocks reserve them (stream-01 line 9, stream-02 line 9), so the gaps are expected.
