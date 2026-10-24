# Quirks — setup-hook-integration

## Q-001: retired

This quirk described a hook that setup no longer installs.

## Q-002 — `jq` not available on Windows; node used as fallback

`setup.sh` originally used `jq` for `settings.json` manipulation. `jq` is not installed by default on Windows. All JSON operations use `node -e` with BOM-stripping (`.replace(/^\uFEFF/, '')`). This means `node` ≥18 is a hard runtime requirement.

## Q-003 — commit-msg advisory hook subject line length uses byte count, not char count

`${#SUBJECT}` in bash counts bytes, not Unicode characters. For commit messages with non-ASCII characters (e.g., em-dash `—`), the reported length may exceed the actual visible character count. The `—` in `feat(0000003): Phase 3 — commit standards` registers as 3 bytes, causing false advisory triggers when the visual length is under 72 chars. Known but low-impact — advisory hook exits 0.

## Q-004 — `skill-sync.sh sync` produces "No manifest found" on first run

Before any external skills are added, `external-skills.json` does not exist. `cmd_sync` logs "No manifest found — nothing to sync." This is expected and non-fatal (calls use `|| true`), but may appear as noise in setup output.

## Q-005 — Windows `mktemp` paths not recognized as git repos

`mktemp -d` on Windows/Git Bash creates directories under a path that git treats as having "dubious ownership". `git init` in these directories succeeds but subsequent `git config` calls fail with exit 128. This affects the integration tests that create a temporary repo.

**Updated in 0000037.** The Git Bash leg of the CI `test-suite` job (0000037-ADR-013) found a second effect. Under Git Bash, `mktemp -d` returns a `/tmp/...` path, and Node reads it as `C:\tmp\...`, outside the fixture root. The ratchet and write-gate suites then saw `expected 2, actual 0`. The fixtures now resolve the folder with `pwd -W`. The Windows run passes in seven shards, and a suite that can't run on Windows prints `SKIP (windows): {reason}` and has a row in the skip table in `planifest-framework/tests/README.md`.

## Q-006: `Write-SetupFlagsMarker` (0000020) verified statically only, no pwsh in this dev environment

The `.claude/.planifest-setup-flags` marker write added to `setup.ps1` (REQ-008) could not be exercised by a live invocation during this feature's codegen pass because no PowerShell runtime (`pwsh`) is available in this session's environment. `bash`/`setup.sh`'s equivalent logic was verified with live temp-workspace runs (see `tests/test-0000020-req-008-install-time-marker-write.sh`, parts a-d); the `setup.ps1` side (part e) is checked statically (function exists, calls the marker writer, uses the matching field names). Recommend a live `pwsh` run of `test_setup.ps1` plus a manual `.\planifest-framework\setup.ps1 claude-code` invocation on Windows or a pwsh-enabled CI runner before this feature ships, to catch anything the static check cannot (e.g. a `ConvertTo-Json` depth or encoding mismatch).

**Resolved in 0000031.** The `Setup under PowerShell 7 (Windows)` CI job now runs `test_setup.ps1` live on every pull request. The test parses the marker after a plain run and after a `--include-full-skill-library` run, and checks every field. It also rejects three broken markers. The first live run passed on 2026-10-16 (CI run 38944916328).

## Q-008: `cline.ps1`'s boot-file relocation (0000027-req-002) verified statically only, no pwsh in this dev environment

Same constraint as Q-006. `cline.ps1`'s `BootFile` was relocated from `.clinerules` to `.clinerules\00-planifest-boot.md` to fix the boot-file/skills-dir path collision (mirroring `cline.sh`'s fix, which was verified live via a new regression test on a disposable workspace). No PowerShell runtime available in this session's environment to exercise `cline.ps1` live — verified via structural source assertions (exact `BootFile`/`SkillsDir` string values) in `tests/test-0000027-req-002-cline-path-collision.sh`, part (e). Recommend a live `pwsh` run before this feature ships, same recommendation as Q-006.

## Q-009: hooks are installed as copies, so a shared module exists at runtime only if a glob copies it (0000028)

Installed hooks are plain `cp` copies, never symlinks, so an `import` in a hook resolves against `.claude/hooks/`, not against `planifest-framework/hooks/`. A shared module is therefore present at runtime only because some `setup.sh` code path actually copied it. A narrow install glob would install the callers and drop every shared module they import. The install functions use `*.mjs` for this reason. The failure this would have caused is not graceful: an ESM import of an absent module throws at module-load time, before the hook's own `try/catch`, so the hook exits non-zero rather than exiting 0 as NFR-001 requires.

Copying is also additive only. `setup.sh` never prunes, so a module renamed or deleted upstream leaves a stale copy behind. There are currently no orphans, but a `*.mjs` glob makes this worth watching in a way an implicit allowlist did not.

