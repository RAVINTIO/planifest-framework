---
title: "Validation Report: 0000035-write-gate-scope-and-path-hardening"
summary: "P4 semantic correctness: 69 of 71 criteria pass now, 2 are open by design until a later step, and the full test run passes."
status: "complete"
---
# Validation report: 0000035-write-gate-scope-and-path-hardening

**Phase:** P4 validate, step 1 (semantic correctness)
**Run mode:** autonomous
**Date:** 2026-10-22

## Result

69 of 71 criteria are covered by a passing test. Two criteria are open by design:

- req-002 AC-3 becomes testable only at P9, after the P7 script run.
- req-010 AC-010.1 waits on three human answers that the build log records.

The count covers every `- [ ]` line in the ten requirement files. That includes each Acceptance Criteria line, each req-002 sub-bullet, and each Input Validation line. Every suite names its req-ID in each test description.

The audit found 19 coverage gaps. New tests closed all 19. One new test failed because the test itself was wrong. One self-correct cycle fixed it. No production code changed.

## Suites

| Suite | Before P4 | After P4 |
|---|---|---|
| `test-0000035-req-001-fast-path-scope-record.sh` | 99 passed | 142 passed, 0 failed |
| `test-0000035-req-002-product-yml-in-p7.sh` | 69 passed | 74 passed, 0 failed |
| `test-0000035-req-003-links-judged-by-real-target.sh` | 35 passed | 46 passed, 0 failed |
| `test-0000035-req-004-root-when-cwd-deleted.sh` | 26 passed | 34 passed, 0 failed |
| `test-0000035-req-005-ratchet-check-shared-root.sh` | 19 passed | 22 passed, 0 failed |
| `test-0000035-req-006-no-planted-root-marker.sh` | 23 passed | 23 passed, 0 failed |
| `test-0000035-req-007-migration-run-state.sh` | 113 passed | 113 passed, 0 failed |
| `test-0000035-req-008-sanctioned-scripts.sh` | 161 passed | 182 passed, 0 failed |
| `test-0000035-req-009-fast-path-enforcement-paths.sh` | 101 passed | 113 passed, 0 failed |
| `test-0000035-req-010-migration-records-for-this-repo.sh` | 45 passed | 48 passed, 0 failed |

## Coverage table

AC rows come from `## Acceptance Criteria`. IV rows come from `## Input Validation`. A test name in quotes is the PASS description, with the `req-NNN:` prefix left out. A row marked (P4) cites a test that this step added.

