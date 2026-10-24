# Security re-review 5: P5 approach 2 iteration 2 for 0000037-green-ci-before-ship

**Reviewer:** fresh-context P5 re-reviewer, REJECT-default
**Diff reviewed:** `git diff 24b4241..HEAD -- . ':!plan'` and the P5 lines in `plan/current/build-log.md`
**Method:** Built throwaway git repositories under `mktemp -d`, outside this repository. Ran the real `planifest-framework/scripts/credential-scan.mjs --safe-paths` and the real `planifest-framework/scripts/archive-current.mjs`. Acted out `### Scan-then-commit` and the `autonomous` blocks of `planifest-framework/skills/planifest-ship-agent/SKILL.md` as written. Built a random `ghp_` key at run time and printed none. I report counts of a 24-character key fragment in `git log --all -p` and of paths matching `key` in `git log --all --name-only`. `gitleaks` is absent here, so every scan was regex only. I did not run PowerShell.

## Overall verdict: APPROVE

N-12, N-13 and N-14 are closed. No Critical, High or Medium finding is open, apart from the accepted 0000204 deferral. Two new Low findings (N-15, N-16) remain. Neither blocks the gate.

## Findings

| Finding | Severity | Verdict | Evidence |
|---|---|---|---|
| N-12 glob names | Medium | Closed | Each fixture had a safe untracked name beside a tracked, modified, held-back file it could match. `a*.js` beside `ab.js`, `pages[id].js` beside `pagesi.js`, `?x.js` beside `ax.js`, `:(glob)*.js` beside `zz.js`, and `src/**/x.js` beside `src/a/x.js`: scan exit 1, commit listed the safe name only, `git show HEAD:{held}` key lines 0, history fragments 0, key paths 0. A directory `d*/` with `d*/s.js` beside `dx/f.js`: commit listed `d*/s.js` only, fragments 0. The `:`-prefixed name `:bad.js` stalled the scan. See N-16. |
| N-13 P9 marker block | Low | Closed for a non-empty list | Real archive run, then the block as written for `autonomous`. Scan exit 1 named `.env.local` and `tracked-leak.md` under the archive directory. Commit `plan(p9): clear session markers` held the three marker deletions and `build-report.md` only. Both held-back files stayed untracked. `git ls-files` for the markers printed nothing. Fragments 0, key paths 0. The old path-list line is a `#` comment. The old line, run on its own, committed a staged key file (fragments 1), so the comment form is needed. See N-15 for the empty list. |
| N-14 other scan exits, reused out-file, cleanup | Low | Closed | An argument list of 30000 paths gave exit 126. A node-less PATH gave exit 127. Step 3 of the standard reads both as exit 2 and commits nothing. A stale out-file survived both failures (9 bytes), so the "fresh `mktemp -d` per commit" text matters, and it is present in the standard and in the P7, P8, P9, Step 10c and Step 11 text. Two `mktemp -d` calls gave distinct folders and `rm -rf` removed them. |
| N-09 tracked held-back file in a fix attempt | Medium | Closed | Tracked `tr.js` with the key and untracked `new.js`: exit 1, commit listed `new.js` only. Fragments 0, key paths 0. |
| N-09 index-only key | Medium | Closed | Key staged, working tree clean: exit 1, `n.js` committed alone, `HEAD:tr.js` key lines 0, fragments 0, key paths 0. |
| P7 Step 7 with the real archive script | Medium | Closed | `archive-current.mjs` moved an untracked `.env.local` and a modified tracked `tracked-leak.md`. The scan named both at their archive paths. The commit held the archived design and requirement files and the old `tracked-leak.md` deletion. Fragments 0, key paths 0. |
| P8 and P9 leftover, Step 10c, Step 11 commits | Medium | Closed | Text reads `git --literal-pathspecs add` and `commit` with `--pathspec-from-file`. The test greps confirm no non-literal safe-list command in each block. |
| Empty safe list (standard step 5) | n/a | Sound | All candidates held back: out-file 0 bytes, no commit, commit count 1 to 1. Fragments 0. |
| Exit 2 | n/a | Sound | A directory candidate gave `could not read dd`, exit 2, no commit. Fragments 0. |
| Repository with no commit | n/a | Sound | `git rm --cached` removed the key file. The first commit held `ok.js` only. Fragments 0, key paths 0. |
| Rename | n/a | Sound | `--no-renames` listed both paths. The old path deletion committed and the new key path stayed untracked. Fragments 0, key paths 0. |
| Deleted key file | n/a | Sound | Scan exit 0 and the deletion committed. My fixture had committed the key earlier, so history held 1 fragment before and 2 after. The extra hit is the deletion diff of the earlier blob. No new blob carries the key. |
| N-10, N-11 | Low | Closed | Unchanged. The held-back suite passes. |
| Earlier credential findings F-01 to F-07, F-09, F-11 to F-13, N-01 to N-08 | High to Low | Closed | Unchanged. The scan suite passes. |
| CI and setup F-01 to F-03, N-05 | Medium, Low | Closed | Unchanged since re-review 3. |
| CI and setup N-06 | Low | Accepted as designed | Unchanged. |
| CI and setup F-04 Git Bash paths (backlog 0000204) | Medium | Accepted deferral | Recorded as the P5 Decision line in `build-log.md`. Not retested. |

