# Security re-review 4: P5 approach 2 for 0000037-green-ci-before-ship

**Reviewer:** fresh-context P5 re-reviewer, REJECT-default
**Diff reviewed:** `git diff ea22c09..HEAD -- . ':!plan'` and the P5 lines in `plan/current/build-log.md`
**Method:** Built throwaway git repositories under `mktemp -d`, outside this repository. Ran the real `planifest-framework/scripts/credential-scan.mjs --safe-paths` and the real `planifest-framework/scripts/archive-current.mjs`. Acted out P7 Step 7, the P8 leftover commit, the P9 marker step, and Steps 10c and 11 as `SKILL.md` words them for `autonomous`. Built the key at run time and printed none. I grepped history for a fragment of it and report counts. `gitleaks` is absent here, so every scan was regex only. I did not run PowerShell.

## Overall verdict: REJECT

N-09, N-10 and N-11 are closed. One new Medium finding (N-12) is open. Every `--pathspec-from-file` list is read as a git pathspec, so a safe file whose name holds a glob character also matches a held-back tracked file. In my fixture the key reached `HEAD`.

## Findings

| Finding | Severity | Verdict | Evidence |
|---|---|---|---|
| N-09 tracked held-back file in a commit | Medium | Closed for the literal-name case. See N-12 for glob names. | Tracked `src/app.js` and `docs/d.md` modified to hold a key, plus a tracked `plan/current/p.md` and `src/b.js`, and an untracked `src/new.js`. Scan exit 1 named the two key files. The out-file held the other three. Commit `fix(p9): repair` listed those three only. Key fragment count in `git log --all -p`: 0. `git show HEAD:src/app.js`: 0 key lines. A second attempt scanned the same two files and held them back again, so there was no deadlock. |
| N-09 variants | Medium | Closed | A tracked file with the key staged: held back, commit left it staged, history count 0. A key only in the index blob with a clean working tree: scan exit 1, `g.js` committed alone, history count 0. |
| N-10 restore on an untracked file | Low | Closed | The standard step 4 and the P8 guard say to unstage only a path staged as a new file. An untracked, unstaged key file was never restored and never committed. |
| N-11 non-ASCII and colon names | Low | Closed | An untracked `café:key.txt` and `ключ.txt` (key) and a safe `ok:é.txt`. The report showed `?` for the unusual bytes. The out-file held the raw name `ok:é.txt`. Commit listed `ok:é.txt` only. History count 0 and no path matching `key`. Backlog 0000222 is now moot for the stall. |
| P7 Step 7 with the real archive script | Medium | Closed | `archive-current.mjs` moved an untracked `.env.local` and a tracked-then-modified `tracked-leak.md`. The scan named both at their archive paths. The old `plan/current/tracked-leak.md` deletion went into the safe list. The commit held `build-log.md`, `design.md`, `requirements/req-001.md` and the deletion. Key count 0. Path `env.local` in history: 0. |
| P8 leftover commit | Medium | Closed | Same scan and pathspec form. Held-back untracked files stayed untracked and out of every commit. |
| P9 marker step | High | Closed | Candidate list held the archive files and the two tracked markers. Scan exit 1. The out-file held `build-report.md` and both markers. Commit `plan(p9): clear session markers` deleted both markers and added `build-report.md`. A held-back staged-new `tracked-leak.md` stayed staged and out of the commit, even though I did not unstage it. Key count 0. |
| Step 10c build-log commit and Step 11 report | Medium | Closed | A clean `build-log.md` committed alone. A `final-report.md` with a key: exit 1, empty out-file, no commit. The commit count did not change. |
| Empty safe list | n/a | Sound | All candidates held back: out-file 0 bytes. The skip rule made no commit. A probe without the skip rule committed the whole index, so the skip rule in step 5 is required and present. |
| Exit 2 | n/a | Sound | Outside a repository, a directory candidate, and an unwritable out-file each exited 2 with an empty or absent out-file. A reused out-file with stale content was emptied at the start of the run. |
| Repository with no commit | n/a | Sound | `git restore --staged` failed with `could not resolve HEAD`. `git rm --cached` exited 0. The first commit held the clean file only. An untracked-only run also committed the safe file only. |
| Spaces and leading `-` | n/a | Sound | `a b.js` and `./-dash.js` committed. `./-bad key.js` held back. A bare `-dash.js` after `--` scanned as a path. |
| Long candidate list | n/a | Sound, fails closed | 3001 candidates scanned correctly with the key file held back. 39013 candidates made `node` fail with `Argument list too long` (exit 126) and left the out-file empty. See N-14. |
| Rename | n/a | Sound | `--no-renames` listed both paths. The old path deletion committed. The new key path stayed untracked. Key count 0. |
| Deleted file whose old blob held a key | n/a | Sound | Deletion scanned exit 0 and committed as a deletion. A staged-new key file removed from the working tree also committed no key. |
| `--pathspec-from-file` falls back to the whole index | n/a | Sound with step 5 | Only an empty file does this. Step 5 skips the commit on an empty file. |
| Earlier credential findings F-01 to F-07, F-09, F-11 to F-13, N-01 to N-08 | High to Low | Closed | Unchanged. The two suites below pass. |
| CI and setup F-01 to F-03, N-05 | Medium, Low | Closed | Unchanged since re-review 3. |
| CI and setup N-06 | Low | Accepted as designed | Unchanged. |
| CI and setup F-04 Git Bash paths (backlog 0000204) | Medium | Accepted deferral | Recorded as the P5 Decision line in `build-log.md`. Not retested. |

