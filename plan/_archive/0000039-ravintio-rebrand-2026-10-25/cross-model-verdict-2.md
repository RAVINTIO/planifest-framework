# Cross-model verdict 2: 0000039-ravintio-rebrand

**Verdict: APPROVE**

- Reviewer model id: `claude-sonnet-5-5`
- Implementer model id: `claude-opus-5-5`
- Date: 2026-10-25
- Branch: `feat/0000039-ravintio-rebrand`, reviewed at HEAD `a19f3b1d`
- Rubric: REJECT by default. Approve only when evidence shows each requirement is met.
- Reviewer instance: fresh, with no part in cycle 1 or in the fixes.

## Result

All six cycle 1 findings are closed. The fresh full review found one Low finding (Y-001) that does not block P7. The full suite passes 162 of 162 on this machine. CI run 40195111057 shows the 5.1 job green, including both new steps.

Two jobs in that run were still in progress when I checked (macOS test suite and Windows shard 7). Every other job had passed. If either fails, treat it as a new finding before P7.

## Test runs

| Run | Result |
|-----|--------|
| `run-tests.sh --quiet` after `unset CLAUDE_PROJECT_DIR` and with `/opt/homebrew/bin` on `PATH` | Exit 0. 127 feature suites and 35 regression suites passed. 162 suites run. |
| Corrected req-003 inventory command at HEAD (the `git grep` from req-003 with the `test-0000039-req-003*` exclusion) | Prints `PLANIFEST_SESSION_ID`, `PLANIFEST_TELEMETRY`, and `PLANIFEST_TELEMETRY_URL` only. This matches the AC. |

## CI run 40195111057

The run was `in_progress` at the time of review.

| Job | Result |
|-----|--------|
| validate-branch | success |
| self-description-check | success |
| Setup under PowerShell 7 (Windows) | success |
| Setup under Windows PowerShell 5.1 | success. Steps "Run test_setup.ps1", "Parse the migration helper under 5.1", and "Run the req-006 .ps1 cases under 5.1" each succeeded. |
| Test suite (ubuntu-latest) | success |
| Test suite (windows-latest), shards 1 to 6 | success |
| Test suite (windows-latest), shard 7 of 7 | in progress |
| Test suite (macos-latest) | in progress |

The job log was not available through the API while the run was in progress, so I judged the 5.1 steps from the step conclusions and from the code.

## Status of cycle 1 findings

| ID | Status | Evidence |
|----|--------|----------|
| X-001 | Closed | `a19f3b1d` adds two steps to `setup-powershell-51`. The first calls `[System.Management.Automation.Language.Parser]::ParseFile` on the helper and exits 1 on any parse error. The second checks that `powershell.exe` reports major version 5, then runs the req-006 suite with `RAVINTIO_TEST_PWSH=powershell.exe` and `RAVINTIO_TEST_REQ006_ONLY=ps1`. The suite now fails (not skips) when a named binary is missing. It asserts that the job holds the parse step, the helper name, both variables, the suite call, and no secrets. A scan of the `.ps1` helper found no PowerShell 7 only syntax (no `??`, ternary, `&&`, `-AsHashtable`, `GetRelativePath`). `$ErrorActionPreference` is `Continue`, so `2>$null` on `git` is safe under 5.1. The CI run shows the 5.1 job green with both steps passing. |
| X-002 | Closed | `0e872066` appends a "Re-verification at HEAD" section. It re-runs the helper rerun on linked and physical paths in both shells, the cross-shell rerun, the stray-manifest-entry cases, req-001 AC1, and the full suite, all from `git archive` copies. It records new counts and closing lines for the old failed rows. The one remaining failed row (D-2) is a requirement wording defect, fixed in `4928eba9`. I re-ran the corrected inventory command and it passes. Y-001 notes the missing closing line. |
| X-003 | Closed | `d2a79606` rewrites ADR-004 line 59 so setup reads neither old marker file and stops while one exists. It marks the two design lines as superseded by the P6 change. |
| X-004 | Closed | `6c5582c3` uses `[ -e ] \|\| [ -L ]` in `setup.sh` and `Get-Item -Force -ErrorAction SilentlyContinue` in `setup.ps1`. `4a3ae470` adds file and dangling-link cases for both shells. Each asserts non-zero exit, no write, and the migration name. The Windows skip for the link case is listed in the tests README. The new cases pass in the full run. |
| X-005 | Closed | `d2a79606` rewrites the step 8 body in req-006 to match the P5 correction. |
| X-006 | Closed | `01374ccc` makes `WS=$(mktemp -d)` fail loudly, and the exit trap clears `chflags` locks and read-only bits before `rm -rf`. `WS` is unique per process and holds every fixture, so two runs at once do not share a folder. I ran the suite once and it passed. I did not repeat the concurrent-run case. |

