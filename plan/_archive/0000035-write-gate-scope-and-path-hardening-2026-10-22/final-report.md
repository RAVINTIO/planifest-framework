# Final Report - 0000035-write-gate-scope-and-path-hardening

> Written by the ship agent at P9 in `autonomous` mode. Line numbers point to `build-log.md` in this folder.

## 1. What shipped

Planifest 0.33.0 lets every sanctioned route pass the write gate, closes five ways past it, and keeps migration run state per project. It folds in ten backlog entries in one wave: 0000062, 0000081, 0000106, 0000107, 0000109, 0000114, 0000117, 0000124, 0000125, and 0000126.

- **Fast Path scope record:** `plan/.fast-path-scope` lists a Fast Path change's paths. The gates admit only those paths, and never an enforcement path or a non-ASCII target.
- **`product.yml` at P7:** `set-product-release.mjs` sets the release fields before the archive. Hard Limit 8 names the seven sanctioned scripts.
- **Path hardening:** the gates judge each target two ways, find the root without a cwd, and ignore planted root markers. `ratchet-check` now works from any folder.
- **Migrations:** files never move, and each project records runs in `plan/_migrations/`.
- **Criteria limit:** up to 10 acceptance criteria per requirement, with a warning from 4.

The run delivered ten requirements in three streams, with 16 ADRs. P5 closed two High bypasses in this feature's own code. The full suite passes 88 feature suites and 33 regression suites.

## 2. Decisions and deviations

The build log holds 42 `Decision` lines and 31 `Deviation` lines. The P6 deviation review classed 3 deviations altering. Each altering item also appears in part 6.

### Decisions

| Line | Phase | Decision |
|------|-------|----------|
| 63 | P0 | Re-record the autonomous anchor in a new commit, not a force push. |
| 103 | P1 | US-001, US-003 to US-006 share stream 01, because each changes `path-rules.mjs`. |
| 104 | P1 | One subagent writes the shared artifacts, and the orchestrator writes the execution plan after the join. |
| 105 | P1 | The scope record is line-based, capped at 16 KiB and 64 paths. |
| 106 | P1 | The gate reads git state from `.git` files and ignores the record when it can't. |
| 107 | P1 | The link hop limit is 40. |
| 108 | P1 | `set-product-release.mjs` carries the P7 `product.yml` update. |
| 109 | P1 | Migration outcomes are `applied`, `not applicable`, and `skipped`. |
| 110 | P1 | A migration with findings here gets no record and becomes an exception. |
| 117 | P1 | The enforcement list covers hook wiring, `hooks/adapters/`, and `.git/`. |
| 118 | P1 | The scope record is accepted self-authorisation with a stderr notice. |
| 119 | P1 | `set-product-release.mjs` also creates `product.yml` and owns `components[]`. |
| 121 | P1 | The seven sanctioned scripts. |
| 125 | P1 | Allow up to 10 criteria, prefer 3 (your instruction). |
| 147 | P2 | Warn from 4 to 10 criteria and still exit 0 (your instruction). |
| 152 | P2 | Split req-002, with req-008 taking the sanctioned-scripts rule (your instruction). |
| 153 | P2 | Reopen the P1 critic, then run the P2 critic over the existing work (your instruction). |
| 157 | P2 | Split req-001, with req-009 taking the enforcement list. |
| 158 | P2 | Split req-007, with req-010 taking this repo's own run. |
| 160 | P2 | req-009 joins stream 01, and req-010 joins stream 03. |
| 181 | P3 | One codegen agent per stream, with each stream's requirements in sequence. |
| 182 | P3 | Section ownership for shared files. The orchestrator bumps the version. |
| 183 | P3 | Each agent commits only its own paths. |
| 191 | P3 | The adoption-mode scan counts three archived designs as compliant. |
| 201 | P3 | Add `./README.md` to the design's component paths for FR-007.10. |
| 210 | P3 | Leave orchestrator skill line 161 as it is. |
| 230 | P4 | Semantic coverage and verify by execution run in parallel. |
| 235 | P4 | P7 reads the source ship skill, because the installed copy is stale. |
| 236 | P4 | The `resolveRoot` contract mismatch goes to the P6 deviation review. |
| 255 | P5 | Two security reviewers, gates and scripts, in parallel. |
| 258 | P5 | Fix the findings in this feature, in three agents by file ownership. |
| 273 | P5 | Fix the seven re-review findings in a second batch. |
| 283 | P5 | Send the seven round 2 items to backlog and stop the review rounds. |
| 307 | P6 | Three docs agents in parallel. |
| 312 | P6 | The orchestrator fixes the three drift items. |
| 313 | P6 | Reword four living-doc lines that named `_done/`. Fix the doc, never the check. |
| 314 | P6 | Keep the 0.33.0 setup-rerun migration as backlog 0000158. |
| 347 | P7 | Move the iteration log into the plan folder so it archives. |
| 350 | P7 | Promote the req-002 suite to the regression pack. |
| 351 | P7 | Promote the req-008 suite to the regression pack. |
| 356 | P7 | Move one misplaced P5 decision line back into the P5 block. |
| 377 | P8 | Fill the stale log fields the build assessment found. |

### Deviations

