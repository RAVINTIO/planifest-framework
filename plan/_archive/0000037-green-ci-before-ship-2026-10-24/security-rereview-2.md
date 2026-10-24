# Security re-review 2: P5 fixes for 0000037-green-ci-before-ship

**Reviewer:** fresh-context P5 re-reviewer, REJECT-default
**Diff reviewed:** `git diff fdcd833..HEAD -- . ':!plan'` and the P5 lines in `plan/current/build-log.md`
**Method:** Built throwaway git repositories under `mktemp -d`, outside this repository. Ran `planifest-framework/scripts/credential-scan.mjs` and `planifest-framework/scripts/archive-current.mjs` against them. Built secret-like strings at run time and printed none. Ran the req-001, 003, 010 and 011 suites. `gitleaks` is absent here, so every scan was regex only. I did not run PowerShell.

## Overall verdict: REJECT

The P8 guard and the standards rule now work. The P7 and P9 paths still let a held-back file under `plan/current/` reach a commit and a push, or deadlock the run. One High and one Medium finding are new.

## Counts

| Verdict | Count |
|---|---|
| Closed | 13 earlier findings, plus N-02, N-03, N-04, N-05 |
| Partly closed | 1 (credentials F-04, N-01) |
| Accepted deferral | 1 (CI F-04, backlog 0000204) |
| Accepted as designed | 1 (N-06, Low) |
| New High | 1 (N-08) |
| New Medium | 1 (N-07) |

## Findings

| Report | Finding | Severity | Verdict | Evidence |
|---|---|---|---|---|
| Credentials | F-01, F-02, F-03, F-05, F-06, F-07, F-09, F-11, F-12, F-13 | High to Low | Closed | Unchanged since iteration 1. `test-0000037-req-001` passes 86 and `test-0000037-req-003` passes 119. |
| Credentials | F-04 and N-01 held-back rule, P8 and standards path | Medium | Closed for P8 | Staged `.env` and a leaking `docs/leak.md`: scan exit 1. After `git restore --staged -- {path}` the scan exits 0. `scan -- plan/current/log.md` exits 0. An explicit-path commit left both files untracked and out of `git log --name-only`. The later scan did not deadlock. |
| Credentials | F-04 and N-01 held-back rule, P7 path | Medium | Open | See N-07 and N-08. |
| Credentials | N-02 no-commit fallback | Low | Closed | In a repository with no commit, `git restore --staged -- .env` failed with `could not resolve HEAD`. `git rm --cached -- .env` exited 0, the file stayed in the working tree, and the scan exited 0. |
| Credentials | N-03 odd-length BOM file | Low | Closed | `FF FE` plus `hello` (odd body) exited 0. `FF FE` plus an AWS-format key exited 1. `FE FF` plus a key exited 1. An even-length UTF-16LE file with a key exited 1. A binary `FF FE 00 01 02` file exited 0. No exit 2 remains for these. |
| Credentials | N-04 `PRTMP` across shell calls | Low | Closed | `SKILL.md:317` now says to run `mktemp`, the scans and `gh` in one shell call and to log the folder path if split. |
| CI and setup | F-01, F-02, F-03 | Medium | Closed | Unchanged. `test-0000037-req-010` passes 50. |
| CI and setup | N-05 `setup.ps1:790-808` | Low | Closed | The code resets `$global:LASTEXITCODE = 0`, tests `Get-Command git`, and warns without a cause. It uses `if/else`, `try/finally` and `-ErrorAction SilentlyContinue`. It has no `?:`, `??`, `&&` or `-Parallel`, so it is 5.1-safe. `test-0000037-req-011` passes 49. |
| CI and setup | N-06 lone shard variable runs every suite | Low | Accepted as designed | `run-tests.sh:25` ignores both variables when only one is set. `test-0000037-req-010-windows-git-bash-leg.sh:112` asserts that behaviour. The run covers more, never less, so it fails safe. |
| CI and setup | F-04 Git Bash paths (backlog 0000204) | Medium | Accepted deferral | Recorded as the P5 Decision line in `build-log.md`. Not retested on Windows. |

## New findings

| ID | Severity | File:line | Finding | Fix |
|---|---|---|---|---|
| N-08 | High | `planifest-framework/skills/planifest-ship-agent/SKILL.md:234` and `:252` | The P9 marker step runs `git add -- "{archive-dir}"` and then a commit of `-- "{archive-dir}"`. It runs no credential scan. A held-back file that sat in `plan/current/` is now in the archive directory, because `archive-current.mjs` moves it. I built the case: an archived `.env.local` with an AWS-format key, `git add -- plan/_archive/f-1`, then `git commit -- plan/_archive/f-1`. `git log --name-only` listed `.env.local`. Step 10 then pushes the branch. Line 197 also excludes `{archive-dir}` from the P8 leftover check, so the guard never sees the file. | In `autonomous`, scan before the marker `git add` (`credential-scan.mjs -- {archive-dir}` or the file list), unstage each archived path that a `held back` line names (mapped to the archive path), and stop on exit 1 or 2. Keep the held-back files out of the commit with explicit paths, since `{archive-dir}` as a path adds the whole directory. |
| N-07 | Medium | `planifest-framework/skills/planifest-ship-agent/SKILL.md:157-166` | P7 Step 7 tells the run to unstage the path in the `held back` line, such as `plan/current/.env.local`. Step 6 has already moved that file. I ran the real `archive-current.mjs` in a temporary repository. It printed `moved: plan/current/.env.local -> plan/_archive/0000001-x-2026-01-01/.env.local` and staged the new path with `git add`. `git restore --staged -- plan/current/.env.local` then failed with `pathspec ... did not match`, and the scan exited 1 on the archive path. The run stops at P7 and cannot commit the archive. Unstaging the archive path made the scan exit 0, but that fix is not in the text, and it leads to N-08. | Say in Step 7 that a held-back path under `plan/current/` maps to `{archive-dir}/{relative-path}` after Step 6. Run the restore on that path. Add a test that runs the archive script on a fixture with a held-back file and then follows Step 7. |

No backlog entries filed. Both findings sit inside this feature's files, so they are fixes, not deferrals.

## What I checked and found sound

- The script prints path, line and rule name only. It printed no matched text in any run.
- A held-back file under `docs/` or `plan/` (outside the archive) cannot reach a commit through P8, Step 10b, Step 10c or Step 11. Each names explicit paths after `--`.
- The Step 7 scan-before-commit order in the text is correct for files outside `plan/current/`.
- The tag push uses no force.

## Fix order

1. N-08 and N-07 together, in `SKILL.md` Step 7 and the P9 marker step.
2. Add one fixture test that archives a held-back file and asserts that neither Step 7 nor the marker commit contains it.
3. Re-review `SKILL.md` Step 7 and the marker step only.