## New findings

| ID | Severity | File:line | Finding | Fix |
|---|---|---|---|---|
| N-12 | Medium | `planifest-framework/standards/autonomous-run-standards.md` step 6 of `### Scan-then-commit`, and every `git add` and `git commit --pathspec-from-file` line in `planifest-framework/skills/planifest-ship-agent/SKILL.md` (Step 7, P8 leftovers, P9 marker, Steps 10c, 10b and 11) | Git reads each line of the pathspec file as a pathspec, with glob and `:` magic. A safe file named `a*.js` also matched a tracked, modified `ab.js` that held the key. The scan held back `ab.js` and wrote `a*.js` only. The commit listed both files and `git show HEAD:ab.js` held the key (history count 1). The same happened with safe `pages[id].js` and held-back `pagesi.js` (count 1). A name such as `[id].js` is common in web projects. With `GIT_LITERAL_PATHSPECS=1` the commit held `a*.js` only (count 0), and `git --literal-pathspecs add` staged only `a*.js`. A safe file named `:!bad.js` was read as an exclude and was not added. That case failed without a leak. | Make every `git add` and `git commit` that uses `--pathspec-from-file` literal. Write `git --literal-pathspecs commit ...` and `git --literal-pathspecs add ...`, or set `GIT_LITERAL_PATHSPECS=1`. Add a fixture test with a safe `a*.js` and a held-back tracked `ab.js` that asserts `git show HEAD:ab.js` stays clean. |
| N-13 | Low | `planifest-framework/skills/planifest-ship-agent/SKILL.md` P9 Step 8, step 4 code block | The block labelled "Run the sequence" still holds the old `git commit ... -- "{archive-dir}" $(git ls-tree ...)` line. A paragraph below it says not to run that line in `autonomous` and gives the pathspec commit instead. The P8 and Step 10b blocks put the old lines after a "don't run them" sentence, which is clearer. An `autonomous` run that executes the first block as written takes the working-tree path-list commit. That commit carries a staged held-back archive file. The build log says old suites assert these lines exactly (the Deviation line). | Move the old line out of the executable block, for example into a sentence marked `interactive` and `continuous` only. Update the old suites that assert the exact text. |
| N-14 | Low | `planifest-framework/standards/autonomous-run-standards.md` steps 2 and 3 of `### Scan-then-commit` | The steps cover exit 0, 1 and 2 only. An argument list that is too long makes the shell stop `node` with exit 126 and run no scan. A reused `{out-file}` would then keep the earlier step's list. A fresh `mktemp` file per step is empty, so the empty-list skip stops the commit and nothing leaks. The text also never says to remove the out-file. It holds paths only, so this is hygiene. | Say to use a new `mktemp` file for each commit and to treat any exit other than 0 or 1 as exit 2. Say to remove the file after the commit. For a long list, split it into batches. |

## The two tests

- `bash planifest-framework/tests/test-0000037-req-003-credential-scan.sh` passes 158 of 158.
- `bash planifest-framework/tests/test-0000037-req-003-archive-held-back.sh` passes 100 of 100.
- The held-back suite runs the real archive script. It covers a tracked src file (line 198), a tracked docs file (line 217), an untracked unstaged file (line 261), an empty safe list and exit 2. It tests what it claims for N-09, N-10 and N-07.
- Neither suite uses a file name with a glob character, so neither can catch N-12.

## Other checks

- The out-file lives outside the repository when the step uses `mktemp`. It holds file paths and no key text.
- The script never printed matched text in any run.
- No backlog entry filed. N-12 to N-14 sit inside this feature's lines, so they are fixes and not deferrals.

## Fix order

1. Fix N-12 in the standard and every ship skill commit line, and add the glob fixture test.
2. Fix N-13 and N-14 in the same pass.
3. Re-review step 6 of `### Scan-then-commit` and the P9 marker block only.
