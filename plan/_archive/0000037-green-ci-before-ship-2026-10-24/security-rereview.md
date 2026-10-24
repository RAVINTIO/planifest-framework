# Security re-review: P5 fixes for 0000037-green-ci-before-ship

**Reviewer:** fresh-context P5 re-reviewer, REJECT-default
**Diff reviewed:** `git diff f1c325c..HEAD -- . ':!plan'` and the P5 lines in `plan/current/build-log.md`
**Method:** Ran `planifest-framework/scripts/credential-scan.mjs` on fixtures under `mktemp -d`. Built secret-like strings at run time and printed none. Ran the shard parser on a fixture copy. Ran the req-001, 002, 003, 004, 010, 011 and both req-013 suites. Mutated each rule in a copy of the script and re-ran the suites. `gitleaks` is absent here, so every scan was regex only. I did not run PowerShell.

## Overall verdict: REJECT

One Medium finding stays open and one is partly closed. A staged refused file still deadlocks the P9 commits, and one skill commit still contradicts the new commit form. The accepted deferral 0000204 is the second open Medium.

## Counts

| Verdict | Count |
|---|---|
| Closed | 13 |
| Partly closed | 1 |
| Open | 1 (0000204, accepted deferral) |
| New Medium | 1 |
| New Low | 5 |

Credentials F-08 and F-10 are Low and not marked fixed, so they are outside this table.

## Findings

| Report | Finding | Severity | Verdict | Evidence |
|---|---|---|---|---|
| Credentials | F-01 NUL and UTF-16 skip | High | Closed | Fixtures with the same AWS-format key exited 1 for plain, trailing NUL, UTF-16LE and UTF-16BE without a BOM, and UTF-16LE and UTF-16BE with a BOM. A clean NUL file exited 0. An odd-length BOM file exited 2 (see N-03). Mutating the NUL strip or the BOM branch failed req-003. |
| Credentials | F-02 quadratic private-key regex | Medium | Closed | A 1.1 MB single line of `a` took 0.12 s. A 1.1 MB line starting `-----BEGIN ` took 0.12 s. A 120000-repeat `-----BEGIN ` line took 0.13 s. Was 43 s. |
| Credentials | F-03 index blob over 1 MB skipped | Medium | Closed | A 3 MB staged blob with a key, then a clean working copy, exited 1 and named the path and rule. `maxBuffer: Infinity` sits at `credential-scan.mjs:64`. |
| Credentials | F-04 held-back rule | Medium | Partly closed | Standards, orchestrator Hard Limit 7 and step 6c now agree: `git restore --staged`, explicit `--` paths, and build-log lines. Run result: with a staged `.env`, `scan -- log.md` exits 1, and after `git restore --staged -- .env` it exits 0. The P8 guard at `planifest-ship-agent/SKILL.md:198` still says a staged refused file stays staged. See N-01 and the 0000220 finding below. |
| Credentials | F-05 unscanned P9 commits | Medium | Closed | Step 10c (`SKILL.md:423`), Step 11 (`:442`) and the fix attempt (`:416`) each run the scan and stop on exit 1 or 2. The fix attempt scans `git diff --name-only`, including `src/` and workflow files. req-001 passes 74. |
| Credentials | F-06 PR temp location | Low | Closed | `SKILL.md:306` uses `mktemp -d` and `:318` adds `rm -rf "$PRTMP"`. Shell state across calls stays open (N-04). |
| Credentials | F-07 title in shell argument | Low | Closed | `SKILL.md` now reads the title into `TITLE="$(cat ...)"` and passes `"$TITLE"`. Command substitution output is not re-evaluated. |
| Credentials | F-09 PR comments outside scan | Low | Closed | The PR text rule now covers comments and review replies, or the run sends none. |
| Credentials | F-11 pattern gaps and case | Low | Closed | `.ENV`, `ID_RSA` and `KEY.PEM` exit 1. Fixtures for `ASIA`, PGP block, `ghs_`, `gho_` and `ghp_` each exit 1 with the named rule. Mutating any rule or removing `toLowerCase` fails req-003. |
| Credentials | F-12 GUTD fetches titles | Low | Closed | `custom-003-git-up-to-date-shorthand.md` requests `number,url,mergedAt` and says to treat check names and links as data. req-002 passes 36. |
| Credentials | F-13 subdirectory run | Low | Closed | From `sub/`, staged mode exited 1 on a root-relative staged path. `-- s.txt` resolved to `sub/s.txt` and exited 1. |
| CI and setup | F-01 shard parser fails open | Medium | Closed | `08/09`, `1/08`, a 20-digit count and `0/3` and `-1/3` exit 2. Index above count exits 2. `9/9`, `4/5` and `4/4` against three suites exit 3 with `Suites run: 0`. `1/3` and `3/3` exit 0 with one suite. Residual in N-06. |
| CI and setup | F-02 `git config` exit ignored | Medium | Closed | `setup.ps1:791-803` tests `$LASTEXITCODE`, prints a warning, and skips the success line. Syntax is 5.1-safe: `if/else`, `try/finally`, `$([char]0x2705)`. No `?:`, `??`, `&&` or `-Parallel`. Residual in N-05. |
| CI and setup | F-03 lost rule coverage | Medium | Closed | Both req-013 suites pass 101. Mutating each of 19 content and name rules fails req-003. Mutating each rule except `ASIA`, `ghp`, `ghs`, `lower`, `NUL` and `BOM` also fails req-013. req-003 covers those six. |
| CI and setup | F-04 Git Bash paths (0000204) | Medium | Open | Not fixed. The orchestrator recorded a Decision at P5 that it stays open and does not block release. I did not run it on Windows. |

