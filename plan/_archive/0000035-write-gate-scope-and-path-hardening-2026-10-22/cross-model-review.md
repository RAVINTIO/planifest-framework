---
title: "Cross-model review - 0000035 write gate scope and path hardening"
summary: "P6 cross-model review of feature 0000035 against req-001 to req-010 and the ADRs. Verdict REJECT on three small blocking minors. No critical or major finding."
status: "draft"
version: "0.1.0"
---
# Cross-model review: 0000035-write-gate-scope-and-path-hardening

- **Reviewer model:** `claude-sonnet-5-5`
- **Implementer model:** `claude-opus-5-5`
- **Branch:** `feat/0000035-write-gate-scope-and-path-hardening` at `82c57f6`
- **Scope:** `git diff main...HEAD` (153 files), read against req-001 to req-010 and the ADRs in `plan/current/adr/`
- **Verdict: REJECT** (REJECT-default rubric)

## Summary

The gates, scripts and skill text are sound. I found no critical or major defect. I could not get a write into `src/` with no design, or into an enforcement path under a scope record, by any route I tried.

The rubric asks for evidence that every item holds. Items 1, 5 and 7 each have one small proven gap. Each gap is minor and costs minutes to fix. Fix M1, M2 and M3 below, and this review flips to APPROVE.

## Test run

`bash planifest-framework/tests/run-tests.sh` on the branch:

- Feature suites: 88 passed, 0 failed.
- Regression suite: 31 passed, 0 failed.
- Result line: `All tests passed.`

The 10 new `test-0000035-*.sh` suites all pass.

## Method

- I read all four hooks, `set-product-release.mjs`, the `promote-to-regression.sh` diff, the `consistency-check.mjs` diff, the ship, migrator and orchestrator skill text, `fast-path.md`, and both boot templates.
- I ran mutation checks on a copy of `planifest-framework/` under the scratchpad. I broke one behaviour at a time and ran the owning suite. About 40 mutations in all. Every behaviour change was caught except one, which is M1. One prose-only edit ("Run this step after Step 6") also survived, and I discounted it because it changes words and not the step order.
- I ran a live attack fixture against `gate-write.mjs` with a current scope record and no design. It covered `..` before and after links, mixed-case wiring paths, a link into `.git`, a link chain into `planifest-framework/hooks/`, CRLF and upper-case `head` in the record, and a design that does not list the record paths.
- Fixtures and scripts: `/private/tmp/claude-501/-Users-martinmayer-d-planifest-framework/c8bb348c-4548-41a9-8aa3-a2d1f6512153/scratchpad/xmodel/`.

## Rubric

| # | Item | Result | Evidence |
|---|------|--------|----------|
| 1 | Every functional line is built, and every acceptance criterion has a test that fails when the behaviour breaks | **Fail** (minor) | All mutations of hook and script behaviour were caught, bar one. The req-002 criterion "Step 7 stages `product.yml`" is asserted by a loose substring check that survives removing the `git add` line. See M1. |
| 2 | No behaviour contradicts a requirement or an accepted ADR | Pass | `scopeVerdict` runs the enforcement list before the record match (`path-rules.mjs:722`), as ADR-004 says. A design wins over a record (`path-rules.mjs:791`). A stale record admits nothing (`path-rules.mjs:712-713`). Req-010 holds five records and three `Exception waiting` lines (`build-log.md:192-194`), which matches AC-010.3. |
| 3 | Hooks keep their contract | Pass | `path-rules.mjs:52-53` imports `node:fs` and `node:path` only. `gate-write.mjs:53-55` and `shell-write-guard.mjs:837-840` exit 0 on unexpected errors. Every block exits 2 with the reason on stderr (`gate-write.mjs:45-49`, `ratchet-check.mjs:283-284`, `shell-write-guard.mjs:832-835`). The `execFileSync("git")` in `ratchet-check.mjs:53` predates the feature and is tracked in backlog 0000128. |
| 4 | No security regression from `main` in the write gates | Pass | See "Attack results" below. Deferred findings G-S04, G-S05, G-S06, G-S10 and G-S12 are not re-reported, and their deferrals hold. |
| 5 | Code quality, glossary names, comments match behaviour | **Fail** (minor) | `toRootRelative` is exported and documented "for existing callers" but has none. See M2. Names match `domain-glossary.md`. |
| 6 | Skill and template text matches the code | Pass | Ship Step 5b exit handling matches the exit codes of `set-product-release.mjs:46-53`. Step 7 stages `product.yml` (`SKILL.md:152-158`). The `fast-path.md` enforcement list and `FAST_PATH_ENFORCEMENT_PATHS` match, and `test-0000035-req-009` checks both directions (mutating one entry fails the suite). Both boot templates carry the same seven-script sentence. Orchestrator Resume Detection step 1 matches the migrator pending rule. |
| 7 | Docs match reality (Hard Limit 7) | **Fail** (minor) | `docs/` and `pipeline-reference.md` are accurate. Four requirement and ADR lines, and one glossary row, still describe the pre-G-S01 and pre-G-S02 design. See M3. |

