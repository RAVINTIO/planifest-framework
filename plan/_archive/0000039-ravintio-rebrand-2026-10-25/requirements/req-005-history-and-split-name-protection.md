---
title: "Requirement: req-005 - history-and-split-name-protection"
summary: "The scripted rename pass leaves history and sibling names untouched, handles every split old name by rule, and leaves every listed suite passing."
status: "draft"
version: "0.1.0"
---
# Requirement: req-005 - history-and-split-name-protection

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000039-ravintio-rebrand
**Source:** US-001
**Priority:** must-have

## User Story

As a human on the loop, I see RAVINTIO Framework in every live path, identifier, and prose line, so that the pack matches the RAVINTIO org without the rename damaging history or breaking a test.

## Functional Requirements
- The scripted P3 pass reads a protected list before it changes any file. The list holds the history paths, the history-reading lines in the suites below, the sibling repo names, and the old feature, ADR, and backlog ids. The full list is in the "Protected inventory" section.
- Each split or built old name in the inventory has one handling rule. The rule says whether the pass renames it, protects it, or leaves it for an **Edit** follow-up.
- The test-writer adds `planifest-framework/tests/test-0000039-req-005-split-names.sh` before the pass runs. It asserts each rule against the post-pass tree.
- The pass maps case by context. `Planifest` in prose becomes `RAVINTIO Framework`. `planifest` in a path or identifier becomes `ravintio`. `PLANIFEST_` is handled by req-003. A blind case-insensitive replace is not allowed.
- The pass changes the `setup.sh` mojibake lines byte-safely. It replaces only the old word and leaves every other byte on those lines as it is.
- Split step: keep. Protection and the split-name rules share one protected list and one script run, so they fail or pass together.

## Acceptance Criteria
- [ ] After the pass, `git diff --stat` against the pre-pass commit shows no change under `plan/_archive/`, `plan/changelog/`, `plan/_migrations/`, `plan/backlog/*/_reference/`, `ravintio-framework/external-skills/` (vendored lines), or the bodies of the shipped files in `ravintio-framework/migrations/`. Verified by: execution
- [ ] `test-0000039-req-005-split-names.sh` passes. It checks every rule in the "Split name rules" table, including that no `planifest-$`, `planifest-{`, `planifest-*`, `[planifest]`, or `.planifest-tmp-` form remains in live files except the protected lines. Verified by: unit
- [ ] After the pass and the `setup.sh claude-code` re-run, `planifest-framework/tests/run-tests.sh` (path `ravintio-framework/tests/run-tests.sh` after the rename) exits 0. That covers every suite in the "Protected inventory" section, the regression pack, `test_setup.sh`, and `test_setup.ps1` on the CI PowerShell legs. Verified by: execution

## Dependencies
- req-001, req-002, req-003, and req-004 define the renames that this requirement protects. This requirement defines what they skip.
- req-007 reads the same allowlist entries for the protected lines.
- RAVINTIO Zero 0000160 build report, as prior art. Its largest P3 cost came from split names that no one listed first.

## Protected inventory

Paths and line numbers are from `main` at the start of 0000039 and are approximate to the line. The test-writer re-greps them before the pass.

