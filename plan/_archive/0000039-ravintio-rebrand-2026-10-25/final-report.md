# Final Report (0000039-ravintio-rebrand, 25 Oct 2026)

P9 is blocked. CI failed 4 of 13 checks on the head that P9 read, and the write gate stops the ship agent from fixing it. PR #71 is back in draft, and the `v0.37.0` tag exists only locally.

## 1. What shipped

Version 0.37.0 renames the framework to RAVINTIO (backlog 0000237). It has ten requirements and one scripted rename pass.

- The pack folder is `ravintio-framework/`, the overrides folder is `ravintio-overrides/`, and the 21 skills are `ravintio-*` (req-001, req-004, req-008).
- Markers and environment variables use `.ravintio-*` and `RAVINTIO_*` (req-002, req-003). Setup stops while the old pack, the old overrides folder, or an old setup marker exists.
- A consumer migration, `migrate-0.37.0-ravintio-rename`, ships with `.sh` and `.ps1` helpers (req-006, req-009). The helpers back up the old pack and never delete a folder. They rename the old marker files and skill folders and rewrite the manifest with a strict name rule.
- A brand guard suite fails on any old-brand hit outside its allowlist (req-007). P7 promoted it to the regression pack.
- History stays as written (req-005), and the version reads 0.37.0 (req-010).

The changelog is `plan/changelog/0000039-ravintio-rebrand-2026-10-25.md`. The test report is `plan/changelog/0000039-ravintio-rebrand-test-report-2026-10-25.md`. The build report is `plan/_archive/0000039-ravintio-rebrand-2026-10-25/build-report.md`.

## 2. Decisions and deviations

### Deviations

| Phase | Class | Deviation |
|-------|-------|-----------|
| P1 | additive | Split req-002 into req-008. |
| P1 | additive | Split req-006 into req-009. |
| P1 | additive | Split req-004 into req-010, with a new US-004. |
| P1 | additive (process breach) | The critic revision agent edited nine `plan/current/` files with a Python one-liner, so `ratchet-check` never ran (Hard Limit 8). Backlog 0000238. |
| P2 | additive, destructive flag | The helper leaves the two setup marker files for setup and removes only `.planifest-session`. `Applies when:` also names the backup folder. |
| P3 | additive | `design.md` gained a `## Component Paths` section. |
| P3 | additive, destructive flag | The scripted rename pass ran once, the Hard Limit 8 exception ADR-008 records. The human on the loop approved it at P0. |
| P3 | additive | The version bump landed in P3, not P6. |
| P4 | additive | The orchestrator opened the PR as a draft in P4, so CI could run the Windows and PowerShell legs. |
| P5 | additive | The M-002 fix changed the branch-protection warning and the workflow `name:` rewrite. |
| P6 | additive | ADR-004 gained two old-name reads, and ADR-005 names the marker-file removal. |
| P6 | **altering, destructive** | Row 12: the human on the loop directed the marker rename. The helper renames both old marker files in eight tool folders and rewrites the manifest. Setup drops both old-name reads and stops while an old marker exists. This is a gross deviation (item 2). |
| P4 rerun | additive | D-1: `setup.sh` writes real manifest paths. |
| P5 rerun | additive, destructive flag | The helper's manifest name rule grew through M-001 to M-003 and N-003 to N-004. The helper deletes its own temporary files. |
| P5 rerun | additive | The Linux and macOS CI legs get 15 minutes, not 10. |
| P5 | process breach | The third re-review agent changed one line with `sed -i` (Hard Limit 8). Backlog 0000238. |

### Decisions