| Line | Class | Deviation |
|------|-------|-----------|
| 111 | altering | The scope record never enters a commit. The brief says the Fast Path commit deletes it. |
| 112 | additive | A missing cwd now blocks a write into `src/`, superseding a 0000032 assertion. |
| 116 | altering | A P1 fix agent wrote four plan files through Python, against Hard Limit 8. |
| 159 | additive (directed by you) | The acceptance-criteria limit and warning. ADR-012 records it. |
| 185 | additive | `product.template.yml` header names P7. |
| 186 | additive | Stricter `--create` argument checks when `product.yml` exists. |
| 187 | additive | `set-product-release.mjs` refuses any `product.yml` link. |
| 188 | additive | Unknown arguments named by position. |
| 195 | additive | `gate-write` blocked the README edit. Line 201 resolved it. |
| 196 | additive | The 0000005 governance suite and its copy expect the new migration layout. |
| 197 | additive | The 0000032 req-011 suite expects the new migration layout. |
| 198 | additive | Two more migration files now say "record the outcome". |
| 199 | additive | Stream 03 suites mark retired names for the residue check. |
| 200 | additive | Stream 03 also edited `project-operations.md`. |
| 204 | additive | The 0000032 req-006 suite expects exit 2 for a deleted cwd. |
| 205 | altering | `resolveRoot` fails open in one deleted-cwd case. |
| 206 | additive | The scope record step is a sub-step of `fast-path.md` step 1. |
| 207 | additive | Four ratchet suites unset `CLAUDE_PROJECT_DIR`. |
| 208 | additive | `resolveTarget` returns `outside` for a path too long to judge. |
| 209 | additive | The admitted-write notice text. |
| 263 | additive | P-S03 to P-S08 share one commit. |
| 264 | additive | `test-regression-pack.sh` uses a fixture tree. |
| 265 | additive | Escaping covers every gate message, not only the two named. |
| 266 | additive | `resolveTargetText` resolves from the cwd's real path. |
| 267 | additive | `ratchet-check` moved its check into `checkWeakening(...)`. |
| 268 | additive | The req-005 checklist line still names `resolveTarget`. |
| 275 | additive | The ratchet caps printed paths at `MAX_PATH_CHARS`. |
| 276 | additive | `shown()` prints U+2028 in the `\u{2028}` form. |
| 279 | additive | The one-link check also covers `--component` paths. |
| 280 | additive | `promote-to-regression.sh` writes through a temp file and a rename. |
| 327 | additive | Migrator Step 1b defines the framework source by the `product.yml` id. |

## 3. Version

`v0.33.0`, tagged at `c1614d6` and pushed.

## 4. PR

https://github.com/planifest/planifest-framework/pull/61, raised as a draft because exceptions wait.

CI result: `pending`. `gh pr checks 61` reported no checks on the branch when this report was written.

## 5. Clean tree

The Step 10b check found one leftover, `plan/changelog/0000035-write-gate-scope-and-path-hardening-2026-10-22.md`, from the PR-link edit. It passed the credential guard and went in as `1dec223`. The check then read `clean`. `gitleaks` isn't installed here.

## 6. Exceptions waiting

Eleven items wait for you. Each has my recommendation.

| # | Line | Item | Recommendation |
|---|------|------|----------------|
| 1 | 192 | `0001-date-format.md` found about 506 `YYYY-MM-DD` dates in 283 files. | Answer `none`. The house rule uses `YYYY-MM-DD`. |
| 2 | 193 | `0002-british-english.md` found about 870 American spellings in 307 files, mostly "artifact" in archived plans. | Answer `none`. Rewriting archived records changes history for little gain. |
| 3 | 194 | `retroactive-release-tags.md` found no tag on `6c145b5` (v0.14.0) and `928f1d4` (v0.15.0). | Confirm the mapping if it's right. Tagging is a visible change on the remote. |
| 4 | 317 | L111: the scope record never enters a commit. | Accept, and reword the brief criterion. |
| 5 | 318 | L116: four plan files written through Python. | Accept. The orchestrator checked the diff, and later critics reviewed the files. |
| 6 | 319 | L205: `resolveRoot` fails open in one deleted-cwd case. | Accept with backlog 0000146. It needs an unreadable folder on the cwd path and no `CLAUDE_PROJECT_DIR`. |
| 7 | 320 | L189: six `_done/` files moved back and the folder removed (`c9c45e7`). | Confirm. `cmp` proved each copy byte-identical. |
| 8 | 321 | L190: five `plan/_migrations/` records are the first data in the new format. | Confirm. |
| 9 | 322 | L191: three archived designs judged compliant. | Confirm. Each records a valid mode or needs none. |
| 10 | 323 | L277: backlog 0000147 deleted when P-N3 closed it. | Confirm. |
| 11 | 324 | L201: `./README.md` added to the design's component paths. | Confirm. req-007 required the README change. |

## Follow-ups

Each next step needs a track.

1. **Backlog 0000158 (Change Pipeline):** add a 0.33.0 migration that tells downstream projects to rerun setup. Until then, downstream projects keep the old hooks and miss this run's security fixes.
2. **Rerun setup in this repo after the merge:** run `setup.sh claude-code` in a new session. The installed `.claude/` hooks and skills predate this run, and the installed ship skill has no P7 `product.yml` step. A setup rerun changes no tracked file, so it needs no track.
3. **Backlog 0000153 (Change Pipeline):** apply your answers to the three migration exceptions and write their records.

Next: the human on the loop reviews and merges the PR.