## Requirement-by-requirement

| Req | Verdict | Evidence | Gap |
|-----|---------|----------|-----|
| req-001 pack paths and identifiers | Met | The req-001 suite passes in the full run. The re-verification records 44 of 44 at `d2a79606` and zero old-brand paths. | None. |
| req-002 runtime names | Met | `setup.sh:1338-1359` and `setup.ps1:70-91` stop before any write for the old folders in any form and for both old marker files. Both name `migrate-0.37.0-ravintio-rename`. The req-002 suite passes, including the new X-004 cases. | None. |
| req-003 environment variables | Met | The corrected inventory command returns only the allowed names. The full suite passes. The OpenCode adapter reads `RAVINTIO_SESSION_ID` first. | Y-001 (report wording only). |
| req-004 brand prose | Met | The req-004 suite passes. | None. |
| req-005 history and split names | Met | The req-005 suite passes. | None. |
| req-006 consumer migration | Met | AC1 to AC3, AC5, and AC6 pass in the 660-assertion suite. AC4 now has a 5.1 parse step and a 5.1 run of the `.ps1` cases in CI, and the job passed. | None. |
| req-007 brand guard | Met | The req-007 suite passes with a closed, reasoned allowlist and a stale-entry check. | None. |
| req-008 emitted names | Met | The req-008 suite passes. The workflow is named `RAVINTIO Strict Pipeline`. | None. |
| req-009 migration order and old paths | Met | The req-009 suite passes. The migrator maps old paths and never reads the backup folder as a live pack. | None. |
| req-010 version bump | Met | The req-010 suite passes. | None. |

## Findings

| ID | Severity | File and line | Issue | Fix |
|----|----------|---------------|-------|-----|
| Y-001 | Low | `plan/current/verification-report.md`, "Closing lines for earlier rows" (end of file) | The re-verification section leaves the req-003 inventory row as failed (D-2) and lists no closing line for the fix in `4928eba9`. At HEAD the corrected command passes, but the report does not say so. A reader sees an open failed row. | Append a closing line: "REQ-003 AC1 inventory, re-run with the corrected command at HEAD: verified, returns only `PLANIFEST_SESSION_ID`, `PLANIFEST_TELEMETRY`, and `PLANIFEST_TELEMETRY_URL`." Update the counts to 12 verified and 0 failed. Fix it in the P7 commit or with the next plan edit. |

## Checks that found nothing

- No PowerShell 7 only syntax in `migrate-0.37.0-ravintio-rename.ps1` (752 lines). Manifest and exclude-file writes use a BOM-free UTF-8 encoding object.
- The stop checks in `setup.sh` and `setup.ps1` list the same eight tool folders and the same two marker paths.
- The `setup-powershell-51` job keeps `timeout-minutes: 10` and `permissions: contents: read` and references no secrets.
- The docs row for `setup-powershell-51` in `docs/architecture-overview.md` matches the new job.

## Exit condition

Approved for P7. Before merge, confirm that the macOS test suite and Windows shard 7 in run 40195111057 finish green. Fix Y-001 in the next plan edit.
