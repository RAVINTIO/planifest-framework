# Verify-by-Execution Report
**Toggle:** on
**Software exercised:** The 0.36.0 pack from `main` and the 0.37.0 `ravintio-framework/` from ROOT, run with `setup.sh`, the 0.37.0 migration helper, and the req-001 suite. All runs used `git clone` copies and scratch repos under a `mktemp -d` folder. Nothing ran inside ROOT.

| Requirement | Criterion | Method | Outcome | Observation evidence |
|-------------|-----------|--------|---------|---------------------|
| REQ-006 | Consumer upgrade: old pack moves to the backup folder | CLI: old `setup.sh claude-code`, copy in new pack, run helper, then new `setup.sh` | verified | Helper exit 0. `Step 6: moved planifest-framework/ to .ravintio-backup/planifest-framework/`. The backup holds the old pack. `.ravintio-backup/` is in `.git/info/exclude`. |
| REQ-006 | Overrides move | Same run | verified | `Step 3: moved planifest-overrides/ to ravintio-overrides/`. `planifest-overrides` is gone. |
| REQ-006 | Workflow renamed | Same run | verified | `Step 4: renamed .github/workflows/planifest.yml to .github/workflows/ravintio.yml`. Git shows an `R` entry. |
| REQ-006 | `core.hooksPath` | `git config core.hooksPath` | verified | Before: `planifest-framework/hooks`. After: `ravintio-framework/hooks`. |
| REQ-006 | No doubled blocks | Count markers after setup, then after a second setup | verified | `ravintio-overrides:instructions:start` count is 1 in `CLAUDE.md` before and after a second run. The `RAVINTIO - Token` line count is 1 in `.claudeignore`. Old `planifest-overrides:` markers: 0. |
| REQ-006 | Old installed skills pruned | `ls .claude/skills` | verified | 21 `ravintio-*` skills and 0 `planifest*` skills. The old `.planifest-manifest` and `.planifest-setup-flags` files are gone. |
| REQ-006 | Flags carried | Old setup with `--strict-orchestrator`, then helper, then plain `setup.sh claude-code` | verified | New `.claude/.ravintio-setup-flags` holds `"flags": ["--strict-orchestrator"]`. |
| REQ-006 | Helper is idempotent | Run the helper again | verified | `Nothing to do. This project already uses the RAVINTIO names.` |
| REQ-009 | Setup stops when the old pack sits beside the new one | Restore the old pack, run `setup.sh` | verified | `Error: found the old folder planifest-framework/ at the project root.` Exit 1. |
| REQ-001 | Fresh consumer sees only new names | Copy only `ravintio-framework/`, run `setup.sh claude-code` | verified | Exit 0. `core.hooksPath` is `ravintio-framework/hooks`. The only `planifest` strings on disk are deliberate old-name reads (`OLD_SENTINEL` in `em-dash-guard.mjs`, migrator mapping text, refresh-setup fallback text). |
| REQ-001 | AC1: no tracked path with the old brand | `RAVINTIO_PASS_COMMIT=81287992` req-001 suite in a ROOT clone | **failed** | `FAIL: ... (3 found)`. Leftovers are `planifest-framework/external-skills/README.md` and two `SKILL.md` files. These are the three held-back external-skills files. ROOT's working tree has them moved, but the move is uncommitted. |
| REQ-001 | AC3: renames show as `R` | Same suite | verified | 43 passed. Every folder, workflow, hook file, and PowerShell script reports `R`. No `D` entry for an old-brand path. |
| REQ-003 | AC1: inventory | The inventory command from req-003 in the clone | verified | Output: `PLANIFEST_SESSION_ID`, `PLANIFEST_SHARD_COUNT`, `PLANIFEST_SHARD_INDEX`, `PLANIFEST_TELEMETRY`, `PLANIFEST_TELEMETRY_URL`. |
| REQ-003 | AC1: full suite passes | Not run | not-verifiable | The criterion says "the full suite passes". The `run-tests.sh` suite was out of scope for this run. CI covers it. |
| REQ-004 | AC3: heredoc bytes | Extract old lines 811 to 958 and new lines 880 to 1027, normalise brand words, `cmp` | verified | `cmp` reports identical. The non-ASCII byte streams match. Old line 1322 and new line 1407 have the same md5 after normalisation. The line numbers moved by 69 and 85 because of added lines above. |
| REQ-005 | History byte-identity | `git diff --name-status --diff-filter=MDR origin/main...HEAD -- plan/_archive plan/changelog plan/_migrations ':(glob)plan/backlog/*/_reference/**'` | verified | No output. |
| REQ-010 | AC2: no live file names 1.0.0 as current | `git grep '1\.0\.0'` outside history, vendored skills, and the backlog | verified | Hits are "removed at 1.0.0" comments, `templateVersion: "1.0.0"` in `component.yml`, and a phase-0 version example. None name 1.0.0 as the current release. `product-version.mjs` prints `0.37.0`. |
| REQ-009 | Migrator view: no pending migration | Compare `ravintio-framework/migrations/*` to `plan/_migrations/*.md` in the clone | verified | `plan/_migrations/migrate-0.37.0-ravintio-rename.md` exists. The only file without a same-named record is `migrate-archive-dirname.sh` and `.ps1`. On `main` these helpers also lack a record, and `0003-archive-dirname.md` covers them. |

