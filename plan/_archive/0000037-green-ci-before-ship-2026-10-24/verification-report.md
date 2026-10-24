# Verify-by-Execution Report

**Toggle:** report-only
**Feature:** 0000037-green-ci-before-ship
**Date:** 2026-10-24
**Software exercised:**
- `planifest-framework/scripts/credential-scan.mjs` against fixtures in a `mktemp -d` directory outside the repository.
- The real `gh` CLI, read-only, against PR #64 and the merged PRs #62 and #63.
- `planifest-framework/tests/run-tests.sh` on a fixture copy with sharding variables set.
- Every suite under `planifest-framework/tests/` and `planifest-framework/tests/regression/`, run from three start directories.
- `test-0000037-req-008-migration-branch-diff.sh` with the real `v*` tags present.
- Run results from `gh run view`, for the latest run on PR #64.

## Summary

| Outcome | Count |
|---------|-------|
| Passed | 24 |
| Failed | 0 |
| Not verifiable here | 9 |

No behavioural failure. One out-of-scope defect is filed as backlog 0000215 (see Findings).

CI evidence relates to PR head `5d43543`. The local branch is ahead by three commits that only touch `plan/` files and are not pushed. CI therefore covers the code that P4 checks.

## Results

| Requirement | Criterion | Command and observation | Outcome |
|-------------|-----------|-------------------------|---------|
| req-003 | Scan reports `{path}:{line} {rule}`, prints no secret, says "regex only" without gitleaks | `node credential-scan.mjs --file bad.txt` (planted `AKIA` plus 16 capitals on line 2) printed `scan mode: regex only (gitleaks not found)` and `.../bad.txt:2 aws-access-key`. Exit 1. Piping the output through `grep -c ABCDEFGH` returned 0, so the matched value never prints (NFR-004). | passed |
| req-003 | Exit 0 on a clean file | `--file clean.txt` printed only the `scan mode:` line. Exit 0. | passed |
| req-003 | Exit 2 when the scan cannot run | `--file missing.txt` printed `scan could not run: file not found: ...`. Exit 2. Staged mode outside a git repository printed `scan could not run: git diff failed`. Exit 2. | passed |
| req-003 (Amended P1) | A credential added after `git add` and committed with `-- {path}` exits 1 | In a temporary repository, `g.txt` was staged clean, then the key was appended to the working tree. `node credential-scan.mjs -- g.txt` printed `g.txt:2 aws-access-key`. Exit 1. | passed |
| req-003 | Index blob is scanned as well as the working tree | `h.txt` was staged with the key, then overwritten with clean text. `-- h.txt` printed `h.txt:1 aws-access-key`. Exit 1. | passed |
| req-003 | File-name rules apply | A staged `.env` printed `.env:1 refused-file-name:.env`. Exit 1. A staged clean file gave exit 0. | passed |
| req-003 | A held-back file is rescanned and refused while the match stands | Two runs over the same staged-and-edited `g.txt` gave the same exit 1 each time. The script does not unstage or commit. The "never commits" and "build log names path and line" parts live in agent prose. | not verifiable here: the commit-blocking steps are agent instructions, so no script runs them. Shell tests cover the text. |
| req-003 | With gitleaks on PATH | `command -v gitleaks` found nothing, so only the regex-only mode ran. | not verifiable here: gitleaks is not installed on this machine |
| req-004 | `--file` mode scans PR title and body files | See the req-003 `--file` rows. Exit 1 on a planted key, 0 on clean text, 2 on a missing file. | passed |
| req-004 | A second match or exit 2 means no `gh pr create` and an `Exception waiting (P9, 7)` line | The exit codes that drive the branch were observed (1 and 2). The regenerate-once logic and the exception line are ship-agent instructions. | not verifiable here: no script runs the Step 10 logic |
| req-001 | A `fail` bucket maps to red, and exit 1 with valid JSON is data | `gh pr checks 62 --json name,bucket,state` printed JSON with `"bucket":"fail"` for `Test suite (ubuntu-latest)` and four `pass` entries. Plain `gh pr checks 62` exited 1. | passed |
| req-001 | A `pass` bucket and exit 0 on an all-green PR | `gh pr checks 64 --json name,bucket,link` returned 13 entries, all `pass`. Exit 0. | passed |
| req-001 | An unreadable status (auth failure) is reported, never read as a pass | `GH_TOKEN=bad gh pr checks 64 --json name,bucket,link` printed `HTTP 401: Bad credentials` and `Try authenticating with: gh auth login`. Exit 1. No JSON on stdout. | passed |
| req-001 | An empty list at the end of the window reads unknown with "no checks reported" | `gh pr checks 30 --json name,bucket,link` (PR with no checks) printed nothing on stdout and `no checks reported on the '...' branch` on stderr. Exit 1. Step 10c expects an empty JSON list. See Findings, backlog 0000215. | passed with a defect noted: the status never reads as a pass, but the documented empty-list path does not match real output |
| req-001 | A `cancel` bucket reads unknown | The cancelled run 40052288281 shows `Test suite (windows-latest, shard 2 of 4)` as `cancelled` in `gh run view --json jobs`. Its bucket is not retrievable, because a newer run replaced it on `gh pr checks`. | not verifiable here: no live PR reports a `cancel` bucket |
| req-001 | A `pending` bucket, the 30-second poll, the 20 and 30 minute windows, the three fix attempts, `gh pr ready --undo`, and the `PR: #{n}` log line | No script runs the poll or the fix loop. The build log already records this deviation (P3). | not verifiable here: agent instructions only |
| req-002 | Step 5 lists merged PRs and picks the newest `mergedAt` | `gh pr list --state merged --base main --limit 10 --json number,url,title,mergedAt` returned 10 entries. Sorted by `mergedAt`, the newest is #63 (2026-10-23T20:38:56Z). | passed |
| req-002 | Step 5 reads that PR's checks and words the result | `gh pr checks 63 --json name,bucket,link` returned 5 `pass` entries, so the report reads "the last merged PR's checks: all passed". Exit 0. The command reads no `main` run. | passed |
| req-002 | A failed check on a merged PR is named, not reported as "could not be read" | PR #62 returned exit 1 with valid JSON and one `fail` bucket. This is the case the override expects to read as `1 failed: Test suite (ubuntu-latest)`. | passed |
| req-002 | `gh` signed out names `gh auth login` | The bad-token run above printed the `gh auth login` hint. | passed |
| req-002 | "no merged PR to check", and `gh` missing | This repository has merged PRs, and `gh` is installed. Neither state can be produced without changing the machine. | not verifiable here |
| req-005 | Fixture repository with and without `doc-checks.yml` | The P6 docs-agent step has not run. The post-P6 revalidation is an agent step with no script. | not verifiable here |
| req-008 AC-008.1, AC-008.2 | Fixture repository cases: exact list passes, omitted skill fails and names the path, extra path fails, absent base tag prints SKIP, frozen migration prints SKIP, no `v*` tags prints `SKIP: no v* tags fetched` | `bash planifest-framework/tests/test-0000037-req-008-migration-branch-diff.sh` ended with `Results: 20 passed, 0 failed`. | passed |
| req-008 AC-008.3 | Real comparison against this repository | The same run printed `SKIP: migrate-0.34.0-rerun-setup.md is frozen: version 0.34.0 is not higher than the highest v* tag v0.34.0`. The real `v0.34.0..HEAD` comparison skipped because `migrate-0.35.0-rerun-setup.md` does not exist before P6 and the highest migration already carries its release tag. The tags are present locally. The criterion says this verifies in the post-P6 revalidation. | not verifiable here: waits for P6 |
| req-009 AC-009.1 | Every suite passes from the repository root, from `planifest-framework/tests/`, and from a temporary directory | A script ran all `test-*.sh` files in `planifest-framework/tests/` and `planifest-framework/tests/regression/` from each directory. Root: 141 passed, 0 failed. Tests directory: 141 passed, 0 failed. Temporary directory: 141 passed, 0 failed. The three passes ran concurrently and none failed. | passed |
| req-009 AC-009.3 | The lint reports 0 findings on the real suites | `bash planifest-framework/tests/test-0000037-req-009-portability-lint.sh` printed `scanned 142 files, 0 findings, 13 marked lines` and `Results: 30 passed, 0 failed`. | passed |
| req-009 AC-009.3 | Re-adding a bare `grep -rn` line fails the lint and names file and line | In a copy of the tests directory, I appended `grep -rn pattern somedir` to `test-0000010-framework-quality-improvements.sh`. The copied lint printed `1 findings` and `test-0000010-framework-quality-improvements.sh:205: grep-recursive: grep -rn pattern somedir`, and failed `AC-009.3`. | passed |
| req-010 (supports) | `run-tests.sh` shards partition the suites | A fixture copy with 5 feature and 2 regression suites ran under `PLANIFEST_SHARD_COUNT=3`. Shard 1 ran a, d, r2. Shard 2 ran b, e. Shard 3 ran c, r1. Each suite ran exactly once. Index 4 of 3 and a non-numeric value exit 2 with a message. Empty variables ran all 7 suites. | passed |
| req-010 (supports) | A nested runner sees no shard | Under shard 3 of 3, suite c ran a second runner copy. The nested run printed no `Shard` line and ran its suite. | passed |
| req-010 AC-2 | The Windows Git Bash check passes on the feature PR | `gh pr checks 64` and `gh run view 40053917957 --json jobs` show 7 shards, all `success`. Durations: shard 1 2m07s, shard 2 4m00s, shard 3 13m07s, shard 4 4m08s, shard 5 3m05s, shard 6 2m05s, shard 7 3m27s. The check name is now `Test suite (windows-latest, shard N of 7)`, per ADR-014, not the literal `Test suite (windows-latest)` in the criterion wording. Shard 3 passed the old 10 minute limit, and the workflow now allows 20 minutes for Windows (`timeout-minutes: ${{ matrix.os == 'windows-latest' && 20 || 10 }}`). | passed |
| req-011 AC-1 | `Setup under Windows PowerShell 5.1` passes on the feature PR | Run 40053917957: `Setup under Windows PowerShell 5.1` was `success`, 55 seconds (02:22:49Z to 02:23:44Z). The job uses `shell: powershell`, `permissions: contents: read`, `timeout-minutes: 10`, and a version check that fails unless the major version is 5. | passed |
| req-011 AC-2 | `test_setup.ps1` assertions pass under PowerShell 7 and 5.1 | In the same run, `Setup under PowerShell 7 (Windows)` was `success` (42 seconds) and the 5.1 job was `success`. Both run `test_setup.ps1`. I read the job conclusions only. I cannot run PowerShell here to see the individual assertions. | passed on CI conclusions, assertion detail not observed |
| req-001 to req-011 | Criteria whose governing type is `integration` or `unit` (text tests over skills, standards, templates, and docs) | Outside this check's scope. The full local run above passed all 11 `test-0000037-*` suites from three directories. | not verifiable here as execution (covered by the suites) |