## Attack results

All run against `gate-write.mjs` with a current scope record listing `src/` and no `design.md`.

| Target | Result |
|--------|--------|
| `src/a.js` | Admitted, with the stderr notice |
| `src/../.claude/settings.json` | Exit 2, enforcement path |
| `src/./../.CLAUDE/Settings.json` | Exit 2 |
| `plan/../.git/config`, `docs/../.git/config` | Exit 2 |
| `src/g/config` where `src/g` links to `../.git` | Exit 2 |
| `src/sub/pf/hooks/enforcement/gate-write.mjs` through a link to `planifest-framework/` | Exit 2 |
| Record listing a hook file by name | Exit 2 |
| Record with CRLF line endings, or upper-case `head` | Admitted (parser accepts both, as the requirement says) |
| Same `src/ok.js` write with a `design.md` that omits it | Exit 2, the design wins |

Mutations that failed the right suites: removing the enforcement check, the `head` check, the text placement, the planted-marker rule, the non-ASCII rule, the deleted-cwd walk, the version-mismatch check, the hard-link check, the link-loop check, the 40-hop limit, the 64-path and 16 KiB record limits, the `..` segment rule, the `rm -f` step, the changelog `Paths:` field, and the 10-criteria limit.

## Findings

Counts: critical 0, major 0, minor 8. M1 to M3 block approval. M4 to M8 do not.

### M1. Minor, blocks item 1: the Step 7 staging criterion is not tested

- **File:** `planifest-framework/tests/test-0000035-req-002-product-yml-in-p7.sh:278-279`
- **Evidence:** The assertion is `assert_contains "product.yml" "$STEP7"`. Step 7 prose names `product.yml` on `planifest-framework/skills/planifest-ship-agent/SKILL.md:152`, so deleting the line `if [ -f product.yml ]; then git add product.yml; fi` (`SKILL.md:156`) leaves the suite green. I proved this with a mutation.
- **Fix:** Assert the command, not the word: `assert_contains "git add product.yml" "$STEP7" "req-002: Step 7 stages product.yml"`.

### M2. Minor, blocks item 5: `toRootRelative` is dead code

- **File:** `planifest-framework/hooks/enforcement/path-rules.mjs:409-421`, and the export list at line 39
- **Evidence:** The comment says "Kept for existing callers. The gates call resolveTarget." `git grep toRootRelative` finds no caller outside this definition, a doc table and archived plans. `shell-write-guard.mjs` was its last caller and moved to `resolveTarget` in this feature. Req-003 line 40 asks to keep it, so remove it only with that line.
- **Fix:** Delete the function and its header line, and reword `plan/current/requirements/req-003-links-judged-by-real-target.md:40`. If you keep it by design, add a test that calls it and change the comment to say it is public API with no in-repo caller.

### M3. Minor, blocks item 7: five plan lines describe the superseded design

Each line is stale against the shipped code. A later paragraph in the same file usually carries the correct text.