## Counts
- verified: 16
- failed: 1 (req-001 AC1)
- not-verifiable: 1 (req-003 full suite)

## Observations
- User-owned override text still names `planifest-framework/templates/...` in the consumer `CLAUDE.md` (line 94). It comes from the overrides copy, so the helper does not rewrite it.
- A plain `setup.sh` re-run without flags resets the stored flags to `[]`. This matches the old behaviour.

## P6 re-verification: marker rename

**Date:** 2026-10-25
**Software exercised:** The `v0.36.0` pack (commit `f8e31435`) from `git archive`, and the working-tree `ravintio-framework/` at `7b182157`. Each consumer is a fresh git repo under one `mktemp -d` folder, `/var/folders/.../tmp.aB2iqA7Y8j`. On macOS `/var` is a link to `/private/var`, so that path holds a link. Nothing ran inside ROOT.

Consumers:

| Copy | Path form | Used for |
|------|-----------|----------|
| `c1` | logical (`/var/...`) | Steps 1, 2a, 3, 4, and 5 with Bash |
| `c2` | logical | Step 2b, old pack and old overrides moved out by hand |
| `c3` | logical | Step 6 with PowerShell 7.6.8 |
| `c4` | physical (`/private/var/...`) | Step 5 control run with Bash |

### Results

| Step | Command | Outcome | Observation evidence |
|------|---------|---------|---------------------|
| 1. Build a 0.36.0 consumer | `git archive v0.36.0 planifest-framework \| tar -x`, then `bash planifest-framework/setup.sh claude-code --strict-orchestrator`, then commit | verified | Exit 0. `.claude/.planifest-setup-flags` holds `"flags": ["--strict-orchestrator"]`. `.claude/skills/.planifest-manifest` lists 21 absolute `/var/.../planifest-*` paths. 21 `planifest-*` skill folders exist. `plan/.orchestrator-strict` exists. The old `.gitignore` ignores `.claude/`, so git tracks no marker. |
| 2a. New setup stops on the old pack | `cp -R` the new pack into `c1`, then `bash ravintio-framework/setup.sh claude-code` | verified | Exit 1. `Error: found the old folder planifest-framework/ at the project root.` and `Run the migration migrate-0.37.0-ravintio-rename first, then run setup again.` A hash of every path, mtime, size, and `git status` matched before and after (`aa6b70ac...` both times). |
| 2b. New setup stops on the old marker | In `c2`, move `planifest-framework/` and `planifest-overrides/` out of the project, then run the same setup | verified | Exit 1. `Error: found the old marker file .claude/.planifest-setup-flags.` The message names the migration. The hash matched (`ab806ba5...`). With the flags file also moved out, setup stops on `.claude/skills/.planifest-manifest` with exit 1, and the hash matched. `grep` finds only existence checks of the old marker names in `setup.sh` line 1341 and `setup.ps1` line 81, and no read of their content. |
| 3. Bash helper | `bash ravintio-framework/migrations/migrate-0.37.0-ravintio-rename.sh` in `c1` | verified | Exit 0. Steps 3 to 6 each report a move. Step 5 renames both markers and all 21 skill folders, then prints `rewrote the entries in .claude/skills/.ravintio-manifest`. Step 7 prints `Next step: run ravintio-framework/setup.sh claude-code --strict-orchestrator, or setup.ps1 with the same arguments, before the next commit.` `cmp` finds the new flags file byte-identical to a copy of the old one (SHA-1 `e9a3c010...` for both). The manifest holds 21 entries. Each entry is a `ravintio-*` folder that exists, and each parent equals `pwd -P` of the skills folder (`/private/var/...`). No `planifest` name is left in `.claude`. |
| 4. Printed setup command | `ravintio-framework/setup.sh claude-code --strict-orchestrator` in `c1` | verified | Exit 0. Setup removes the 21 listed folders and installs fresh copies. `find` outside `.git` and `.ravintio-backup` returns no `planifest-*` or `.planifest-*` path. `.ravintio-setup-flags` holds `"flags": ["--strict-orchestrator"]`. `plan/.orchestrator-strict` exists. |
| 5. Helper rerun | Run the Bash helper again in `c1`, after step 4 | **failed** | Exit 0, but the run changed a file. Step 5 printed `rewrote the entries in .claude/skills/.ravintio-manifest`. The hash moved from `9afb63be...` to `da1c5b0b...`. `setup.sh` writes manifest entries with the logical path `/var/...`. The helper rewrites them to the physical path `/private/var/...`. A second helper rerun changes nothing. See defect D-1. |
| 5. Control: physical path | In `c4` at `/private/var/...`: build, helper, `setup.sh claude-code --strict-orchestrator`, then helper again | verified | Exit 0 at each run. The rerun prints only skip lines. The hash matched before and after (`a35a37b3...`). |
| 6. PowerShell helper | `pwsh -NoProfile -File ravintio-framework/migrations/migrate-0.37.0-ravintio-rename.ps1` in `c3` | verified | Exit 0. After the copy path is masked, the output matches the Bash helper's step 3 output line for line, including the step 7 command with `--strict-orchestrator`. The flags file is byte-identical. The manifest holds 21 valid `ravintio-*` entries and matches the Bash helper's manifest. |
| 6. PowerShell setup | `pwsh -NoProfile -File ravintio-framework/setup.ps1 claude-code --strict-orchestrator` in `c3` | verified | Exit 0. `find` returns no `planifest-*` or `.planifest-*` path. `.ravintio-setup-flags` records `--strict-orchestrator`. `plan/.orchestrator-strict` exists. A `.ps1` helper rerun exits 0, and the hash matched (`1a177647...`). |