Counts: the Summary counts table rows, and a criterion can span several rows. It counts 24 `passed` rows (two carry a noted caveat) and 9 `not verifiable here` rows. The last row covers the text-test criteria that this check does not execute.

## Findings

1. **Backlog 0000215 (out of scope, not a validation failure).** For a PR with no checks, real `gh pr checks --json` prints nothing on stdout, writes `no checks reported on the '{branch}' branch` to stderr, and exits 1. Step 10c in the ship skill and GUTD step 5 expect an empty JSON list. Under the current text, a fresh PR whose jobs have not registered would read as "could not be read" on the first poll. A check never reads as a pass, so the risk is a premature `P9 blocked`. File: `plan/backlog/0000215-gh-pr-checks-prints-no-json-before-checks-register/entry.md`.
2. **Suite count differs from the requirement text.** req-009 says P4 runs 135 suites (130 plus five). The repository holds 141 (108 feature suites and 33 regression suites). All 141 passed from each start directory.
3. **Lint numbers differ from the Amended text.** The lint scanned 142 files (the amendment says 132) and counted 13 marked lines (the amendment says 12). The extra marker sits in `test-0000037-req-001-p9-ci-check.sh`, a suite this feature adds. Findings are 0, as required.
4. **Shard 3 took 13m07s on Windows.** It stays under the 20 minute limit, but it is close to the old limit and carries most of the Windows time. Backlog 0000213 already covers duration-weighted shards.
5. **No behavioural failure was found.** Nothing in this report is a validation failure.

## Not changed

- No commits, pushes, PR edits, or branch changes.
- `plan/.run-mode`, the build-log `Run mode` row, and the P1 Toggle record are untouched.
- Fixtures live under `mktemp -d` directories outside the repository. The repository gained only this report and the backlog entry.