- P1: one stream, because every requirement depends on the rename pass.
- P1: backlog IDs 0000246 to 0000255 went to the drafting subagents.
- P1: req-006 kept its criteria at four, then at five. req-002 kept four.
- P1: req-004 moved its version criteria to req-010.
- P1: the design's Out line gained a clarifying sub-line, because the ratchet blocked a rewrite.
- P1: a spec revision agent fixed the critic iteration 1 findings, and the orchestrator fixed the files it owns.
- P1: later dispatch prompts name the ban on interpreters and shell writers.
- P1: the split lines stayed `unclassified` until the deviation review.
- P1: the deferred moves ran through Edit after the critic loop closed.
- P1: loop-state timestamps were corrected to the commit times.
- P1: no new component manifest, no OpenAPI spec, and no operational model.
- P1: `src/setup-hook-integration/component.yml` keeps its id and name.
- P1: the pack folder is `ravintio-framework/`, and the brand guard lives in its `tests/` folder.
- P1: the two `test-0000030` telemetry-absence suites keep the old telemetry variable names.
- P2: ten ADRs, one drafter each in one batch.
- P2: NFR-003 and ADR-009 also check `plan/backlog/*/_reference/`.
- P2: the stale marker wording was fixed across the ADRs and the glossary.
- P3: three stages, with req-002 and req-008 in one track.
- P3: new 0000039 tests use post-pass names, and the pass skips their content and `plan/current/`.
- P3: three files are recorded as a delete plus an add.
- P3: the prose rule for "RAVINTIO Framework", "RAVINTIO", and `Ravintio` identifiers.
- P3: the vendored "Planifest Framework Contributors" lines stay as written.
- P3: the em-dash guard accepts the old sentinel through 0.x.
- P3: the stage 3 tracks add the old-name reads, each with its own RED test.
- P3: the three held-back files kept their old paths until the human on the loop cleared them.
- P3: req-004 needed no implementer.
- P3: the presence banners keep their own form, with no `[RAVINTIO]` prefix.
- P3: the req-003 inventory skips every `test-0000039-*` suite.
- P3: one refactor pass across all stage 3 tracks.
- P4: the migration doc tells consumers to check their own override files.
- P4: the orchestrator showed the two `cso/SKILL.md` lines at the human on the loop's request.
- P4: the three cleared files moved as R100 renames, and the held-back fixture went.
- P4: the merge commit used a plain `git commit`.
- P5: two fresh-context reviewers in parallel.
- P5: N-006 became backlog 0000270, and the P5 loop closed after the fourth round.
- P5 rerun: one strict name allowlist in both helpers. Backlog 0000255 stays out of scope.
- P6: three docs subagents in one batch.
- P6: the req-010 classifier accepts either word order for the 1.0.0 removal.
- P6: the decisions index cites the Write-or-Edit rule by name.
- P6: the scripted pass needs no new exception item.
- P6: the helper renames both old marker files and the listed skill folders, as the human on the loop directed.
- P6: the change reopened P3 to P5 for req-002 and req-006.
- P3 reopened: the helper rewrites a manifest whenever the checked form differs.
- P6: the 15-minute CI cap gets no new ADR.
- P6: three parallel batches for re-reviews, the cross-model review, and CI.
- P6: all six cross-model findings fixed in one batch of three streams.
- P7: P7 to P9 follow the `autonomous` procedure, although `run-mode.mjs` prints `interactive`. The P4 merge from `main` (1fffd812) un-anchors the mode. Backlog 0000273.
- P7: `test-0000039-req-005-history-and-split-name-protection.sh` not promoted, because it checks a one-off pass.
- P7: `test-0000039-req-006-consumer-migration.sh` not promoted, because the helpers ship only through 0.x.
- P7: `test-0000039-req-007-brand-guard.sh` promoted by `agent`, because it guards a standing rule.
- P9: Option [1], push and update the existing PR.
- P9: `gh pr ready 71`, then `gh pr ready --undo 71` after CI went red.
- P9: hold the `v0.37.0` tag locally until the fix lands.

## 3. Version

0.37.0. The tag `v0.37.0` exists locally at dd71693a and is not pushed. After the fix, delete it locally, create it again at the new head, and push it.

## 4. PR

https://github.com/RAVINTIO/planifest-framework/pull/71, open, draft.

CI on the head that P9 read (3962ab5b, run 40197746564): 4 failed, 9 passed.

| Check | Result | Link |
|-------|--------|------|
| Test suite (ubuntu-latest) | red | https://github.com/RAVINTIO/planifest-framework/actions/runs/40197746564/job/121182174930 |
| Test suite (macos-latest) | red | https://github.com/RAVINTIO/planifest-framework/actions/runs/40197746564/job/121182174644 |
| Test suite (windows-latest, shard 1 of 7) | red | https://github.com/RAVINTIO/planifest-framework/actions/runs/40197746564/job/121182174804 |
| Test suite (windows-latest, shard 3 of 7) | red | https://github.com/RAVINTIO/planifest-framework/actions/runs/40197746564/job/121182174711 |

Cause: the P7 regression copy of the brand guard names the retired telemetry variable. Two suites skip `tests/test-0000039-*` but not `tests/regression/test-0000039-*`:

- `ravintio-framework/tests/test-0000039-req-003-environment-variables.sh`
- `ravintio-framework/tests/test-0000030-req-001-002-removed-files-and-residue.sh`

The P7 local run passed, because both suites read tracked files and the copy was not yet committed. P9 tried to add the skip lines, and `gate-write` refused: "No confirmed design at plan/current/design.md. Complete Phase 0 first."

## 5. Clean tree

Clean. Step 10b committed one leftover, the archived build log, in 3962ab5b. After the final report commit, the scoped `git status --porcelain` check lists nothing.

## 6. Exceptions waiting

- **Exception waiting (P9, 6):** CI is red on 4 test jobs after the P7 promotion, and the write gate blocks the P9 fix. Fix it through the Fast Path or the Change Pipeline. Option one adds `tests/regression/test-0000039-*` to the skip rules in the two suites above. Option two undoes the promotion. Then rerun CI, mark the PR ready, and push the tag.
- **Gross deviation (item 2), destructive (item 1):** deviation row 12, the marker rename. The human on the loop directed it at P6. Confirm it at review.
- **Destructive flag (item 1):** deviation rows 5, 7, and 14. Row 7 is the scripted rename pass from P3, which the human on the loop approved at P0.
- **Hard Limit 8 breaches:** the P1 Python one-liner and the P5 `sed -i` slip. Backlog 0000238 tracks both.
- **Backlog 0000255:** the older manifest prune in setup stays unguarded. Security reviewers raised it four times.
- **Backlog 0000273:** the P4 merge from `main` un-anchors the autonomous run mode, so `run-mode.mjs` reads `interactive`.
- **Cleared:** the four `Exception waiting (P3, 7)` credential sightings, cleared by the human on the loop at P4. `Exception waiting (P6, 1)`, resolved by the human on the loop's direction.

After the merge, run `gh repo rename ravintio-framework` (backlog 0000260). Route it through the Fast Path, because it changes no file.

Next: the human on the loop reviews and merges the PR.