### 1. History paths (byte-identical)
- `plan/_archive/`, `plan/changelog/`, `plan/_migrations/`.
- `plan/backlog/*/_reference/` (historical reviews, with brand-guard allowlist entries).
- The bodies of the shipped files in `planifest-framework/migrations/`: `0001-date-format.md`, `0002-british-english.md`, `0003-archive-dirname.md`, `migrate-0.31.0-rerun-setup-for-shell-write-guard.md`, `migrate-0.34.0-rerun-setup.md`, `migrate-0.35.0-rerun-setup.md`, `migrate-0.36.0-rerun-setup.md`, `migrate-adoption-mode-and-about-md.md`, `migrate-product-yml-component-paths.md`, `migrate-remove-context-mode-and-telemetry.md`, `retroactive-release-tags.md`, plus `migrate-archive-dirname.sh` and `.ps1`. The folder moves with the pack. The file names and bodies stay.
- `planifest-framework/external-skills/`: vendored upstream text stays. Only pack-authored lines change.
- Old feature ids `0000001` to `0000038`, their ADR ids, and old backlog ids stay wherever they appear.
- Sibling names: `planifest-docs` links (allowlisted), RAVINTIO Zero (`/Users/martinmayer/d/planifest/zero`), and the `C:\d\planifest\framework\` path in the refresh script.
- Two `U+FEFF` byte-order-mark regexes in `setup.sh` (lines 33 and 606) and the BOM in templates are real characters, not mojibake. The pass leaves them alone.

### 2. Suites that read history, tags, diffs, or migration names
These read the real repository. The pass protects the lines noted.

| Suite | What it reads | Rule |
|-------|---------------|------|
| `test-0000037-req-008-migration-branch-diff.sh` | `git tag -l 'v*'`, `git diff --name-only base..HEAD -- planifest-framework`, `migrations/migrate-*-rerun-setup*.md` (lines 73 to 124) | Rename the `fw=` path, the pathspec, the `grep '^planifest-framework/'`, and the fixture paths (lines 190 and 204) together. After the pass the highest re-run-setup migration is 0.36.0, so the check reports SKIP as frozen. The 0.37.0 migration is named `migrate-0.37.0-ravintio-rename.md` and does not match the glob. |
| `test-0000036-req-001-rerun-setup-migration.sh` | The shipped 0.34.0 migration body and `plan/_migrations/migrate-0.34.0-rerun-setup.md` (lines 26 to 28, 108, 112 to 135, 209) | Protect the needles `planifest-refresh-setup` (line 108) and `skills/planifest-migrator/SKILL.md`, `skills/planifest-orchestrator/SKILL.md`, `skills/planifest-ship-agent/SKILL.md` (about lines 124 to 126). They match the unchanged migration body. The comment `git diff --name-only 2253e80 5c7859a` stays. |
| `test-0000035-req-010-migration-records-for-this-repo.sh` | `plan/_migrations/*.md` and `plan/_archive/0000035-*/build-log.md` (lines 21 to 40) | No change to the history reads. The new `not applicable` record for 0.37.0 must not break its fixed record list. |
| `test-0000027-req-003-005-007-008-governance-docs.sh` | the archived 0000027 skill-scope-principle ADR file under `plan/_archive/0000027-*/adr/` (line 60) | No change. The id and archive path stay. |
| `test-0000030-req-005-refresh-setup-migration-and-self-hosting.sh` | `migrations/migrate-remove-context-mode-and-telemetry.md` (line 13) | Rename the folder path only. The file name and body stay. |
| `test-0000030-req-001-002-removed-files-and-residue.sh` | Exempts `planifest-framework/migrations/migrate-remove-context-mode-and-telemetry.md` from a residue scan (line 50) | Rename the folder in the exemption. The residue scan must still skip that file's old text. |
| `test-0000032-req-011-rerun-setup-migration.sh` | `migrations/migrate-0.31.0-rerun-setup-for-shell-write-guard.md` (lines 13 to 42) | Rename the folder path only. |
| `test-0000035-req-007-migration-run-state.sh` | `plan/_migrations/{stem}.md` rules and `migrationPath: "planifest-framework/migrations/"` (line 87) | Rename line 87 with `component.yml`. Keep the `plan/_migrations/` strings. |
| `test-0000005-framework-governance.sh` | `plan/_migrations/` in the migrator skill (line 172) | Keep `plan/_migrations/`. |

These suites assert `plan/_archive/`, `plan/changelog/`, or git commands as text in the ship, change, and orchestrator skills, or run them in temp fixtures. The `plan/_archive/` and `plan/changelog/` strings do not change, so the suites need no protected line. They must still pass.
- `test-0000017-req-003-phase-wave-sweep.sh`, `test-0000017-req-007-change-agent-archive.sh`, `test-0000023-req-002-marker-commit-lifecycle.sh`, `test-0000025-req-002-ship-agent-p7-git-add.sh`, `test-0000028-req-006-em-dash-guard.sh`.
- `test-0000032-req-001-marker-clear-before-tag.sh`, `test-0000032-req-002-resume-from-archive-evidence.sh`, `test-0000032-req-009-shell-guard-path-parity.sh`.
- `test-0000033-req-001-run-mode-script.sh` (fixture `plan/_archive/0000099-x-2026-10-19`, `git log -p`), `test-0000033-req-012-archive-script-without-glob-delete.sh`, `test-0000033-req-013-clean-close-out.sh`.
- `test-0000035-req-001-fast-path-scope-record.sh`, `test-0000035-req-002-product-yml-in-p7.sh`, `test-0000035-req-009-fast-path-enforcement-paths.sh`.
- `test-0000036-req-003-ship-commit-subjects.sh`, `test-0000037-req-001-p9-ci-check.sh`, `test-0000037-req-003-archive-held-back.sh`, `test-0000037-req-003-credential-scan.sh`.
- The `regression/` copies of: `test-0000005`, `test-0000017-req-007`, `test-0000019-req-002`, `test-0000032-req-001`, `-002`, `-009`, `test-0000033-req-001`, `-012`, `-013`, `test-0000035-req-002`, `test-0000037-req-003` (both). They get the same treatment as their top-level twins.

### 3. Suites that build fixture repos with `planifest-framework/` paths
Each fixture path renames together with the code under test. A fixture left on the old name makes the suite pass for the wrong reason or fail.
- `cp -r "$FRAMEWORK" "$dir/planifest-framework"`: `test-0000020-req-008-install-time-marker-write.sh` (37), `test-0000023-req-003-copilot-setup-self-copy.sh` (41), `test-0000025-req-004-setup-config-relocation.sh` (55), `test-0000027-req-002-cline-path-collision.sh` (34), `test-0000029-req-001-003-boot-file-regeneration.sh` (32), `test-0000030-req-004-install-clean-up-and-retired-flags.sh` (35), `test-0000032-req-006-outside-repository-pass.sh` (398), `test-0000032-req-012-write-or-edit-boot-rule.sh` (59), `test-0000037-req-007-wired-command.sh` (29), `test-0000038-req-004-installed-reference-links.sh` (25), `test-0000038-req-007-partial-reads.sh` (55), `test_setup.sh` (12 and 57).
- `mkdir` or manual layout: `test-0000035-req-007-migration-run-state.sh` (177), `test-0000032-req-006-outside-repository-pass.sh` and `test-0000032-req-009-shell-guard-path-parity.sh` (planted `planifest-fra...` paths, lines 178 and 172), `test-0000035-req-009-fast-path-enforcement-paths.sh` (156 to 157, a name built around `${LONG_S}`), `test-0000037-req-008-migration-branch-diff.sh` (73, 190, 204), `test-0000019-req-005-self-description-check.sh` (44, 75, 105, README table fixtures).
- `product.yml` fixtures with `id: "planifest-framework"`: `test-0000035-req-002-product-yml-in-p7.sh` (66), `test-0000035-req-008-sanctioned-scripts.sh` (55, 325, 361).
- Other fixture builders that call `git init`: `test-0000017-req-002-ratchet-approve.sh`, `test-0000019-req-002-component-yml-matcher.sh`, `test-0000032-req-003`, `-007`, `-008`, `test-0000035-req-003`, `-004`, `-005`, `-006`, `test-0000036-req-002-skill-drift-check.sh`, `test-skill-sync-security.sh`, `test-0000028-req-004-install-refresh-registration.sh` (line 14 `FRAMEWORK_DIR`), and the regression twins of these.

### 4. Split name rules

| Form | File and line | Rule |
|------|---------------|------|
| `planifest-$s-agent` | `tests/test-0000033-req-002-exception-list.sh:91,93` and the `regression/` twin | Pass renames the `planifest-` prefix to `ravintio-`. The skill folders rename in the same pass. The new suite checks that `ravintio-$s-agent/SKILL.md` exists for each `$s`. |
| `planifest-$agent-agent` | `tests/test-0000033-req-016-always-parallel-work-units.sh:66` | Same rule. |
| `planifest-{a,b,...}` brace expansion | `tests/test-0000030-req-003-telemetry-pipeline-text-removal.sh:37` (15 names) | Pass renames the prefix before the brace. The suite fails on a missing file, so a half rename shows at once. |
| `planifest-{skill-name}` placeholder | `skills/planifest-orchestrator/references/phase-0-assess-and-coach.md:180`, `templates/design.template.md:55` | Rename to `ravintio-{skill-name}`. The braces are not variables, so the prefix match applies. |
| `planifest-*` and `_planifest-*` globs | `tests/test-0000025-req-006-docs-agent-continuous-run.sh:14` (comment), `tool-setup-reference.md:39,73-74,105-106` | Rename in prose and trees. `setup.sh` no longer creates `_planifest-*` folders, so the docs are stale. File a backlog entry if the docs show folders that setup does not make. |
| `/^\[planifest\]/i` | `tests/test-0000036-req-011-escaped-hook-output.sh:97` | Rename to `/^\[ravintio\]/i`. Lines 179 and 180 (`[planifest] forged.md`) rename too. The case-insensitive flag keeps the match on `[RAVINTIO]`. |
| `\[Planifest\]` prefix strings | `hooks/enforcement/path-rules.mjs`, `shell-write-guard.mjs:68`, `check-design.mjs`, `em-dash-guard.mjs`, `hooks/commit-msg:64`, `setup.sh`, `setup.ps1`, `setup/opencode.*`, and the `[Planifest]` assertions in `test-0000032-req-007` and `test-0000035-req-001:337` (and the regression twin) | Rename source and assertion together to `[RAVINTIO]`. Req-002 owns the prefix. This row prevents a one-sided rename. |
| `planifest\\/` escaped path regex | `scripts/self-description-check.mjs:101` (`\(planifest-framework\/`) | Rename the folder inside the regex and keep the escapes. The matching README table fixtures in `test-0000019-req-005` (44, 75, 105) rename too. |
| `.planifest-tmp-` | `scripts/set-product-release.mjs:393`, `setup.sh:49`, `setup.ps1:97,144`, `setup/opencode.sh:76`, `setup/opencode.ps1:47` | Rename to `.ravintio-tmp-`. |
| `*.planifest-tmp*` leftover globs | `tests/test-0000030-req-004-install-clean-up-and-retired-flags.sh:204,316,485` | Rename with the writers. If the glob is left old, the test passes with no check. The new suite asserts both sides use `ravintio-tmp`. |
| mktemp templates | `planifest_0000037_req008_XXXXXX` and the other `planifest_NNNNNNN_reqNNN_XXXXXX`, `planifest_req00N_*_XXXXXX`, `planifest_test_XXXXXX`, `planifest-shard.XXXXXX`, `planifest-nest.XXXXXX` in about 45 suites | Rename the prefix to `ravintio_` or `ravintio-`. Keep the feature number and `XXXXXX`. A temp name is not history, and the brand guard flags it. |
| `.planifest-setup-flags-$(guid)` | `tests/test_setup.ps1:93` | Rename. Setup reads the old `.planifest-setup-flags` name once (design.md). Any fixture that plants the old file on purpose keeps the old name and goes on the brand-guard allowlist. |
| String concatenation | None found in live code. | The new suite greps for `"planifest"` followed by a quote and `+`, and for `"-framework"`. It fails if one appears. |
| `.planifest-session` | `hooks/adapters/opencode/index.ts:26`, `hooks/enforcement/path-rules.mjs:59`, `scripts/archive-current.mjs:23,63`, `tests/test-0000033-req-012` (61, 105) and its regression twin | Rename. Req-002 owns the old-marker read-through. `archive-current.mjs` must still delete the old `.planifest-session` as well as the new one. |

### 5. `setup.sh` mojibake lines
- `planifest-framework/setup.sh` lines 812 to 945 sit inside the heredoc at lines 811 to 958 that writes `plan/feature-structure.md`. The mojibake appears on 64 lines at 812, 822 to 829, 836, 838, 842 to 846, 851, 857 to 876, 879, 882, 883, 889, 895 to 908, 911, 914, 925, 926, 929, 932, 935, and 945.
- Line 1322 is the banner bar under `echo "Planifest Setup"` (line 1321).
- The old name sits on the same lines at 812, 814, 822, 836, 838, 841, 917, 945, 949, and 957. The pass edits them with a byte-safe tool (`LC_ALL=C` or a byte-mode replace), not a re-encode.
- Related mojibake outside `setup.sh`: `planifest-framework/setup.ps1:1053`, and the guides `templates/execution-plan-guide.md`, `templates/risk-register-guide.md`, and `templates/feature-brief-guide.md`. The pass treats these the same way. Do not repair the mojibake in this feature.
- After the pass, `git diff` of those lines must show only the old word changed. The new suite counts the mojibake lines before and after and expects the same number.
- Lines 788 and 957 (and `setup.ps1:894,1065`) link to `planifest/spec/feature-structure.md` and `planifest/templates/`. Those paths are stale and already wrong. The pass renames the word. File a backlog entry for the broken link.
