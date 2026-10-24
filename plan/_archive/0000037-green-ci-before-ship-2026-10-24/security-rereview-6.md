# Security re-review 6: P5 approach 2 iteration 3 for 0000037-green-ci-before-ship

**Reviewer:** fresh-context P5 re-reviewer, REJECT-default
**Diff reviewed:** `git diff HEAD~1..HEAD -- . ':!plan'` (HEAD 3854681)
**Method:** Built throwaway git repositories under `mktemp -d` outside this repository. Ran the real `planifest-framework/scripts/credential-scan.mjs`. Ran the P9 marker block as written. Built a random `ghp_` key at run time and printed none. I report counts of a 24-character key fragment in `git log --all -p`. `gitleaks` is absent here, so the scan used regex only. I did not run PowerShell.

## Overall verdict: APPROVE

N-15 and N-16 are closed. No Critical, High or Medium defect appears in the changed lines. One new Low finding (N-17) concerns the exit status of the guard line. It does not leak a credential.

## Findings

| Finding | Severity | Verdict | Evidence |
|---|---|---|---|
| N-15 empty list commits the whole index | Low | Closed | State rebuilt: untracked markers, an untracked held-back archive file with a key, a tracked staged file with the key. Scan exit 1. The out-file held the markers only, so I truncated it to 0 bytes to model the empty list. The P9 marker block as written made no commit (commit count 1 before and after). Key fragments in `git log --all -p`: 0. The staged key file stayed staged and uncommitted. |
| N-15 `set -e` abort on an empty list | Low | Closed for the block, open as N-17 for the final line | In the P9 marker block the guard is followed by `git ls-files`. Under `bash -e` the block printed `after-step` and exited 0. A failed `[ -s ] &&` list is not an errexit trigger. The guard in mid-script position gave exit 0. |
| N-16 `:`-led name, staged mode | Low | Closed | `:lead.txt` staged with a key: exit 1, not 2. Index holds the key and the working tree is clean: exit 1. A clean `:a.txt`: exit 0. |
| N-16 `:`-led name, `--safe-paths` | Low | Closed | Key in the index only, clean working tree: exit 1 and the safe list holds `ok.txt` only. A clean `:a.txt`: exit 0 and the safe list holds `:a.txt`. |
| N-16 from a subdirectory | Low | Closed | `sub/:in.txt` run from `sub/`: staged mode exit 1. `--safe-paths` exit 1 and the safe list held `../ok.txt` only. The script changes to the repository root before `git show`, so `:./` resolves from the root. |
| N-16 name holding `:./` | Low | Closed | Path `x:./y.txt` with a key: `--safe-paths` exit 1, staged mode exit 1. Key only in the index with a clean working tree: exit 1. The prefix `:./` is added once, so an embedded `:./` is inert. |
| Changed lines, new High or Medium | n/a | None found | The script change swaps `:${rel}` for `:./${rel}` at two sites. The shell text change adds a guard only. The guard can only skip a commit, so it cannot widen what a commit holds. |
| Test suites | n/a | Pass | `test-0000037-req-003-credential-scan.sh`: 161 passed, 0 failed. `test-0000037-req-003-archive-held-back.sh`: 143 passed, 0 failed. |

## New findings

| ID | Severity | File:line | Finding | Fix |
|---|---|---|---|---|
| N-17 | Low | `planifest-framework/skills/planifest-ship-agent/SKILL.md` (P8 commit block, P9 CI record block, P9 final report block) and `planifest-framework/standards/autonomous-run-standards.md` step 6 | When the guard line is the last command of a block and the out-file is empty, the block exits 1 (`bash -e` and plain). Nothing aborts, because errexit ignores a failed `&&` list. A tool that treats a non-zero exit as a failure could read a correct skip as an error. This fails closed and leaks nothing. | Write the line as `if [ -s "{out-file}" ]; then git --literal-pathspecs commit ...; fi`, or append `|| true`. Optional. |

## Other checks

- The script printed no matched text in any run.
- The out-file holds paths only and sat in a `mktemp -d` folder outside this repository.
- I filed no backlog entry. N-17 sits inside this feature's lines and does not block the gate.