| REQ-ID | AC | Covered by test | Pass/Fail |
|---|---|---|---|
| req-001 | AC-1 listed `x.md` exits 0, `y.md` exits 2, guard the same | "gate-write admits the listed …", "gate-write blocks the unlisted …", "the shell guard admits the listed …", "the shell guard blocks the unlisted …" | Pass |
| req-001 | AC-2 a stale `branch` or `head` admits nothing | "a record with a stale branch / stale HEAD / from before a commit admits nothing", "a worktree record that names the main branch …" | Pass |
| req-001 | AC-3 `fast-path.md` writes the record first and removes it before commit | "fast-path.md writes the record before the first change", "fills branch from git", "fills head from git", "removes the record before git commit" | Pass |
| req-001 | IV input source `plan/.fast-path-scope` | the whole stale and invalid record block | Pass |
| req-001 | IV input source: git files | "the worktree's .git is a file", "a worktree record follows the gitdir line and commondir", "a ref held only in packed-refs is read", "a detached HEAD matches branch (detached)" | Pass |
| req-001 | IV record at most 16 KiB | "a record over 16 KiB admits nothing …" | Pass |
| req-001 | IV git files 4 KiB, `packed-refs` 4 MiB | "a record with a HEAD file over 4 KiB …", "a record with packed-refs over 4 MiB …" (P4), "a record with a .git file over 4 KiB …" (P4), "an oversized packed-refs / .git file makes the git state unreadable" (P4) | Pass |
| req-001 | IV `branch` pattern and 1 to 255 characters | "a branch with a semicolon / with .. / with a leading -", "a branch of 256 characters …" (P4), "a 255-character branch is valid and only stale" (P4) | Pass |
| req-001 | IV `head` is 40 or 64 hex characters | "a head of 39 characters", "a head that isn't hex", "a 64-character head is valid and only stale" (P4) | Pass |
| req-001 | IV path pattern and segment rules | "an absolute path", "a path with a backslash / .. / . / empty segment / drive letter / glob", "a path over 512 characters" | Pass |
| req-001 | IV at most 64 paths | "a record with 65 paths …", "a record with exactly 64 paths admits a listed path" (P4) | Pass |
| req-001 | IV an invalid record gets the no-record block, exit 2 | every `expect_ignored` exit-2 pair, "… gets the no-record block" (P4) | Pass |
| req-001 | IV reason names line and rule, never a raw value | "the reason names the line number", "the reason never echoes the raw branch", "the reason never echoes a raw path" (P4), "a 256-character branch breaks the line 1 rule" (P4) | Pass |
| req-002 | AC-1 the suite runs the close-out order for each case | `close_out` for max, explicit, and `--create`, plus "the external Step 9 derivation exits 5 …" (P4) and "the --component Step 9 derivation matches the tag" (P4) | Pass |
| req-002 | AC-1a max and explicit: `version` and `feature` match the tag and ID | "a stale version is corrected to 0.33.0", "explicit writes --version", "explicit writes the feature ID", "the Step 9 derivation after the archive matches the tag", "the explicit Step 9 derivation matches the tag" | Pass |
| req-002 | AC-1b a second run is byte-identical | "a second run leaves product.yml byte-identical", "an explicit second run …", "a second --component run …" | Pass |
| req-002 | AC-1c a stale file is corrected, an unrelated line stays | "a stale version is corrected …", "an unrelated line is left alone", "the name line is left alone" | Pass |
| req-002 | AC-1d external: only `feature` changes, exit 5 | "external exits 5", "external leaves version as it is", "external writes the feature ID", "the external archive commit holds the new feature" (P4) | Pass |
| req-002 | AC-1e max: a different `--version` exits 2, file unchanged | "a --version that differs from the derived one exits 2", "a mismatch leaves product.yml unchanged" | Pass |
| req-002 | AC-1f no `product.yml`: exit 4, nothing written | "no product.yml and no --create exits 4", "exit 4 writes nothing" | Pass |
| req-002 | AC-1g `--create` with two components builds the file | "--create with two components exits 0", "--create sets …", "--create writes exactly two components[] entries" | Pass |
| req-002 | AC-1h `--component` replaces `components[]` exactly | "components[] holds exactly the --component entries", "components[] drops the entry --component left out", "without --component, components[] stays byte-identical", "the --component archive commit holds exactly the --component entries" (P4) | Pass |
| req-002 | AC-2 ship skill: step before Step 6, Step 7 stages, Step 9 no edit | "the product.yml step comes before Step 6", "Step 7 stages product.yml", "Step 9 holds no instruction to edit product.yml" | Pass |
| req-002 | AC-3 `product.yml` reads `0.33.0` and the feature ID at P9 | none yet. The root `product.yml` reads `0.30.0` and `0000031-…` until the P7 script run. | Open until P9 |
| req-003 | AC-1 a dangling `plan/` link to `src/` exits 2 in both gates | "gate-write blocks a write through a dangling plan/ link …", "shell guard blocks a write through a dangling plan/ link …" | Pass |
| req-003 | AC-2 `plan/l/../../../src/x.js` judged as `src/x.js` | "gate-write judges plan/l/../../../src/x.js as src/x.js", "shell guard judges …", "resolveTarget returns { status: inside, relPath: src/x.js }" | Pass |
| req-003 | AC-3 loop and 41-link chain exit 2 with cause, 10 links under 500 ms | "gate-write / shell guard blocks a write through a link loop", "… names the link loop", "… blocks a 41-link chain", "… names the hop limit", "… judges a 10-link chain in under 500 ms" | Pass |
| req-003 | IV input source: link text | the dangling, loop, and chain cases | Pass |
| req-003 | IV any text, never run or printed | "the block reason never prints link text", "the gate / guard reason never prints link text" (P4) | Pass |
| req-003 | IV length limits after each substitution | "gate-write / shell guard blocks a path past MAX_PATH_SEGMENTS after its link" (P4), "gate-write names the length cause" (P4) | Pass |
| req-003 | IV `unresolvable` blocks with exit 2 | the loop and 41-link exit-2 cases | Pass |
| req-003 | IV reason shows the first 80 characters, never link text | "the gate / guard reason shows the first 80 characters of the target" (P4), "… shows no more than 80 characters …" (P4) | Pass |
| req-004 | AC-1 deleted cwd with `CLAUDE_PROJECT_DIR`: `src/x.js` exits 2 in both | "gate-write blocks src/x.js from a deleted cwd with CLAUDE_PROJECT_DIR set", "shell guard blocks …", relative variants | Pass |
| req-004 | AC-2 deleted cwd, variable unset: nearest parent finds the fixture | "the nearest existing parent finds the fixture, so gate-write blocks src/x.js", "the shell guard finds the fixture from the nearest existing parent" | Pass |
| req-004 | AC-3 the 0000032 req-006 assertion expects 2, full suite passes | `test-0000032-req-006-outside-repository-pass.sh` "a cwd that doesn't exist gates src/a.js (0000035 req-004)", full run below | Pass |
| req-004 | IV input source: stdin `cwd` and `CLAUDE_PROJECT_DIR` | the set and unset blocks | Pass |
| req-004 | IV any path text, never printed or run | "the gate / guard output never prints the cwd" (P4), "… never prints CLAUDE_PROJECT_DIR" (P4) | Pass |
| req-004 | IV a too-long target keeps warn-and-allow | "a too-long target from a deleted cwd keeps its warn-and-allow exit 0" (P4), "… keeps its warning" (P4) | Pass |
| req-004 | IV the walk ends at the file-system root | "a hook call with a deleted 20-segment cwd takes under 500 ms" | Pass |
| req-004 | IV a cwd that isn't a non-empty string gives `null`, hook exits 0 | "resolveRoot returns null for a cwd that is not a non-empty string" (P4), "with no cwd and CLAUDE_PROJECT_DIR unset, gate-write passes", "… the shell guard passes" (P4) | Pass |
| req-004 | IV logging: neither value in hook output | "the gate / guard output never prints the cwd" (P4), "… never prints CLAUDE_PROJECT_DIR" (P4) | Pass |
| req-005 | AC-1 subfolder Edit removing a criterion exits 2, reason on stderr | "removing a criterion from src/ with a relative file_path exits 2", "the ratchet reason names the root-relative path" | Pass |
| req-005 | AC-2 relative `file_path` resolves against stdin `cwd`, adding exits 0 | "a relative file_path resolves against the stdin cwd", "adding a criterion from src/ exits 0" | Pass |
| req-005 | AC-3 imports `resolveRoot` and `resolveTarget`, no `process.cwd()` | "ratchet-check.mjs uses resolveRoot / resolveTarget", "imports path-rules.mjs", "calls process.cwd() only through the shared cwd fallback" | Pass |
| req-005 | IV input source: stdin `cwd` and `file_path` | the stdin-cwd case | Pass |
| req-005 | IV any path text | the relative, absolute, and link cases | Pass |
| req-005 | IV a longer path passes with exit 0 | "control, a nested plan/current/ artifact is guarded" (P4), "a file_path past MAX_PATH_SEGMENTS passes with exit 0" (P4) | Pass |
| req-005 | IV a non-string `file_path` passes with exit 0 | "a non-string file_path passes with exit 0" (P4) | Pass |
| req-005 | IV the reason shows the root-relative path | "the ratchet reason names the root-relative path" | Pass |
| req-006 | AC-1 planted `src/claude.md/.git`: `../other/x.js` exits 2 in both | "gate-write blocks ../other/x.js from planted src/claude.md/.git", "shell guard blocks touch ../other/x.js …" | Pass |
| req-006 | AC-2 a planted `planifest-framework/` doesn't move the root | "gate-write / shell guard blocks from planted src/claude.md/planifest-framework/", "gate-write blocks from planted src/pause.md/planifest-framework/" | Pass |
| req-006 | AC-3 `vendor/lib/.git` stays its own root | "vendor/lib/.git is its own root …", "vendor/lib/.git gates its own src/x.js", "shell guard keeps vendor/lib as its own root" | Pass |
| req-007 | AC-007.1 no file moves, `_done/` gone, eight files at top level, no text says to move one | "migrations/_done/ no longer exists", "… sits at the top level of migrations/", "holds exactly eight top-level migration files", "… never tells an agent to move it", "no skill, migration, or doc names _done/", "the migrator never moves a migration file" | Pass (source text, as the migrator is agent behaviour) |
| req-007 | AC-007.2 pending means no readable record, both skills state the rules | "step 1 makes pending mean no readable record", "the orchestrator step 1 / migrator states …", "states the unreadable-record rule" | Pass (source text) |
| req-007 | AC-007.4 Record step writes through Write, creates the folder, same outcome byte-identical | "the Record step writes plan/_migrations/{stem}.md", "… writes through Write", "… creates plan/_migrations/ on its first record", "a re-run with the same outcome leaves the record unchanged", "a Write to plan/_migrations/x.md exits 0" | Pass (source text plus gate run) |
| req-008 | AC-1 one case per Input Validation rule: exit 2, names the argument, no raw value, byte-identical | the `reject` helper's four assertions per case, plus "a repeated --root / --product-id / --product-name" (P4), "a missing --component value" (P4), "a --component path that is a folder" (P4) | Pass |
| req-008 | AC-1 sub: `product.yml` link outside the root | "a product.yml link to a file outside the root exits 2", "the link target stays unchanged", "the link itself stays in place", "a dangling product.yml link exits 2" | Pass |
| req-008 | AC-2 newline plus `versionPolicy: "explicit"` in `--feature-id` | "a newline in --feature-id exits 2", "… leaves product.yml byte-identical", "the newline injection adds no key" | Pass |
| req-008 | AC-3 one `Sanctioned scripts:` sentence in HL8, same seven scripts | "… holds one Sanctioned scripts: sentence", "puts the sentence inside Hard Limit 8", "names exactly the seven sanctioned scripts", "both templates name the same scripts", "both templates carry the same sentence" | Pass |
| req-008 | IV input source: six flags | at least one reject case per flag | Pass |
| req-008 | IV `--root` real path equals the resolved root | "a --root subfolder", "a --root outside the repo", "a --root that does not exist", "a root with no planifest-framework/ folder", "--root equal to the resolved root exits 0", "a --root link whose real path is the resolved root exits 0" (P4) | Pass |
| req-008 | IV `--root` default, `null` exits 2 | "a null resolveRoot result exits 2", "… names --root" | Pass |
| req-008 | IV `--feature-id` pattern and 80 characters | "a newline in --feature-id", "a --feature-id past 80 characters", "a --feature-id that breaks the pattern" | Pass |
| req-008 | IV `--version` strict semver and 32 characters | "a prerelease --version", "a build suffix on --version", "a leading zero in --version", "a --version past 32 characters" | Pass |
| req-008 | IV `--product-id` pattern and 64 characters | "a --product-id that breaks the pattern", "a --product-id past 64 characters" | Pass |
| req-008 | IV `--product-name` pattern and 1 to 80 characters | "a quote in --product-name", "a --product-name past 80 characters", "an empty --product-name" | Pass |
| req-008 | IV `--component` id pattern and 64 characters | "a --component id that breaks the pattern", "a --component id past 64 characters", "a --component with no =" | Pass |
| req-008 | IV `--component` path pattern, 256 characters, `component.yml` | "a --component path with a space", "… past 256 characters", "… that is not component.yml" | Pass |
| req-008 | IV `--component` path: no `/`, `..`, empty segment, must exist inside root | "… starts with /", "… with a .. segment", "… with an empty segment", "… with no file", "… that resolves outside the root", "… that is a folder" (P4) | Pass |
| req-008 | IV at most 64 components, unique ids, others once, unknown exits 2 | "more than 64 --component arguments", "two --component arguments that share an id", "a repeated --version / --feature-id / --create", "a repeated --root / --product-id / --product-name" (P4), "an unknown argument", "a missing --version value" | Pass |
| req-008 | IV caps apply to the raw value | every past-the-cap case | Pass |
| req-008 | IV a rule break writes nothing | "… leaves product.yml byte-identical" in every reject case | Pass |
| req-008 | IV stderr names the argument, never the raw value | "… names {arg} on stderr", "… never echoes the raw value" in every reject case | Pass |
| req-008 | IV the named suite cases | subfolder, outside, newline, quote, prerelease, and `..` cases above | Pass |
| req-009 | AC-1 a record listing `planifest-framework/` or `hooks/` never admits `gate-write.mjs`, guard the same | "a record listing planifest-framework/[hooks/] never admits … in gate-write / in the shell guard", "the shell guard reason for … names 0000033 ADR 009" (P4), shell-guard control (P4) | Pass |
| req-009 | AC-2 the settings files and `claude-code.sh` blocked, mixed case exits 2 | "a record listing .claude/settings.json / .claude/settings.local.json / planifest-framework/setup/claude-code.sh never admits …", "a record listing planifest-framework/ never admits Planifest-Framework/Hooks/x.mjs in gate-write / in the shell guard" (P4) | Pass |
| req-009 | AC-3 the `fast-path.md` list equals `FAST_PATH_ENFORCEMENT_PATHS` | "doc entry … is in FAST_PATH_ENFORCEMENT_PATHS", "constant entry … is in the fast-path.md prerequisites" | Pass |
| req-010 | AC-010.1 a record for each of the eight migrations | five records pass every frontmatter check. Three migrations wait on human answers. | Open until the human answers |
| req-010 | AC-010.2 each `not applicable` body names the framework-source reason | "the {stem}.md body says this repo is the framework source" (both) | Pass |
| req-010 | AC-010.3 a migration with findings has no record and one Exception waiting line | "… has no record, so the build log holds its Exception waiting line", "the build log holds exactly one Exception waiting line for …" (P4) | Pass |

