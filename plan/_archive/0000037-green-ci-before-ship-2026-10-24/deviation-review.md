# Deviation Review

Feature: `0000037-green-ci-before-ship`. Reviewer: fresh-context `planifest-reversal-assessor`, REJECT-default.

Baseline: `plan/current/design.md`, confirmed on 24 Oct 2026 at 12:46 AM BST, plus the four P0 Scope Lock answers in the build log.

The build log holds 14 `Deviation (P{N}, unclassified)` lines, not 16. A grep for `Deviation (P` finds lines 130, 143, 157, 187, 222, 227, 231, 237, 240, 245, 260, 273, 339, and 385. The P5 Scope Lock line sits at 385, not 383. Line 383 is a P6 decision.

## Verdicts

| # | Build-log line | Class | Flags | Exception-list item | Evidence |
|---|----------------|-------|-------|---------------------|----------|
| 1 | 130: Deviation (P1): backlog 0000193 and 0000199 move to Deferred, and the brief's goal now covers the head P9 read | altering | none | yes | The confirmed design says `Deferred: nothing deferred`. The accepted happy-path Scope Lock says the run reads as done only when all checks pass. `feature-brief.md` line 15 now limits the goal to the head P9 reads. `scope.md` lines 39 and 40 admit an unread CI run after the Step 11 push, and a req-008 check that skips in CI. Both narrow the confirmed scope. |
| 2 | 143: Deviation (P1): `design.md` gains the run-level "CI before P4" step with a draft PR | additive | none | no | The step adds a run-level process and no in-scope item. The shipped framework text doesn't change. `custom-001` allows `gh pr create` without asking. The body cites paths only and passes `credential-scan.mjs --file` first. The agent still never merges or pushes to `main`. |
| 3 | 157: Deviation (P1): the `gh` assumption now says the run doesn't read as done | additive | none | no | The edit brings the `## Assumptions` bullet in line with the red-check handling confirmed at P0. It restores what the human confirmed and changes nothing else. |
| 4 | 187: Deviation (P2): the P9 poll window becomes the longest job cap plus 10 minutes, so 30 minutes in ADR-014's 20 branch | altering | none | yes | The confirmed latency target says P9 waits at most 20 minutes. The accepted happy-path Scope Lock says P9 waits up to 20 minutes. The 20 branch fired at P3 (build log line 244), so the shipped window is 30 minutes. `req-001` lines 23 to 24 and the `Amended (P2)` design line show the change. When unsure, the assessor classes it as altering. |
| 5 | 222: Deviation (P3): the req-006 inline-text fixture case uses text assertions on the skill rule | additive | none | no | ADR-008 makes the requirement-ID scan an agent check with no script, so no runnable fixture can exist. The criterion and the in-scope item stay as confirmed. |
| 6 | 227: Deviation (P3): `setup.ps1` replaces one `` `u{2705} `` escape with `$([char]0x2705)` | additive | none | no | The design confirms Windows PowerShell 5.1 as a supported runtime for `setup.ps1`. The edit serves that item, and PowerShell 7 output doesn't change. |
| 7 | 231: Deviation (P3): the P8 guard calls `credential-scan.mjs` in place of inline `grep` and `gitleaks` | additive | none | no | req-003 makes the script the one pattern list. Decision line 232 moved the five `test-0000033-req-013` assertions to the script. P5 then made both suites run the script on a fixture for every rule (build log line 326). No protection was lost. |
| 8 | 237: Deviation (P3): the intermittent `test-0000035-req-001` failure didn't reproduce, so backlog 0000200 tracks it | additive | none | no | FR-009.2 in `req-009` already says to record the finding in a backlog entry when the cause isn't a working-directory dependence. Backlog `0000200-fast-path-scope-suite-intermittent-failure` exists. The deviation follows the confirmed requirement. |
| 9 | 240: Deviation (P3): the docs-agent skip case keeps the old `Post-P6 revalidation: skipped, no P6 edits` phrase, marked as replaced | additive | none | no | The old phrase stays so the 0000033 req-014 suite still passes. The new post-P6 revalidation behaviour ships as confirmed. |
| 10 | 245: Deviation (P3): the Windows leg shards four ways, each shard capped at 20 minutes | additive | none | no | The confirmed `## Risks` mitigation names sharding as the second fallback after the 20-minute cap. The in-scope Git Bash leg stays. CI minutes rise past the cost boundary and R-013, so the final report should state the cost. |
| 11 | 260: Deviation (P3): the Windows leg moves from four shards to seven, and CI jobs per PR rise from 10 to 13 | additive | none | no | The same confirmed sharding fallback covers this change. It only rebalances the shards (build log line 259). The problem, the users, and the in-scope list stay as confirmed. The final report should state the extra CI jobs. |
| 12 | 273: Deviation (P3): the req-001 execution check covers the read command and the exit-1-with-JSON case, not the whole poll | additive | none | no | ADR-001 puts the poll in skill text with no script. P4 cycle 2 then ran the real `gh pr checks` and fixed the empty-list case (build log line 298). The confirmed criterion stays. |
| 13 | 339: Deviation (P5): the ship skill keeps the old path-list commit lines as labelled references beside the pathspec commands | additive | none | no | The old lines stay as labelled references for `interactive` and `continuous` so earlier suites still pass. The `autonomous` commit path uses the new scan-then-commit procedure. No in-scope item changes. |
| 14 | 385: Deviation (P5): the cross-session Scope Lock answer said a stopped commit leaves files staged. A held-back file now leaves the index | altering | none | yes | The human accepted the cross-session Scope Lock answer "a stopped commit leaves files staged with the path named". The shipped `### Scan-then-commit` unstages held-back paths with `git restore --staged` instead (build log lines 325 to 338). That reverses an accepted answer. The fix for F-04, N-07, and N-09 is sound, but the human must approve the new behaviour. Unstaging changes only the index, and the file stays on disk, so it isn't destructive. |

## Data, schema, and destructive decisions

No recorded decision changes a schema. No decision drops, deletes, or renames data. The run adds no data store (Decision line 101).

| Build-log line | Topic | Class | Flags | Exception-list item | Evidence |
|----------------|-------|-------|-------|---------------------|----------|
| 101: Decision (P1): no data contract, OpenAPI spec, or data store | data | additive | none | no | The design lists no data store. GitHub state is read only. |
| 113: Decision (P1): a held-back file stays staged | index state | covered by row 14 | none | covered by row 14 | P5 replaced this decision. Row 14 carries the exception. |
| 337 to 338: Decision (P5): scan-then-commit with `--safe-paths` and `git commit --pathspec-from-file` | index state | additive | none | no | An empty pathspec file commits the whole index. Every commit line therefore starts with `[ -s "{out-file}" ] &&` (build log line 345). Only staged-new held-back paths leave the index, so tracked files are never removed. |

## Counts

| Class or flag | Count | Rows |
|---------------|-------|------|
| altering | 3 | 1 (line 130), 4 (line 187), 14 (line 385) |
| additive | 11 | 2, 3, 5 to 13 |
| schema | 0 | none |
| destructive | 0 | none |
| Exception-list items | 3 | 1, 4, 14 |