## New findings

| ID | Severity | File:line | Finding | Fix |
|---|---|---|---|---|
| N-15 | Low | `planifest-framework/skills/planifest-ship-agent/SKILL.md` lines 266-272 (P9 Step 8, step 4 code block) | The block runs `git --literal-pathspecs commit --pathspec-from-file="{out-file}"` with no empty-list guard. The skip rule sits in the prose above the block. With an empty out-file git commits the whole index. In my fixture the markers were untracked and a tracked archive file held the key and was staged. Scan exit 1, out-file 0 bytes, and the block committed that file (fragments 1). This needs untracked markers, an all-held-back archive and a staged tracked key file, so I rate it Low. The prose guard exists and the other blocks rely on prose the same way. | Add `[ -s "{out-file}" ] &&` before the `git --literal-pathspecs commit` line, or add a comment line in the block that says to skip it when the out-file is empty. |
| N-16 | Low | `planifest-framework/scripts/credential-scan.mjs:214` and `:264` (`git show :${rel}`) | An indexed file whose name starts with `:` makes `git show ::name` fail. The scan exits 2 with `git -C failed`, so the run stops under exception item 7. It fails closed and leaks nothing. A safe `:bad.js` staged beside a held-back file stalled the commit (history fragments 0). The form `git show ":./${rel}"` returned 0 in my probe for `:bad.js`, `:(glob)q.js` and `:!e.js`. | Read index blobs with `:./${rel}`, or pass the path through `git cat-file --batch`. Add a `:`-prefixed fixture to the scan suite. |

## The two tests

- `bash planifest-framework/tests/test-0000037-req-003-credential-scan.sh` passes 158 of 158.
- `bash planifest-framework/tests/test-0000037-req-003-archive-held-back.sh` passes 141 of 141.
- The held-back suite builds `a*.js` beside `ab.js` and `pages[id].js` beside `pagesi.js`. It asserts the commit names the safe file only, `HEAD:{held}` holds no key, and history holds no fragment. It tests N-12 for the two names the first finding used.
- Text assertions check `--literal-pathspecs` on the standard and on every ship block. The grep that finds a non-literal safe-list command returns 0. The N-13 assertions find the block by line offset, which breaks if someone adds a line there.
- The suites have no `?x.js`, `:`-prefixed or glob-directory fixture, and no empty-list run of the P9 block. My runs cover those, and N-15 and N-16 came from them.
- The suite harness re-implements the commit steps in shell. It proves the procedure, not the agent's following of it.

## Other checks

- The script never printed matched text in any run, and the report shows `?` for unusual bytes.
- The out-file holds paths only and lives outside the repository.
- No backlog entry filed. N-15 and N-16 sit inside this feature's lines.

## Fix order

1. N-15: add the empty-list guard to the P9 marker block.
2. N-16: read index blobs with `:./` in `credential-scan.mjs`, and add a fixture.
