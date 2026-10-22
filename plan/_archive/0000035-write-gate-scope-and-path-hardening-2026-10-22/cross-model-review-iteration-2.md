---
title: "Cross-model review iteration 2 - 0000035 write gate scope and path hardening"
summary: "P6 cross-model re-review of feature 0000035. All eight iteration 1 findings are resolved or soundly deferred. Verdict APPROVE with two minor, non-blocking findings."
status: "draft"
version: "0.1.0"
---
# Cross-model review, iteration 2: 0000035-write-gate-scope-and-path-hardening

- **Reviewer model:** `claude-sonnet-5-5`
- **Implementer model:** `claude-opus-5-5`
- **Branch:** `feat/0000035-write-gate-scope-and-path-hardening` at `01f9516`
- **Scope:** fix commits `47a5084`, `c824bbb`, `fa9bd5c`, `557f986`, `01bd0e2`, `f7b2f33` and `7f655f5`, then `git diff main...HEAD` read afresh against req-001 to req-010 and the ADRs
- **Verdict: APPROVE** (REJECT-default rubric)

## Summary

M1, M2, M3, M5, M6, M7 and M8 are resolved. M4 is deferred to backlog 0000159, and the deferral is sound. I found no critical or major defect. I found two minor issues, and neither blocks approval.

## Test run

`bash planifest-framework/tests/run-tests.sh` on the branch:

- Feature suites: 88 passed, 0 failed.
- Regression suite: 31 passed, 0 failed.
- Result line: `All tests passed.`

## Iteration 1 findings

| ID | Fix commit | Result | Evidence |
|----|-----------|--------|----------|
| M1 | `47a5084` | resolved | The assertion now reads `assert_contains "git add product.yml" "$STEP7"`. I deleted the `if [ -f product.yml ]; then git add product.yml; fi` line (`SKILL.md:156`) on a scratch copy. The suite failed with `FAIL: req-002: Step 7 stages product.yml`. |
| M2 | `c824bbb` | resolved | `git grep toRootRelative` finds no hit in `planifest-framework/` or `docs/`. Only archived plans and the new "removed" notes in ADR-005 and req-003 remain. The function and its header line are gone from `path-rules.mjs`. The req-003 prose now says the export was removed. |
| M3 | `fa9bd5c`, `c824bbb` | resolved | ADR-007 line 22 and req-005 line 22 name `resolveTargetBoth`. The req-003 caller line names `resolveTargetBoth`. The req-009 matching line names `foldWide`. The glossary row says `foldWide` folds case and NFKC lookalikes. The comment in `ratchet-check.mjs:9` matches the import at line 60. |
| M4 | none, filed as backlog 0000159 | deferred, sound | See "M4 deferral" below. |
| M5 | `557f986` | resolved | `fast-path.md:103`, req-001 and ADR-002 no longer claim a Hard Limit 8 permission. They say the limit gives no rule for the marker and the shell guard passes the `rm`. This matches the guard, because `plan/` is always permitted. |
| M6 | `01bd0e2` | resolved | `retroactive-release-tags.md` frontmatter holds no `status` or `completed` field. ADR-016 item 8 records the rule that a migration file holds no run state. |
| M7 | `f7b2f33` | resolved | The migrator skill gains Step 1b. It reads the `**Target:**` line, tests for `id: "planifest-framework"` in `product.yml`, skips Steps 2 to 4, and records `not applicable` with both counts at `0`. This matches the req-010 prose, which now points to Step 1b. |
| M8 | `7f655f5` | resolved | `git diff main...HEAD -- planifest-framework/pipeline-reference.md` adds no em dash. The six Fast Path items use colons. |

### Req-005 line 58

Line 58 is the unchanged `- [ ]` line. It says `ratchet-check.mjs` imports `resolveRoot` and `resolveTarget`. The hook imports `resolveTargetBoth` (`ratchet-check.mjs:60`). The line reads true with the added prose. Line 22 now names `resolveTargetBoth`, and the next line says the hook reaches `resolveTarget` through `resolveTargetBoth`. The suite check at `test-0000035-req-005...sh:165` matches the substring `resolveTarget`, which `resolveTargetBoth` contains. A reader who stops at line 58 still sees a literal mismatch. I class that as minor finding m2, with no action needed.

### M4 deferral

The deferral holds for these reasons:

- The order predates the feature. `main` already runs the always-permitted basename check first (`path-rules.mjs` on `main`, lines 207 and 255).
- The permitted names are `claude.md`, `agents.md`, ignore files, `.gitattributes`, `pause.md` and session markers. No hook, wiring file or git hook loads any of them as code.
- Req-010 plants the same names as distrusted root markers (ADR-008), so the planted-marker route is closed.
- The backlog entry names the file, the line, the fix and a test case.