## Q-010: `setup.sh` wrote enforcement hook commands as bare `.mjs` paths and they never ran (fixed 0000028)

For as long as the enforcement block has existed, `setup.sh` pushed commands such as `.claude/hooks/enforcement/gate-write.mjs` into `settings.json` with no interpreter prefix, while the hook sources are committed with mode `100644` and `cp` propagates that mode. The shell could not execute the wired command and returned 126. Claude Code treats any exit other than 2 as non-blocking, so seven enforcement hooks silently did not run: the write gate, two retired backstops, all three `UserPromptSubmit` orchestrator checks, and 0000028's own em dash guard. Only `ratchet-check.mjs` worked, and only because its source file happens to carry mode `100755`.

`setup.ps1` had always written `node $HooksDir/gate-write.mjs`, so the two scripts disagreed and the PowerShell form was the correct one. Fixed at 0000028 P5 by prefixing every enforcement command string with `node`, which is also the only portable form since Windows has no exec bit. Worth remembering when reading test evidence: the P4 suite invoked the hook as `node em-dash-guard.mjs` and passed, because it tested the hook rather than the command string `setup.sh` actually writes.

## Q-007: OpenCode's `setup.ps1` tool config does not return a `SkillsDir`-bearing object (pre-existing)

`setup/opencode.ps1` performs its install as a sequence of top-level statements rather than returning a config object like every other `setup/<tool>.ps1`, so `Invoke-PlanifestSetup`'s `$toolConfig.SkillsDir` is empty for OpenCode on Windows. This predates 0000020 and is out of scope for this feature per `plan/current/scope.md` (general `setup.ps1` parity drift), but it means the new `Write-SetupFlagsMarker` call is guarded to skip silently for OpenCode on Windows rather than error. OpenCode's marker write works correctly on the `setup.sh` side (bespoke branch in `run_tool_setup`, see ADR-002 implementation notes).

## Q-011: NFR-002 idempotency ignores `writtenAt` (0000030)

Setup rewrites the `writtenAt` timestamp in the install marker on every run, so two runs never produce byte-identical markers. The 0000030 idempotency test hashes the marker with the `writtenAt` line removed. Any later idempotency check must do the same. This predates 0000030.

<!-- BEGIN retired-integrations (0000030) -->
## Q-012: clean-up deletes whole stale folders and removes the `emit_event` group by matcher alone (F6, accepted)

The clean-up deletes `hooks/context-mode/` and `hooks/telemetry/` as whole folders, so a file a person stored there is lost. It also removes hook groups with the matcher `mcp__structured-telemetry-mcp__emit_event` without checking the command path. Both departures are accepted because the folders are Planifest install locations, the server behind the matcher no longer exists, and setup prints every removal. 0000030-ADR-004 records the deviation. Backlog 0000090 holds the narrower design: delete shipped file names only, and remove an empty folder.
<!-- END retired-integrations (0000030) -->

## Q-013: PowerShell changes in 0000030 have static checks only (backlog 0000091)

The `setup.ps1` clean-up, the `-LiteralPath` and reparse-point handling (F2), the exclusive temporary file (F5), the BOM-less `Write-SettingsFile`, and the PowerShell retired-flag branch were never run, because no `pwsh` exists in this environment and CI runs no PowerShell. Source-text assertions in `test-0000030-req-004-install-clean-up-and-retired-flags.sh` check them. Same constraint as Q-006 and Q-008.

**Partly resolved in 0000031.** The Windows CI job now runs `setup.ps1` live on a fresh install, which exercises `Write-SettingsFile` and the clean-up pass with nothing to remove. No live test yet seeds stale entries or passes a retired flag under PowerShell.

**Resolved in 0000037.** The req-011 section of `test_setup.ps1` seeds a stale hook folder and a stale `settings.json` entry, passes `--context-mode-mcp`, and checks the clean-up, the removal notice, the surviving hand-added hook, and the marker. It runs under PowerShell 7 and under Windows PowerShell 5.1 in the `setup-powershell-51` job (0000037-ADR-012). Under 5.1, the test relaxes `$ErrorActionPreference` to `Continue` around the setup call, because 5.1 turns merged native stderr into a terminating error. The `-LiteralPath`, reparse-point, and exclusive temporary file paths stay checked by source text only.

## Q-014: `Write-SettingsFile` writes UTF-8 without a BOM (0000030)

`Write-SettingsFile` in `setup.ps1` now writes UTF-8 without a byte order mark. Windows PowerShell 5.1 `Set-Content -Encoding UTF8` wrote one. Readers in this repo strip a leading BOM, so files written by older runs still parse.
