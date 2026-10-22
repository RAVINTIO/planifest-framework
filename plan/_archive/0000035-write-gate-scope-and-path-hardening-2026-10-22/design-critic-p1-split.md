# Design-Critic Verdict (P1 re-run after the req-002 split)
**Phase:** P1
**Mode:** on
**Mechanical check:** clean
**Overall:** APPROVE

```
consistency-check: clean
EXIT=0
```

The split is clean. Every line of the old req-002 (commit `1f1654c`) now sits in req-002 or req-008, and no check was lost. No critical or major finding remains. Five minor findings follow, and none blocks the gate.

## Split check

| Check | Result | Evidence |
|-------|--------|----------|
| No check lost | pass | Old req-002 lines 51 to 85 (carve-out and boot text) map to req-008 lines 25 to 59. Old ACs 4 to 6 map to req-008 ACs 1 to 3. Old Input Validation lines 113 to 131 map to req-008 lines 73 to 91. Old ACs 1 to 3 stay as req-002 ACs 1 to 3. |
| One concern per requirement | pass | req-002 holds the P7 step, the script behaviour, and the close-out suite. req-008 holds the carve-out, its limits, the argument rules, and the boot sentence. req-008 line 22 states the ownership boundary. |
| Cross-references | pass | req-002 lines 3, 29, 45, and 71 point to req-008. execution-plan lines 24, 30, 51, and 94 to 96 cite req-008. scope.md lines 44 and 59 to 61, risk-register R-020, domain-glossary line 24, and design.md line 40 cite req-008. ADR-011 line 20 names req-008. |
| No stale carve-out pointer to req-002 | pass | A grep of `plan/current/` finds no carve-out or Input Validation reference to req-002 outside the build log. Build-log lines 100 and 120 predate the split and line 152 records it. |
| Story trace | pass | US-008 appears in feature-brief line 28, design.md line 19, and stream-02 line 8. Brief ACs on lines 143 and 144 map to req-008 ACs 3 and 1. |
| Sanctioned list | pass | A grep of `planifest-framework/skills/` confirms the seven writers. `run-mode.mjs`, `product-version.mjs`, `consistency-check.mjs`, and `stream-reconcile.mjs` hold no file-write call. Template lines 14 and 20 match req-008 line 42. |

## Criteria counts

Every requirement holds exactly 3 checkbox criteria, so the check prints no warning. req-002 AC 1 (line 53) holds nine sub-cases under one checkbox. They all test the one script, so they form a single concern and need no split. The counter can't see sub-bullets, and backlog 0000139 already covers that gap.

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Each AC names an exit code, a file value, or a source check. Examples: req-002 lines 53 to 64, req-008 lines 63 to 65, req-003 lines 67 to 69. |
| 2 Traceability | pass | Each requirement has a `Source:` story on line 11. The 15 brief ACs (feature-brief lines 130 to 144) each map to a requirement AC. No story lacks a requirement. See m3 for one loose fit. |
| 3 ADRs record real decisions | n/a | ADRs are P2 artifacts and the P2 critic reviews them. ADR-010 line 58 and ADR-011 line 20 point to the right requirements after the split. |
| 4 Consequences honest | n/a | P2 scope. |
| 5 Scope boundaries | pass | scope.md lines 64 to 73 exclude plausible work, such as relaxing the root-file gate (line 70) and seeding from `_done/` (line 69). |
| 6 Risks specific and mitigated | pass | R-001 to R-020 are specific. R-020 (risk-register line 39) cites the req-008 rules as concrete actions. |
| 7 NFRs measurable | pass | NFR-001 to NFR-005 (execution-plan lines 36 to 40) each give a number or a deterministic check. |
| 8 Internal consistency | pass | req-008 matches execution-plan lines 94 to 96, scope.md lines 59 to 61, and ADR-011. design.md line 78 and scope.md line 13 agree with build-log line 152 on when the split happened. |

## Findings (severity-ordered)

- [minor] m1 `streams/stream-02-release-manifest.md` lines 33 and 37: the stream record predates the split in two places.
  - Line 33 says `SET-PRODUCT-RELEASE-SCRIPT` serves req-002 only. req-008 now adds the argument rules and the real-path check to that script.
  - Line 37 lists no consumed artifact. req-008 line 78 imports `resolveRoot` from `path-rules.mjs`, which stream 01 changes in parallel (execution-plan line 81).
  - Fix: on line 33, say the script serves req-002 and req-008 inside this stream. On line 37, list `path-rules.mjs` `resolveRoot` (existing export, signature unchanged) and cite req-008 line 70.
- [minor] m2 `requirements/req-008-sanctioned-scripts.md` lines 35 and 91: req-008 owns the real-path check, but its own suite has no link case. The only link case sits in the req-002 suite (req-002 line 62). req-002 line 71 states this, but req-008 doesn't.
  - Fix: add one sentence after req-008 line 35. It should say the req-002 close-out suite tests the link case. Or move that case into the req-008 suite list on line 91 and drop it from req-002 line 62.
- [minor] m3 `feature-brief.md` line 28 and `requirements/req-008-sanctioned-scripts.md` line 18: the US-008 story covers naming the sanctioned scripts. It doesn't cover the argument rules that make one script safe, yet brief AC line 144 and req-008 lines 73 to 91 sit under it.
  - Fix: widen the story's outcome in all three copies (brief line 28, design.md line 19, req-008 line 18). For example: "so that an agent never writes past the gates through any other script, and each named script writes only its own file."
- [minor] m4 `requirements/req-001-fast-path-scope-record.md` lines 54 to 81 and 137: req-001 is a candidate split. It holds the scope record and its admission rule. It also holds the enforcement list, which grows to hook wiring files, tool-local settings, `planifest-framework/setup/`, and `.git/`. Three ADRs back it (ADR-002, ADR-003, and ADR-004). AC 2 on line 137 packs the enforcement check and the staleness check into one checkbox.
  - Fix: offer the human on the loop a split. A new requirement would take `FAST_PATH_ENFORCEMENT_PATHS`, the wiring and settings lists, the `fast-path.md` parity check, and their suite cases. req-001 would keep the record, the git-state reader, and admission. If the human on the loop declines, split AC 2 into two checkboxes so the staleness check shows on its own.
- [minor] m5 `requirements/req-007-migration-run-state.md` lines 117 to 124, 137 to 143, and 149: req-007 is a candidate split. FR-007.9, FR-007.11, and AC-007.3 run the migrations in this repo and handle its findings. That is a one-off task with its own exception flow. The rest of req-007 changes framework behaviour.
  - Fix: offer the human on the loop a split. A new requirement would take FR-007.9, FR-007.11, and AC-007.3. req-007 would keep the file layout, the record format, and resume detection. If the human on the loop declines, record the reason in the build log.
