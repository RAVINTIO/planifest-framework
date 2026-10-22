# Deviation Review

Feature: `0000035-write-gate-scope-and-path-hardening`. Reviewer: fresh-context `planifest-reversal-assessor`, end of P6, run mode `autonomous`.

Baseline: `plan/current/design.md` as the human on the loop confirmed it at P0, its "Decisions added at P1" section, and `plan/current/feature-brief.md`. Each row compares a build-log line with that baseline. Rows 1 to 30 are deviation lines. Rows 31 to 39 are recorded decisions that touch data, a schema, or a destructive operation.

## Summary

| Class or flag | Count |
|---------------|-------|
| additive | 34 |
| altering | 5 |
| schema | 1 |
| destructive | 2 |
| Exception-list items | 8 |

## Verdicts

| # | Build-log line | Class | Flags | Exception-list item | Evidence |
|---|----------------|-------|-------|---------------------|----------|
| 1 | L111: the scope record never enters a commit, and Fast Path removes it before `git commit` | altering | none | yes | P0 design and brief AC (brief line 134) say the Fast Path commit deletes the record. The built workflow removes it before the commit instead. The brief AC still carries the old wording. |
| 2 | L112: a missing cwd now blocks a write into `src/`, superseding a 0000032 test assertion | additive | none | no | US-004 and the P0 fail-closed line ask for exactly this block. Only an older test expectation changes. |
| 3 | L116: a fix agent wrote four P1 artifacts through a Python script, breaking Hard Limit 8 | altering | none | yes | The confirmed constraints list Hard Limit 8. The orchestrator checked the diff by hand, but the confirmed write rule was not kept. Unsure, so altering. |
| 4 | L159: `consistency-check.mjs` allows up to 10 criteria and warns from 4 to 10 | additive | none | no | No P0 story covers it. The human on the loop directed it in the P1 and P2 exchanges (L124, L146). `design.md` "Decisions added at P1" and ADR-012 record it. |
| 5 | L185: `product.template.yml` header comment names P7 and `--create` | additive | none | no | A comment change outside the stream file list. It keeps new `product.yml` files in step with the confirmed P7 update. |
| 6 | L186: `set-product-release.mjs` validates `--create` arguments even when `product.yml` exists | additive | none | no | The P0 design doesn't cover `--create`. The change tightens input checks. req-002 now records it (line 48). |
| 7 | L187: `set-product-release.mjs` refuses any `product.yml` link, dangling ones included | additive | none | no | With a real-path root every link resolves elsewhere, so this matches req-008 in effect. It fits US-003 and US-008. |
| 8 | L188: an unknown argument is named by position | additive | none | no | It changes stderr wording only. No raw value reaches the log. |
| 9 | L195: `gate-write` blocked the FR-007.10 `README.md` edit, and the suite held a comment | additive | none | no | A temporary gap. L201 closed it, and row 39 reviews that decision. |
| 10 | L196: the 0000005 governance suite and its copy expect the new migration layout | additive | none | no | The tests follow the confirmed P0 decision that the `_done/` folder goes away. |
| 11 | L197: the 0000032 req-011 suite asserts no `_done/` and a `## Record` heading | additive | none | no | The test follows the confirmed migration-state decision. |
| 12 | L198: two migrations now say "record the outcome", not "archive it" | additive | none | no | It follows the confirmed rule that migration files never move. The files sat outside the req-007 list. |
| 13 | L199: stream 03 suites wrap migration names in `retired-integrations` markers | additive | none | no | A test-only change so the 0000030 residue check passes. |
| 14 | L200: stream 03 also edited `project-operations.md` | additive | none | no | FR-007.10 requires the edit. It serves the confirmed US-007. |
| 15 | L204: the 0000032 req-006 suite expects exit 2 for a deleted cwd writing `src/a.js` | additive | none | no | Same change as row 2. req-004 planned it at P1. |
| 16 | L205: `resolveRoot` returns `null` when the cwd walk fails at `realpathSync` and `CLAUDE_PROJECT_DIR` gives no root | altering | none | yes | US-004 says the gates never fail open on a write into `src/` after the cwd is gone. This case still fails open with exit 0. Backlog 0000146 tracks it. Unsure, so altering. |
| 17 | L206: `fast-path.md` writes the scope record in a sub-step of step 1 | additive | none | no | Layout only. The confirmed behaviour holds and the cited step numbers stay. |
| 18 | L207: ratchet suites gained `unset CLAUDE_PROJECT_DIR` | additive | none | no | A test isolation fix outside the req-005 list. It follows the confirmed US-005 change. |
| 19 | L208: `resolveTarget` returns `outside` for a path too long to judge | additive | none | no | It keeps the existing warn-and-allow result. Both gates check the length limit first, so the gates don't reach this case. |
| 20 | L209: the admitted-write notice wording differs from the req-001 example | additive | none | no | The P1 decision asks for a stderr notice. The wording was only an example. |
| 21 | L263: P-S03 to P-S08 share one commit | additive | none | no | Commit granularity only. Nothing the human confirmed changes. |
| 22 | L264: the regression-pack suite and its copy use a fixture tree | additive | none | no | `promote-to-regression.sh` no longer lets `PLANIFEST_REGRESSION_DIR` move the destination (`eb09fc8`). That binding serves US-008, so each script writes only its own file. |
| 23 | L265: G-S11 escaping also covers five more stderr messages | additive | none | no | It widens a P5 hardening fix. It stops forged log lines and changes no confirmed rule. |
| 24 | L266: `resolveTargetText` resolves from the cwd's real path | additive | none | no | An implementation detail of the confirmed US-003 link rule. |
| 25 | L267: `ratchet-check.mjs` moves its check into `checkWeakening(...)` | additive | none | no | A refactor so the hook can judge two placements. Behaviour matches US-005. |
| 26 | L268: the req-005 checklist line still names `resolveTarget` | additive | none | no | Documentation only. A new FR line explains `resolveTargetBoth`. |
| 27 | L274: the ratchet caps printed paths at `MAX_PATH_CHARS`, not 80 | additive | none | no | Output length only. The `.ratchet-approve` hint line stays whole. |
| 28 | L275: `shown()` prints U+2028 as `\u{2028}` | additive | none | no | Escaping detail inside a P5 fix. |
| 29 | L278: the one-link `component.yml` check also covers `--component` paths | additive | none | no | It widens a P5 hardening check in the same script. |
| 30 | L279: `promote-to-regression.sh` writes through a temp file and Node `renameSync` | additive | none | no | It serves US-008. The Node built-ins rule (0000032 ADR 004) covers hooks, not this script. |
| 31 | L189: six `_done/` files returned by **Write**, `cmp`, and `git rm`, and the `_done/` folder removed (`c9c45e7`, ADR-015) | additive | destructive | yes | The P0 design confirmed this move. The step still deletes and renames tracked files, so it carries the destructive flag. `cmp` showed each copy identical. |
| 32 | L190: five run records written to `plan/_migrations/` (`afd2378`, req-010) | additive | schema | yes | The P0 design confirmed the records and the `not applicable` outcome for the two downstream-only migrations. The records are the first data in a new record format that resume detection reads. |
| 33 | L191: the adoption-mode scan counts three archived designs as compliant | altering | none | yes | The confirmed design says a scan with findings records nothing until the human on the loop confirms. The agent judged three edge cases compliant and wrote `applied` with 0/0. Unsure, so altering. |
| 34 | L192 to L194: three migrations left with no record (`0001-date-format.md`, `0002-british-english.md`, `retroactive-release-tags.md`) | additive | none | no | This follows the confirmed exception flow. Each already waits for human review in the build log. AC-010.1 stays deferred to the human on the loop. |
| 35 | L277: `git rm` of backlog entry 0000147 in `7bce6e9` | additive | destructive | yes | P-N3 closes the entry inside this feature. The commit still deletes a tracked file, so it carries the destructive flag. |
| 36 | L152: req-002 split into req-002 and req-008 (US-008) | additive | none | no | The human on the loop directed the split (L151). The scope and the criteria stay the same. |
| 37 | L157: req-001 split into req-001 and req-009 (US-009) | additive | none | no | The human on the loop asked for a split whenever criteria grow. The enforcement-path rule was already a confirmed P0 decision. |
| 38 | L158: req-007 split into req-007 and req-010 (US-010) | additive | none | no | Same instruction as row 37. The P0 scope already listed a record for each of the eight migrations. |
| 39 | L201: `./README.md` added to the `design.md` Component Paths at P3 | altering | none | yes | The human on the loop confirmed the Component Paths list at P0. The addition widens what `gate-write` admits for this feature. req-007 FR-007.10 needs it, but no human confirmed the change. |

## Exception list

| # | Build-log line | Decision for the human on the loop |
|---|----------------|------------------------------------|
| 1 | L111 | Accept that the scope record is removed before the commit and never committed. If you accept, the brief AC at line 134 needs new wording. |
| 3 | L116 | Accept the four P1 artifacts written through a Python script, or have them re-checked. |
| 16 | L205 | Accept the remaining fail-open case in `resolveRoot`, with backlog 0000146 as follow-up, or require a fix before ship. |
| 31 | L189 | Confirm the six `_done/` file moves and the removal of the `_done/` folder. |
| 32 | L190 | Confirm the `plan/_migrations/` record format and the five records written in this repo. |
| 33 | L191 | Confirm that the three archived designs are compliant, so the `applied` record for `migrate-adoption-mode-and-about-md.md` stands. |
| 35 | L277 | Confirm the deletion of backlog entry 0000147 as closed by P-N3. |
| 39 | L201 | Confirm that `./README.md` joins the design's Component Paths. |