### Defect D-1: helper rerun rewrites a manifest that `setup.sh` wrote

- **Criterion:** req-006 "A rerun changes nothing", and the P6 bullet "A rerun skips what is done".
- **Trigger:** the project path holds a link, such as `/var` on macOS. Then run the helper, then `setup.sh`, then the helper again.
- **Cause:** `setup.sh` writes each manifest entry with the logical project path. The helper writes the physical path. `setup.ps1` writes the physical path, so the `.ps1` rerun changes nothing.
- **Effect:** each helper rerun after a `setup.sh` run rewrites the manifest and prints `rewrote the entries`. It prints no warning and exits 0. The entries name the same folders, so setup still prunes and installs correctly.
- **Scope:** low. A project path with no link shows no change, as the `c4` control run shows.

### Counts

- verified: 8
- failed: 1 (step 5, defect D-1)
- not-verifiable: 0

### Observations

- Step 2b needed both `planifest-framework/` and `planifest-overrides/` moved out, because either folder stops setup first.
- req-006 step 8 says a rule must now require `RAVINTIO Strict Pipeline`. The migration doc and the helper output say the opposite: keep `validate-branch` and don't require the workflow name. The helper follows the migration doc.

## Re-verification at HEAD

**Date:** 2026-10-25
**Closes:** cross-model finding X-002
**Commits:** first run at `d2a79606`. HEAD then moved to `01374ccc`, which changes the `setup.sh` and `setup.ps1` old-folder stop check (X-004) and a test fixture (X-006). The consumer and stray-entry runs were repeated at `01374ccc` with the same results. The full suite and req-001 suite ran at `d2a79606`.
**Software exercised:** the `v0.36.0` pack (`f8e31435`) and the `ravintio-framework/` pack at each commit, both taken with `git archive`. The working tree was never used, because other agents had uncommitted changes in it. Each consumer is a fresh git repo under one `mktemp -d` folder, `/var/folders/.../tmp.XCOpC9004X`. On macOS `/var` is a link to `/private/var`. The full suite and the req-001 suite ran in a `git clone` checked out at `d2a79606` in the scratchpad. PowerShell is 7.6.8 with `PATH="/opt/homebrew/bin:$PATH"`. Nothing ran inside ROOT.

Consumers:

| Copy | Path form | Helper and setup |
|------|-----------|------------------|
| `c1` | logical (`/var/...`), holds a link | `.sh` helper, then `setup.sh` |
| `c2` | physical (`/private/var/...`) | `.sh` helper, then `setup.sh` |
| `c3` | logical, holds a link | `.ps1` helper, then `setup.ps1` |
| `c4` | physical | `.ps1` helper, then `setup.ps1` |
| `s1` | logical, stray entries planted | `.sh` helper, then `setup.sh` |
| `s2` | logical, stray entries planted | `.ps1` helper, then `setup.ps1` |