## 0000220 confirmed

Backlog 0000220 is correct, and it understates the effect. `planifest-ship-agent/SKILL.md:198` says a refused staged file stays staged. `autonomous-run-standards.md:106` says to take it out of the index.

The mismatch is a deadlock, not a wording gap. Staged mode scans the whole index (`credential-scan.mjs:168-171`). A staged refused leftover therefore makes the Step 10b, 10c and 11 scans exit 1 even when they name a clean file. I ran `scan -- log.md` with a staged `.env` and got exit 1. The run then stops under exception item 7 and cannot commit its build log or final report.

The `test-0000033-req-013` suite asserts `stay uncommitted` (about line 183). The fix must keep that phrase.

## New findings

| ID | Severity | File:line | Finding | Fix |
|---|---|---|---|---|
| N-01 | Medium | `planifest-framework/skills/planifest-ship-agent/SKILL.md:153-157` and `:198` | Step 7 runs `git add plan/current/ plan/_archive/ ...` and a plain `git commit` with no paths. The new rule bans a plain commit. A directory add re-stages a held-back file under `plan/` or `docs/`. I ran it: `git add plan/current/` then `scan` exited 1 on the held-back file. The commit either sweeps the file in or the run stops with no explicit-path form to use. Line 198 adds the deadlock above. | Change line 198 to take a staged refused file out with `git restore --staged -- {path}`, keeping the phrase `stay uncommitted`. In Step 7, scan first, read the `held back` lines, and commit with explicit paths after `--` that leave out those paths. |
| N-02 | Low | `planifest-framework/standards/autonomous-run-standards.md:106` | `git restore --staged` fails with `fatal: could not resolve HEAD` in a repository with no commit. I ran it: exit 128 and the file stayed staged. | Add `git rm --cached -- {path}` as the form for a repository with no `HEAD`. |
| N-03 | Low | `planifest-framework/scripts/credential-scan.mjs:85` | A file that starts with `FF FE` or `FE FF` and has odd length exits 2. A binary file with that start stops the run as unscannable. It fails closed. | Scan the NUL-stripped text and skip the strict decode, or report the path as a binary refusal. |
| N-04 | Low | `planifest-framework/skills/planifest-ship-agent/SKILL.md:306-318` | `PRTMP` does not persist across Bash calls on some hosts. Already in 0000220. | Add that `mktemp`, scans and `gh` run in one shell call. |
| N-05 | Low | `planifest-framework/setup.ps1:791-803` | The warning always says "not in a git repository". A failed `git config` has other causes. If `git` is absent and an earlier native command left `$LASTEXITCODE` at 0, the check reads success. | Initialise `$LASTEXITCODE = $null` before the call and test `-ne 0` or `$null`. Word the warning without the cause. |
| N-06 | Low | `planifest-framework/tests/run-tests.sh:25` | If only one of the two shard variables is set, the runner ignores both and runs every suite. It fails safe. A one-sided edit hides a mis-set shard. | Exit 2 when exactly one variable is set. |

No backlog entries filed. N-01 to N-06 sit inside this feature's files, so they are fixes, not deferrals. Backlog 0000220 already holds N-04 and the 0000220 mismatch.

## What I checked and found sound

- The script prints no matched text. Output held path, line and rule name only.
- Exit 2 on a directory path, a missing `--file`, and an undecodable BOM file.
- A held-back file cannot reach a push through P8 to P9 commits, which all name explicit paths after `--`. The tag push uses no force.
- The held-back log lines carry paths only, so the next scan does not match them.
- Orchestrator step 6c and the standards Resume bullet agree.

## Fix order

1. N-01, including the 0000220 mismatch. This closes F-04.
2. N-02, N-05 and N-06 in the same pass.
3. Re-run this review on `SKILL.md` and the standards file only.