- `plan/current/requirements/req-005-ratchet-check-shared-root.md:22` and `:58`, and `plan/current/adr/ADR-007-ratchet-check-uses-shared-path-rules.md:22`, say `ratchet-check.mjs` imports `resolveTarget`. It imports `resolveTargetBoth` (`ratchet-check.mjs:60`). Say `resolveTargetBoth`.
- `plan/current/requirements/req-003-links-judged-by-real-target.md:41` says `judgeWrite` calls `resolveTarget`. It calls `resolveTargetBoth` (`path-rules.mjs:832`). ADR-005 line 40 already says so.
- `plan/current/requirements/req-009-fast-path-enforcement-paths.md:56` says the gate compares `norm(relPath)` with `norm(entry)`. The code compares `foldWide` forms (`path-rules.mjs:526-540`). Line 57 adds the fold, so reword line 56 to point at it.
- `plan/current/domain-glossary.md`, the "Enforcement path" row, says "Matching is case-insensitive through `norm`". Say it folds case and NFKC lookalikes.

### M4. Minor: an always-permitted file name inside an enforcement folder is admitted

- **File:** `planifest-framework/hooks/enforcement/path-rules.mjs:788` against `:722`
- **Evidence:** `evaluateWrite` returns at the always-permitted check before `scopeVerdict` runs the enforcement list. `planifest-framework/hooks/enforcement/CLAUDE.md`, `.git/info/.gitignore` and `.git/hooks/pause.md` all exit 0 in my fixture. This contradicts "a record never admits an enforcement path" (req-009, ADR-004) as written. It is not exploitable. None of the permitted names runs as code, and no wiring file uses one.
- **Fix:** Either run `isEnforcementPath` before the always-permitted return when no design exists, or add a sentence to req-009 and `fast-path.md` that permitted file names keep their pass anywhere.

### M5. Minor: `fast-path.md` states a Hard Limit 8 permission the limit does not give

- **File:** `planifest-framework/workflows/fast-path.md:103`
- **Evidence:** "Hard Limit 8 permits this `rm`" appears nowhere in Hard Limit 8 in `standard-boot.md:14`. The `rm` is harmless and the shell guard passes it, because `plan/` is always permitted.
- **Fix:** Reword to "The shell-write guard passes this `rm`, because `plan/` is always permitted and the record is a session marker, not code."

### M6. Minor: `retroactive-release-tags.md` frontmatter says the migration is complete

- **File:** `planifest-framework/migrations/retroactive-release-tags.md:5-7`
- **Evidence:** `status: "complete"` and `completed: "2026-05-18"` remain, yet the pending rule counts it pending until a record exists, and `build-log.md:194` holds it as waiting. A reader sees two answers.
- **Fix:** Drop `status` and `completed` from the frontmatter, or add a line that the record in `plan/_migrations/` is the only state.

### M7. Minor: the migrator skill never defines the target check

- **File:** `planifest-framework/skills/planifest-migrator/SKILL.md`, "Run records" and Process Steps 1 to 3
- **Evidence:** The `not applicable` outcome is defined, but no step says to read the `**Target:**` line and decide. Only req-010 and the glossary describe it. A fresh agent has no instruction to reach `not applicable`.
- **Fix:** Add one sentence to Step 2: if the `**Target:**` line names only downstream projects and this repo is the framework source, record `not applicable`.

### M8. Minor: new prose uses em dashes

- **File:** `planifest-framework/pipeline-reference.md:134-139`
- **Evidence:** The six rewritten Fast Path list items keep the old em dash separators. The project style, and the em-dash guard, forbid them in new prose. The two scripts that gained em dashes in comments or messages (`consistency-check.mjs`, `promote-to-regression.sh`) are code text and can stay.
- **Fix:** Replace the separator in each of the six items with a colon or a full stop.

## Notes for the human on the loop

- Three migrations (`0001-date-format.md`, `0002-british-english.md`, `retroactive-release-tags.md`) have no record by design. The next session's resume detection will run the migrator for them.
- Six `Exception waiting (P6, ...)` lines at `build-log.md:316-321` still need a human answer. This review did not touch them.
- Two regression-pack tests changed with the behaviour they cover (`tests/regression/test-0000005-framework-governance.sh` and `test-regression-pack.sh`). The changes are consistent with req-007 and req-008.
- `product.yml` still reads `0.30.0` and feature `0000031`. Ship Step 5b corrects it at P7, so that is expected now.

## Re-review

After M1 to M3 land, re-run `bash planifest-framework/tests/run-tests.sh`. M4 to M8 may ship in the same commit or go to the backlog.