Each upgrade run took these steps:

1. Run `tar -x` on the 0.36.0 archive, then `bash planifest-framework/setup.sh claude-code --strict-orchestrator`, then commit.
2. Extract the new pack, then run the helper.
3. Run the setup command from the helper's `Next step:` line.
4. Hash the state, rerun the helper, and hash again.

The hash covers every path, mtime, size, and mode outside `.git`, the SHA-1 of each file, `git status --porcelain`, and `core.hooksPath`.

### Results

| Check | Command | Outcome | Observation evidence |
|-------|---------|---------|---------------------|
| D-1: `.sh` rerun on a linked path (`c1`) | `bash ravintio-framework/migrations/migrate-0.37.0-ravintio-rename.sh`, then `ravintio-framework/setup.sh claude-code --strict-orchestrator` as printed, then the helper again | verified | The old manifest names `/var/.../c1/.claude/skills/planifest-adr-agent`. Helper exit 0 with 28 change lines and `Next step: run ravintio-framework/setup.sh claude-code --strict-orchestrator, ...`. Setup exit 0. Its manifest now names `/private/var/.../c1/.claude/skills/ravintio-adr-agent`, so `setup.sh` writes the real path (fix `72ac382d`). Rerun exit 0, 0 change lines, `Nothing to do. This project already uses the RAVINTIO names.` State hash `9213937fe5ee` before and after. At `01374ccc` the hash is `88567a123b0c` both times. |
| `.sh` rerun on a physical path (`c2`) | Same steps | verified | Rerun exit 0, 0 change lines. State hash `ab7a90b1efa9` both times. At `01374ccc` the hash is `27f100b6351e` both times. |
| `.ps1` rerun on a linked path (`c3`) | `pwsh -NoProfile -File ravintio-framework/migrations/migrate-0.37.0-ravintio-rename.ps1`, then `pwsh -NoProfile -File ravintio-framework/setup.ps1 claude-code --strict-orchestrator`, then the helper again | verified | Helper exit 0, 28 change lines, and the same `Next step:` line as the `.sh` helper. Setup exit 0. Rerun exit 0, 0 change lines, `Nothing to do.` State hash `1cc0277006ee` both times. At `01374ccc` the hash is `23562b06003e` both times. |
| `.ps1` rerun on a physical path (`c4`) | Same steps | verified | Rerun exit 0, 0 change lines. State hash `ce2ea7ee0e9f` both times. At `01374ccc` the hash is `bbe44e08616e` both times. |
| Cross-shell rerun | `.ps1` helper in `c1` after `setup.sh`, and `.sh` helper in `c3` after `setup.ps1` | verified | Both exit 0, 0 change lines, `Nothing to do.` |
| Upgrade end state (`c1` to `c4`) | Read the markers after setup | verified | 21 manifest entries. `.ravintio-setup-flags` holds `"flags":["--strict-orchestrator"]` and `"attemptStatus":"completed"`. `plan/.orchestrator-strict` exists. `core.hooksPath` is `ravintio-framework/hooks`. `find` outside `.git` and `.ravintio-backup` returns 0 `planifest*` paths. |
| Manifest holds only strict names after migration (`c1` to `c4`) | For each entry, check that the last part matches `^[A-Za-z0-9][A-Za-z0-9._-]*$`, doesn't end in a dot, and starts with `ravintio-`. Then check that its parent equals `pwd -P` of the skills folder and the folder exists | verified | 21 entries in each copy, 0 failing. |
| Stray entries dropped (`s1`, `.sh`) | Append 11 stray lines to `.claude/skills/.planifest-manifest` and plant `.ravintio-manifest.AbC123`. Run the helper, then `setup.sh claude-code` | verified | The stray lines are an outside folder, a `../../../` path to it, `//evilhost/share/...`, `\\evilhost\share\...`, `bad name`, `trail.`, `CON`, `aux.txt`, `*`, a relative name, and `.hidden`. Helper exit 0 prints `WARNING: dropped manifest entry` once for each of the 11. It prints `Step 5: removed the leftover temporary file .claude/skills/.ravintio-manifest.AbC123.` The new manifest holds 21 entries, 0 failing the rule. After setup the outside folder still holds its file (`victim intact: data`). Same result at `01374ccc`. |
| Stray entries dropped (`s2`, `.ps1`) | Same fixture with the `.ps1` helper and `setup.ps1` | verified | Same 11 drop warnings and the temporary file removal. 21 entries, 0 failing. The outside folder is intact. Same result at `01374ccc`. |
| req-001 AC1: no tracked path with the old brand | `git ls-files` filtered for the old brand outside the protected paths, then `RAVINTIO_PASS_COMMIT=81287992 bash ravintio-framework/tests/test-0000039-req-001-pack-paths-and-identifiers.sh` in the clone | verified | `count=0` at `d2a79606` and at `01374ccc` (`git ls-tree`). The three external-skills files now sit at `ravintio-framework/external-skills/`, moved in `e5608c50`. Suite exit 0, `Results: 44 passed, 0 failed`, including `PASS: ... (0 found)`. |
| req-003 AC1: full suite passes | `bash ravintio-framework/tests/run-tests.sh --quiet` in the clone, with `pwsh` on the path | verified | Exit 0. `Feature suites: 127 passed, 0 failed.` `Regression suite: 35 passed, 0 failed.` `Suites run: 162`. This covers macOS with PowerShell 7 only. The Windows and Windows PowerShell 5.1 legs need the CI matrix on the PR. |
| req-003 AC1: inventory | The exact command from req-003: `git grep -ohE 'PLANIFEST_[A-Z_]+' -- . ':!plan/_archive' ... ':!ravintio-framework/tests/test-0000039-req-006*' \| sort -u` | **failed** | Output: `PLANIFEST_SESSION_ID`, `PLANIFEST_SHARD_COUNT`, `PLANIFEST_SHARD_INDEX`, `PLANIFEST_TELEMETRY`, `PLANIFEST_TELEMETRY_URL`. The criterion allows only the session and telemetry names. Both shard hits come from `test-0000039-req-003-environment-variables.sh` line 130, a probe that shows the old shard names no longer shard a run. See defect D-2. |

