# Deviation Review

Feature: 0000038-token-efficiency-windows-shard. Reviewer: fresh-context `planifest-reversal-assessor`. Compared each line with `plan/current/design.md` (Problem, Users, Scope In and Out).

| # | Build-log line | Class | Flags | Exception-list item | Evidence |
|---|----------------|-------|-------|---------------------|----------|
| 1 | Deviation (P1): commit `0411efd` reworded a req-005 acceptance criterion through a Bash edit | additive | none | no (process breach goes to the human on the loop, see below) | `git show 0411efd` changes three lines in req-005. Each swaps "0000032 ADR-003" for "which feature 0000032 set". The criterion still pins the unchanged after-P9 blocking reset, and the design constraint for US-005 says the same. Problem, users and scope are untouched. |
| 2 | Deviation (P1): acceptance-criteria count rose from 21 to 29 | additive | none | no | The design confirms 21 criteria, three per story. The extra eight sit in req-003, req-004 and req-006 and tighten existing stories. No story, user or in-scope item is added. |
| 3 | Deviation (P3): setup rewrites `../standards/` links in skill reference files, in `setup.sh` and `setup.ps1` | additive | none | no | Design Deployment says framework files ship through the setup scripts. US-004 moves text into reference files, and without the rewrite every install holds broken links. The change serves US-004 and adds no story. |
| 4 | Deviation (P4): warm-up pattern also covers the 0000035 req-005 10-link ratchet check | additive | none | no | The design's warm-up applies to timed suites and keeps the 200 ms limit with no retry. The extra suite gets the same treatment. Out of scope stays intact because no limit is raised or removed. |
| 5 | Deviation (P5): L4 fix also changes the existing `SKILL.md` read in `setup.ps1` | additive | none | no | The same encoding bug affected a second read in a file already touched by deviation 3. It repairs existing behaviour and changes no gate, user or story. |
| 6 | Deviation (P6): `test-0000037-req-009-portability-lint.sh` fails on two lines added at P5 | additive | none | no | A test-file lint finding. The fix is a line edit or a `# portable-ok` marker, and no assertion weakens. Scope and users are untouched. |

## Req-005 bypass (line 1)

I class line 1 as additive. The diff shows a citation rewording and no change in meaning.

The bypass itself still needs the human on the loop's review. The edit broke Hard Limit 8, skipped `ratchet-check`, and no `.ratchet-approve` line covers it. A correct classification of the content does not excuse the process breach. The human on the loop should decide whether to accept the change, and the orchestrator must not write the approval marker.

## Altering, schema or destructive items

None. No line is altering. No recorded decision touches a schema or a destructive operation. The P1 decisions on data state that no data changes, and deleting backlog 0000230 is in the confirmed scope. The only exception-list item to raise is the line 1 process breach, for review by the human on the loop.