## Gaps found and closed

Each gap is a criterion or Input Validation line that no test covered, or covered only in part.

1. req-002 AC-1: the external and `--component` cases skipped the close-out order. Added `close_out` runs for both. Commit `1560782`.
2. req-008 AC-1: the "every other argument at most once" rule had no repeat case for `--root`, `--product-id`, or `--product-name`. Added three reject cases. Commit `65b459c`.
3. req-008 AC-1: no case covered a `--component` with no value or a path naming a folder. Added two reject cases. Commit `65b459c`.
4. req-008 IV `--root`: the "real path" rule had no case with a link. Added a positive case. Commit `ca3a608`.
5. req-009 AC-1: the shell guard checked the exit code only, and had no control. Added the guard reason check and a guard control. Commit `661f9cb`.
6. req-009 AC-2: the mixed-case case used a record that named the same mixed-case path. Added a lowercase `planifest-framework/` record against `Planifest-Framework/Hooks/x.mjs`. Commit `661f9cb`.
7. req-010 AC-010.3: the check proved at least one Exception waiting line, not exactly one. Added a count check. Commit `661f9cb`.
8. req-001 IV git files: only an oversized `HEAD` had a case. Added `packed-refs` over 4 MiB and a `.git` file over 4 KiB. Commit `8c06102`.
9. req-001 IV `branch`: the 255-character limit was untested. Added 255 and 256 character cases. Commit `8c06102`.
10. req-001 IV `head`: a 64-character head was untested. Added a case. Commit `8c06102`.
11. req-001 IV 64 paths: only 65 was tested. Added an exactly-64 case. Commit `8c06102`.
12. req-001 IV failure: no test checked the no-record block text. `expect_ignored` now checks it. Commit `8c06102`.
13. req-001 IV logging: only the raw branch was checked. Added a raw-path check and a line-number check. Commit `8c06102`.
14. req-003 IV logging: the 80-character cap was untested, and the link-text check read only the guard's output. Added a long-name loop with distinctive link text for both hooks. Commit `2b5123a`.
15. req-003 IV length: the limit after a link substitution was untested. Added a 300-segment link for both hooks. Commit `2b5123a`.
16. req-004 IV logging: no test checked that the cwd and `CLAUDE_PROJECT_DIR` stay out of hook output. Added checks for both hooks. Commit `a0ef1dc`.
17. req-004 IV length and failure: the warn-and-allow result from a deleted cwd and the `null` root were untested. Added a too-long target case, a `resolveRoot` unit check, and a shell-guard no-cwd case. Commit `a0ef1dc`.
18. req-005 IV length: no test ran a path past the limits. Added a control and a 260-segment case. Commit `ea0cd00`.
19. req-005 IV failure: a non-string `file_path` was untested. Added a case. Commit `ea0cd00`.