### Defect D-2: the req-003 inventory command doesn't match its test

- **Criterion:** req-003 AC1, "the inventory command returns only `PLANIFEST_SESSION_ID` ... and `PLANIFEST_TELEMETRY*`".
- **Cause:** the requirement's exact command leaves out only `test-0000039-req-006*`. The req-003 suite leaves out every `test-0000039-*` file (line 33), so the suite passes. The req-003 test holds the old shard names in its legacy probe.
- **Effect:** none in the shipped software. The CI workflow and `run-tests.sh` read only the `RAVINTIO_SHARD_*` names. The earlier inventory row showed the same five names and still recorded verified.
- **Suggested fix:** under Hard Limit 7, change the command in req-003 to leave out `ravintio-framework/tests/test-0000039-req-003*` as well, or match the suite's `test-0000039-*`.
- **Scope:** low.

### Observation: setup lists folders it didn't install

`setup.sh` writes every folder under `.claude/skills/` to the manifest. That includes folders the pack didn't install. In `s1` and `s2` the planted folders `bad name`, `trail.`, `CON`, and `aux.txt` appear in the manifest after setup. The next helper run drops them and rewrites the manifest, so the rerun isn't a no-op in this fixture. The next setup run without a helper run deletes them. A 0.36.0 consumer shows the same deletion of a user folder `my-own-skill` on the second setup rerun, so this predates 0000039. It's out of scope here. Backlog entry 0000255 covers a related prune gap but not this listing.

### Counts

- verified: 11
- failed: 1 (req-003 AC1 inventory, defect D-2)
- not-verifiable: 0

### Closing lines for earlier rows

- REQ-001 AC1, first table, **failed**: now verified at `d2a79606` and `01374ccc`. The three held-back files were committed in `e5608c50`.
- REQ-003 AC1 full suite, first table, not-verifiable: now verified, 162 of 162 suites pass on macOS. The Windows and 5.1 legs still need CI.
- REQ-003 AC1 inventory, first table, verified: now failed against the exact command (D-2). The output is unchanged. The earlier row didn't compare it with the criterion.
- P6 step 5 helper rerun, **failed** (D-1): now verified for `.sh` and `.ps1` on a linked path and a physical path.
- REQ-003 AC1 inventory, this section, **failed** (D-2): now verified. `4928eba9` corrected the command in req-003 to also exclude `test-0000039-req-003*`. The orchestrator ran the corrected command at `58658ee6`. It printed only `PLANIFEST_SESSION_ID`, `PLANIFEST_TELEMETRY`, and `PLANIFEST_TELEMETRY_URL`, which the criterion allows. Counts after this line: verified 12, failed 0, not-verifiable 0.
