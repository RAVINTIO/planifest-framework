# Security re-review 3: P5 fixes for 0000037-green-ci-before-ship

**Reviewer:** fresh-context P5 re-reviewer, REJECT-default
**Diff reviewed:** `git diff 8619562..HEAD -- . ':!plan'` and the P5 lines in `plan/current/build-log.md`
**Method:** Built throwaway git repositories under `mktemp -d`, outside this repository. Ran the real `planifest-framework/scripts/archive-current.mjs --feature-id` and `planifest-framework/scripts/credential-scan.mjs`. Acted out P7 Step 6 and 7, the P8 leftover commit, the P9 marker step, and Steps 10b, 10c and 11 as `SKILL.md` words them. Followed `### Scan-then-commit`. Built secret-like strings at run time and printed none. `gitleaks` is absent here, so every scan was regex only. I did not run PowerShell.

## Overall verdict: REJECT

N-07 and N-08 are closed. One new Medium finding (N-09) is open. A held-back tracked file under `src/` or `docs/` reaches a commit when the run reuses its original path list after the unstage.

## Findings

| Finding | Severity | Verdict | Evidence |
|---|---|---|---|
| N-07 Step 7 unstages the old `plan/current/` path | Medium | Closed | Real archive run moved `plan/current/.env.local` to `plan/_archive/0000001-x-2026-10-24/.env.local`. The scan named the archive path. `git restore --staged` on that path exited 0, the rescan exited 0, and the P7 commit held `design.md`, `build-log.md` and `requirements/req-001.md` only. The text now says to act on the scan's path. |
| N-08 P9 marker commit has no scan | High | Closed | The marker step stages `{archive-dir}`, and the scan exited 1 on the archive `.env.local`. After the unstage the scan exited 0. The commit `plan(p9): clear session markers` listed `build-report.md` only. `git log --all --name-only` matched `env.local` 0 times in both repositories. The key file stayed in the working tree. |
| Credentials F-04 and N-01 held-back rule | Medium | Closed for P7, P8, P9, 10b, 10c, 11 | Ran all steps with a commit and with no commit yet (`git rm --cached` fallback, exit 0). No step deadlocked. A `docs/` held-back file (untracked) stayed out of the P8 commit. Two held-back files were both held back. A held-back file staged by `git add` was unstaged once and the rescan exited 0. See N-09 for the tracked-file exception. |
| Exit 2 | n/a | Confirmed | Outside a git repository the scan printed `scan could not run: git rev-parse failed` and exited 2. Every step text says to stop and commit nothing on exit 2. |
| Deleted held-back file | n/a | Sound | A staged deletion and an unstaged working-tree deletion of a tracked secret file both scanned at exit 0. A path-mode scan of a missing file exits 0. |
| Duplicate scan lines | n/a | Sound | The index copy and the working-tree copy print the same path twice with different line numbers. Unstaging the path once empties the index entry, and the rescan exited 0. |
| Credentials F-01 to F-03, F-05 to F-07, F-09, F-11 to F-13, N-02 to N-05 | High to Low | Closed | Unchanged since re-review 2. |
| CI and setup F-01 to F-03, N-05 | Medium, Low | Closed | Unchanged since re-review 2. |
| CI and setup N-06 | Low | Accepted as designed | Unchanged. |
| CI and setup F-04 Git Bash paths (backlog 0000204) | Medium | Accepted deferral | Recorded as the P5 Decision line in `build-log.md`. Not retested. |

## New findings

| ID | Severity | File:line | Finding | Fix |
|---|---|---|---|---|
| N-09 | Medium | `planifest-framework/skills/planifest-ship-agent/SKILL.md:425` and `planifest-framework/standards/autonomous-run-standards.md:121` (step 4) | A held-back file that git already tracks reaches a commit. In a fix attempt, `git diff --name-only` lists a modified tracked `src/app.js` that holds a key. The scan exited 1 on it. `git restore --staged -- src/app.js` exited 0 but did nothing, because the file was a working-tree change. The index rescan then exited 0. The text says to commit with "explicit paths after `--`" and does not say to drop the held-back path from that list. `git commit -- src/app.js src/b.js` then committed the key (`git show HEAD:src/app.js` matched). Committing `src/b.js` alone left the key out. The same applies to a tracked `docs/` or `plan/` file in the P8, 10b and 10c commits. A path-mode rescan (`-- {paths}`) also exits 1 forever, because it reads the working tree, and step 3 does not say which mode to rescan in. | In step 4 of Scan-then-commit, say: build the commit's `--` list from the paths the scan did not name, and never from the original list. Say the rescan is the index scan with no arguments. For a tracked held-back file, add `git update-index --assume-unchanged` or say to leave it modified and out of the list. Add a fixture test with a tracked modified file that asserts `git show HEAD:{path}` stays clean. |
| N-10 | Low | `planifest-framework/skills/planifest-ship-agent/SKILL.md:206` | The P8 guard says to run `git restore --staged -- {path}` for each refused path. For an untracked, unstaged file this exits 1 with `did not match any file(s) known to git`. The run is not harmed, but a shell with `set -e` stops. | Say to skip the restore when the path is not in the index (`git ls-files --error-unmatch`). Fold into the N-09 fix. |
| N-11 | Low | `planifest-framework/scripts/credential-scan.mjs` (path printer) | Filed as backlog 0000222. Non-ASCII and colon paths print with `?`, so `git restore --staged` can fail to match and the repeat step has no cap. Fails closed. | See `plan/backlog/0000222-scan-output-path-glob-chars-stall-unstage/entry.md`. |

## The new test

`bash planifest-framework/tests/test-0000037-req-003-archive-held-back.sh` passes 33 of 33. It runs the real archive script and asserts the scan names the archive path, the commit omits the key, and no commit in the history holds it. It tests what it claims for N-07 and N-08, with two weaknesses:

- The marker-step unstage at the end is a hard-coded path, not one parsed from the scan output.
- It covers no tracked modified file, no repository without a commit, and no exit 2, so it cannot catch N-09.

## Backlog filed

- 0000222 `scan-output-path-glob-chars-stall-unstage` (Low, N-11).

## Fix order

1. Fix N-09 and N-10 together in step 4 and step 3 of Scan-then-commit, and in `SKILL.md` Step 10c and the P8 guard.
2. Add the tracked-file fixture test.
3. Re-review Scan-then-commit and Step 10c only.
