# Deviation Review

Feature: 0000039-ravintio-rebrand. Reviewer: `ravintio-reversal-assessor`, fresh context, not the maker. Baseline: `plan/current/design.md`, confirmed 2026-10-25 at 02:12 GMT.

This feature has no database, so no line carries the `schema` flag. A line that renames or removes files carries the `destructive` flag.

| # | Build-log line | Class | Flags | Exception-list item | Evidence |
|---|----------------|-------|-------|---------------------|----------|
| 1 | Deviation (P1): split req-002 into req-008. Both trace to US-001. design.md Skill Map gains a REQ-008 row. | additive | none | no | The confirmed in-scope item "the rename map" covers emitted names. The split moves criteria between files and adds no scope. |
| 2 | Deviation (P1): split req-006 into req-009. Both trace to US-002. design.md Skill Map gains a REQ-009 row. | additive | none | no | Migrator order, old-path mapping, and `Applies when:` sit in confirmed migration steps 1 and 7. No new behaviour. |
| 3 | Deviation (P1): split req-004 into req-010 (version bump). A new US-004 splits US-001 and adds no scope. | additive | none | no | The 0.37.0 bump is a confirmed in-scope item and the confirmed Version line. US-004 restates it as a story. Users and problem are unchanged. |
| 4 | Deviation (P1): the critic revision agent edited nine `plan/current/` files with a Python one-liner, not Edit, so `ratchet-check` never ran (Hard Limit 8). | additive | none | no | A process breach, not a design change. The orchestrator diffed the edits and found no acceptance-criteria or in-scope line removed. Backlog 0000238 tracks it. The human on the loop should still see it in the run summary, because a hard limit failed. |
| 5 | Deviation (P2): the helper leaves `.planifest-setup-flags` and `.planifest-manifest` for setup, and removes only `.planifest-session`. `Applies when:` also names `.ravintio-backup/planifest-framework/`. | additive | destructive | yes | Confirmed step 3 says the helper removes the old markers, and confirmed old-name reads say setup reads and removes `.planifest-setup-flags`. The change moves two removals from the helper to setup and keeps the end state. One new removal: setup now reads and removes `.planifest-manifest`, which the confirmed design did not list. It is a pack-owned marker (ADR-010), and setup already prunes skills the pack no longer ships (R-016). No new human decision is needed. |
| 6 | Deviation (P3): design.md gains a `## Component Paths` section listing the old and new pack and override folders, `src/setup-hook-integration/`, `.github/workflows/`, `.claude/skills/`, `docs/`, and four root files. | additive | none | no | Every listed path is a target of the confirmed rename map or a confirmed component. The section restates scope in the form `gate-write` reads and adds no path outside it. |
| 7 | Deviation (P3): the scripted rename pass ran once at 2026-10-25T03:03:18Z, the exception to Hard Limit 8 that ADR-008 records. 1,181 renames, 405 files changed, 1,086 protected files skipped. | additive | destructive | yes | The confirmed "Bulk rename method" records the human on the loop's P0 approval of one scripted pass. The run matches it: one run, `git mv`, protected list, setup re-run in one commit. It renames files, so it stays on the exception list. The build log already records the human decision, so no new decision is needed. |
| 8 | Deviation (P3): the version bump landed in P3, not P6 as req-010 states. | additive | none | no | The confirmed design fixes the version, 0.37.0, not the phase that writes it. Only timing changed. |
| 9 | Deviation (P4): the orchestrator opens the PR as a draft in P4, so CI runs the Windows shards and both PowerShell legs before P5. P9 marks the PR ready. | additive | none | no | A pipeline-process change. Problem, users, and in-scope list are unchanged. The PR stays unmerged, as `custom-005` requires. |
| 10 | Deviation (P5): the M-002 fix changed the migration's branch-protection warning and made the helper rewrite the workflow `name:` line. design.md gains a P5 correction sub-line, and R-007 reads mitigated. | additive | none | no | Confirmed step 6 promises a branch-protection warning. Its wording named the wrong check. The fix keeps the warning's purpose and makes it correct. Confirmed step 2 already has the helper rewrite the pack's own names in the workflow, and the rename map names `RAVINTIO Strict Pipeline`. |
| 11 | Deviation (P6): ADR-004 gains the two old-name reads, and ADR-005 now names the one marker-file removal. | additive | none | no | Documentation catches up with built code (Hard Limit 7). The two reads (old em-dash sentinel, old enforcement paths) widen compatibility through 0.x and remove nothing. The marker removal is the confirmed step 3 behaviour. |

## Data and destructive decisions

| Decision | Needs a new human on the loop decision | Evidence |
|----------|----------------------------------------|----------|
| Scripted rename pass (P0 exchange, P3 run) | no | The human on the loop approved it at P0. design.md and ADR-008 record it. The run matched the approved method. |
| Pass skips `plan/current/`, and three files land as delete plus add (P3) | no | History and plan text stay as written, which the confirmed constraints require. The delete-plus-add files are git similarity artefacts with content kept, and a fixture lists them. |
| Setup prune of the 21 old `planifest-*` skill copies, read from `.planifest-manifest` (P2, P3, P5 S-01) | no | Setup already prunes skills the pack stops shipping (R-016). The copies are setup output, not consumer data. The P3 refactor unlinks a linked folder and never recurses into it. Backlog 0000255 and 0000259 track the remaining edge cases. |
| Helper marker removal, `.planifest-session` only, plus the same delete in `archive-current.mjs` (P2, P3) | no | Confirmed step 3 removes old markers. The P2 change narrows what the helper removes. The marker is pack-owned (ADR-010). |
| Held-back file clearance (P3, P4) | no | The human on the loop cleared the three files on 2026-10-25, and the build log records the words used. |
| External-skills moves to `ravintio-framework/external-skills/` as R100 renames (P4) | no | They follow the human clearance and the confirmed rename map. Content stays byte-identical, which keeps vendored text as written. |
| Merge of `origin/main` took main's deletion of backlog 0000096 (P4 cycle 1) | no | The deletion came from `main`, which the human on the loop merged. This feature made no delete of its own. |

## Result

All 11 lines are additive. None alters the confirmed problem, the users, or the in-scope list. Lines 5 and 7 carry the `destructive` flag, so they go on the exception list. Each already has a recorded basis, and neither needs a new human on the loop decision. Line 4 needs no decision but belongs in the run summary as a Hard Limit 8 breach.