## Functional requirements

Every functional requirement has an implementation. No FR is missing code or skill text.

Some FR branches run in the code but have no test of their own. They sit below the criteria, so closing them here would widen scope. Backlog entry 0000140 lists each one. It also records a wording mismatch. The `resolveRoot` doc comment says it returns `null` when `realpathSync` throws. req-004 says it returns `null` only for a cwd that is not a non-empty string.

## Self-correct cycles

```
Cycle 1:
  Check: test (test-0000035-req-004-root-when-cwd-deleted.sh)
  Error: FAIL: req-004: gate-write passes a cwd of 42 / "" / null (expected 0, actual 2)
  Root cause: test-bug. A non-string stdin cwd falls back to process.cwd() under the
    req-004 hookCwd FR. resolveRoot then returns the nearest existing folder as the
    root, so the no-design block is correct. The IV null rule applies to the
    resolveRoot argument, not to the stdin field.
  Fix: replaced the three hook cases with a resolveRoot unit check for '', 42, and
    undefined. Added a shell-guard case with no usable cwd, to match the gate-write one.
  Result: pass (34 passed, 0 failed)
```

Cycles used: 1 of 5.

## Open items

- req-002 AC-3: the root `product.yml` reads `0.30.0` and `0000031-ci-test-and-powershell-coverage`. P7 runs `set-product-release.mjs`, and P9 confirms the result.
- The installed copy `.claude/skills/planifest-ship-agent/SKILL.md` differs from `planifest-framework/skills/planifest-ship-agent/SKILL.md`. It has no `set-product-release.mjs` step. If no setup refresh runs before P7, the ship agent in this repo follows the old steps and AC-3 fails.
- req-010 AC-010.1: `0001-date-format.md`, `0002-british-english.md`, and `retroactive-release-tags.md` have no record. Each has one `Exception waiting (P3, human review)` line in the build log. FR-010.2 keeps AC-010.1 open until the human answers and the migrator writes the records.

## Full run

`bash planifest-framework/tests/run-tests.sh` exits 0.

- Feature suites: 88 passed, 0 failed.
- Regression suite: 31 passed, 0 failed.
- The output holds 7,704 individual PASS lines and no FAIL line.