One gap remains. req-009 and `fast-path.md` still say a record never admits an enforcement path with no exception. See m1.

## Rubric

| # | Item | Result | Evidence |
|---|------|--------|----------|
| 1 | Every functional line is built, and each acceptance criterion has a test that fails when the behaviour breaks | Pass | I mutated one behaviour per requirement on a scratch copy, and the owning suite failed each time. Req-001: the admission notice text (2 failures). Req-002: exit 5 changed to 0 for `external` (1 failure), and the `git add product.yml` line removed (1 failure). Req-003: hop limit 40 changed to 400 (3 failures). Req-004: the `CLAUDE_PROJECT_DIR` fallback in `hookCwd` removed (2 failures). Req-005: `resolveRoot` fed `process.cwd()` (2 failures). Req-006: the always-permitted basename rule in `plantedAt` removed (3 failures). Req-007: `not applicable` renamed in the migrator skill (2 failures). Req-008: one script removed from `standard-boot.md` (3 failures). Req-009: `.codex/config.toml` removed from the enforcement list (3 failures). Req-010: the `not applicable` record changed to `applied` (1 failure). |
| 2 | No behaviour contradicts a requirement or an accepted ADR | Pass | `scopeVerdict` runs the enforcement list before the record match (`path-rules.mjs:707`), as ADR-004 says. The always-permitted name exception is a pre-existing order that req-009 words too strongly. See m1. |
| 3 | Hooks keep their contract | Pass | `path-rules.mjs` imports `node:fs` and `node:path` only. The only `child_process` import is `ratchet-check.mjs:53`, which predates the feature and sits in backlog 0000128. Unexpected errors exit 0, and block paths exit 2 with a reason. The suites assert both. |
| 4 | No security regression from `main` in the write gates | Pass | Iteration 1 ran the attack fixture. The fix commits since then touch no hook logic. The only code change is the removal of `toRootRelative`, which had no caller. The test run is green. |
| 5 | Code quality, glossary names, comments match behaviour | Pass | `toRootRelative` is gone. Comments in `ratchet-check.mjs` and `path-rules.mjs` match the imports. Glossary names `foldWide`, `resolveTargetBoth` and `Enforcement path` match the code. One small export nit is m2. |
| 6 | Skill and template text matches the code | Pass | Ship Step 7 stages `product.yml` and a test pins the command. The migrator Step 1b matches req-010. Both boot templates carry the seven-script sentence, and the suite checks that they match. |
| 7 | Docs match reality | Pass | The M3 lines now match the code. `docs/` holds no stale `toRootRelative` or `_done/` reference. The one gap is the unqualified wording in m1. |

## Findings

Counts: critical 0, major 0, minor 2. Neither blocks approval.

### m1. Minor: req-009 and `fast-path.md` omit the always-permitted name exception

- **File:** `plan/current/requirements/req-009-fast-path-enforcement-paths.md` (Matching and precedence section) and `planifest-framework/workflows/fast-path.md` (enforcement list section)
- **Evidence:** Both say a scope record never admits an enforcement path. `evaluateWrite` returns at the always-permitted check (`path-rules.mjs:788`) before `scopeVerdict` runs, so `planifest-framework/hooks/enforcement/CLAUDE.md` is admitted. Backlog 0000159 covers the code. The prose stays absolute until then.
- **Fix:** Add one sentence to both files: "An always-permitted file name, such as `claude.md`, keeps its pass inside an enforcement folder until backlog 0000159 lands." Remove the sentence when 0000159 ships.

### m2. Minor: `resolveTargetText` is exported with no caller outside its module

- **File:** `planifest-framework/hooks/enforcement/path-rules.mjs:358`, and the header comment at line 37
- **Evidence:** Only `resolveTargetBoth` (line 369) calls it. Neither gate nor any test imports it. `parseScopeRecord` and `readGitState` are in the same position but are documented public helpers. This is the same pattern that made `toRootRelative` dead code.
- **Fix:** Either drop the `export` keyword and the header line, or add a direct test and keep it as public API. No action blocks approval.

## Notes for the human on the loop

- Req-005 line 58 stays as the ratchet left it. It reads true with the prose beside it, as set out above.
- Backlog 0000159 remains open. Pick it up at the next P0.
- The `Exception waiting` lines in `build-log.md` still need a human answer. This review did not touch them.
