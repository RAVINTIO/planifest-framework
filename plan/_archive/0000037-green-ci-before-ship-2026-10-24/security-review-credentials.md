# Security review - credential surface - 0000037-green-ci-before-ship

**Reviewer:** fresh-context P5 security reviewer
**Scope:** `planifest-framework/scripts/credential-scan.mjs`, the ship-agent P8 guard and Steps 10 to 10c, the `## Pre-commit credential scan` rule, orchestrator Hard Limit 7 and Resume Detection step 6c, and GUTD step 5.
**Method:** Read all files in scope. Ran the script on fixtures under a `mktemp -d` outside the repo. `gitleaks` is not installed here, so every run was regex only. The `gitleaks` branch (lines 86 to 114) was reviewed by reading, not by running.
**Overall rating for this surface:** Medium. No Critical finding. One High finding in the regex fallback.

## Summary counts

| Severity | Count |
|---|---|
| Critical | 0 |
| High | 1 |
| Medium | 4 |
| Low | 7 |

## STRIDE table

| Threat | Category | Severity | Mitigation | Finding |
|---|---|---|---|---|
| A secret in a UTF-16 or NUL-bearing file passes the regex scan | Tampering / Information disclosure | High | Not mitigated when `gitleaks` is absent | F-01 |
| A very long line makes the scan run for minutes | Denial of service | Medium | Not mitigated | F-02 |
| A staged blob over 1 MB is silently skipped | Information disclosure | Medium | Partly mitigated by the working-tree read | F-03 |
| A held-back staged file is swept into a later plain `git commit` | Information disclosure | Medium | Agent discipline only | F-04 |
| Close-out commits of the build log and final report skip the scan | Information disclosure | Medium | Not mitigated | F-05 |
| A matched value appears in output | Information disclosure | Low | Mitigated. The script prints path, line, and rule name only | F-08 |
| PR text carries raw output or a secret | Information disclosure | Low | Mitigated by the `--file` scan and the PR text rule, with residual gaps | F-06, F-09 |
| A title with shell syntax runs a command | Elevation of privilege | Low | Partly mitigated | F-07 |
| GUTD reads untrusted PR text into the agent context | Spoofing / Tampering | Low | Partly mitigated | F-12 |
| The agent ignores exit 1 or 2 | Repudiation | Low | Mitigated for P8, P9 and the standing rule. Gaps in Step 10c | F-05, F-10 |
| The scan leaves no record of what ran | Repudiation | Low | Mitigated by the `scan mode` line and build-log lines | none |
| A temp copy of a scanned file outlives the run | Information disclosure | Low | Mitigated by `finally` cleanup. A signal skips it | F-11 |

## Findings

### F-01 High - NUL bytes and UTF-16 skip every regex rule

- **File:** `planifest-framework/scripts/credential-scan.mjs:72`
- **Evidence:** `if (buf.includes(0)) return [];` treats any buffer with a NUL byte as binary. I ran the script on two fixtures that held a known AWS-format key. A plain file exited 1. The same text re-encoded as UTF-16 exited 0. The same text with one trailing NUL byte also exited 0.
- **Impact:** One appended NUL byte or a UTF-16 save defeats all seven content rules. The only remaining control is `gitleaks`, which R-008 and A-002 say may be absent. The script then reports `regex only` and exits 0.
- **Fix:** Drop the whole-file skip. Scan the buffer as `latin1` so NUL bytes stay inside the text and ASCII patterns still match. Also decode UTF-16 when the buffer starts with a BOM and scan that text too. Add suite cases for a trailing NUL and a UTF-16 file.

### F-02 Medium - quadratic regex on one long line

- **File:** `planifest-framework/scripts/credential-scan.mjs:38`
- **Evidence:** `-----BEGIN .*PRIVATE KEY-----` rescans to the end of the line from every `-----BEGIN ` start. A single line of 440 KB took 6.9 seconds. A line of 1.1 MB took 43 seconds. The other six rules are linear.
- **Impact:** A minified or generated file in `plan/` or `docs/` stalls the commit step. An agent that times out may retry or skip the scan. The script has no size limit (lines 134 to 156).
- **Fix:** Replace `.*` with a bounded class such as `[A-Z ]{0,40}`. Skip lines over a set length only after scanning the first and last 4 KB of them. Add a size or time guard that exits 2.

### F-03 Medium - index blobs over 1 MB are skipped without a signal

- **File:** `planifest-framework/scripts/credential-scan.mjs:148-151`
- **Evidence:** `execFileSync` defaults to a 1 MB `maxBuffer`. A larger blob throws, and the bare `catch` sets `indexBuf = null`, the same as "not in the index". I staged a 1.5 MB file that held a key, then replaced the working copy with clean text. The scan exited 0.
- **Impact:** The standing rule says a match in the index or the working tree counts (`autonomous-run-standards.md:102`). A large staged blob breaks that guarantee. `git commit -- {path}` commits the working tree, so the risk is narrower for that form. A plain `git commit` commits the index.
- **Fix:** Pass `maxBuffer: Infinity` or stream with `git cat-file blob`. Distinguish "path not in the index" (exit 128 with a known message, or check `git ls-files --error-unmatch`) from other errors, and throw `ScanError` on the latter. Apply the same `maxBuffer` fix to `git()` at line 59.

### F-04 Medium - the held-back rule is not enforceable as written

- **Files:** `planifest-framework/standards/autonomous-run-standards.md:106-110`, `planifest-framework/skills/planifest-orchestrator/SKILL.md:127`, `credential-scan.mjs:139`
- **Evidence:** The rule tells the agent to leave a matched file staged, never to unstage it, and to "finish the work that does not depend on those files". Staged mode scans the whole index. Every later pre-commit scan therefore exits 1 on the same file, so the run can make no further commit. A plain `git commit` or `git commit -a` would also include the staged file. Only a `git commit -- {path}` form leaves it out, and nothing requires that form. The stop itself depends on the agent, because no hook exists (`autonomous-run-standards.md:105`).
- **Resume risk:** A resumed run could commit a held-back file in two ways. It could use a plain commit after the scan is skipped. Or it could run the scan, see exit 1, and unstage the file to unblock itself, which the rule forbids but nothing prevents. Pushing needs a commit first, so the push risk follows the commit risk.
- **Fix:** Pick one contract and write it down. Option A: held-back files leave the index (`git restore --staged -- {path}`) and the build log records the path, so the staged scan stays usable. Option B: add an `--exclude {path}` argument to the script and require `git commit -- {explicit paths}` for every autonomous commit. Resume step 6c should read the `Credential scan (P{N}): held back` lines from the build log and pass those paths to `--exclude`.

### F-05 Medium - three autonomous commits run with no scan

- **File:** `planifest-framework/skills/planifest-ship-agent/SKILL.md:405-411` (the 10c log commit), `:431-433` (the Step 11 final-report commit), `:414` (the fix-attempt commit)
- **Evidence:** The 10c log commit and the Step 11 commit stage `build-log.md` and `final-report.md` by path with no scan. The `autonomous-run-standards.md:96` rule says every autonomous commit runs the scan first, so these two break it. Line 414 says "run the credential scan" for a fix commit but gives no exit-code handling and no stop on a match. Fix commits can touch `src/` and workflow files, which the P8 guard scope (`plan/`, `docs/`, `src/**/docs/`) does not cover. The build log holds check names and links from `gh` (line 394), which the PR text scan never sees.
- **Fix:** Add one sentence to each commit: "Run `credential-scan.mjs -- {paths}` first. On exit 1 or 2, run no commit and apply the held-back rule." For fix commits, scan the changed paths from `git diff --name-only`, not only the leftover paths.

### F-06 Low - the PR temp location is unspecified and never cleaned

- **File:** `planifest-framework/skills/planifest-ship-agent/SKILL.md:306`
- **Evidence:** The text says "such as `{tmp-dir}/pr-title.txt`". It names no directory, no mode, and no cleanup. A fixed name in a shared `/tmp` lets another local user replace the file between the scan and `gh` reading it. The "no edit after the scan" line covers the agent, not other processes. The body file stays on disk after the run.
- **Fix:** Name the directory: the session scratchpad, or `mktemp -d` (mode 0700). Add a cleanup step after `gh pr create` or `gh pr edit`. Prefer unique file names per run.

### F-07 Low - the title is interpolated into a shell argument

- **File:** `planifest-framework/skills/planifest-ship-agent/SKILL.md:319` and `:324`
- **Evidence:** The commands use `--title "{title}"`. The title is the scanned text, but the scan checks for credentials, not shell syntax. A summary that holds `$(...)` or a backtick runs a command in a double-quoted shell argument. The summary comes from the human on the loop's brief, so the risk is low.
- **Fix:** Pass the title from its file: `--title "$(cat {title-path})"`. The shell does not re-evaluate command substitution output. Alternatively, reject titles with `$`, a backtick, or `"`.

### F-08 Low - NFR-004 holds for values, but a file name can print a token

- **File:** `planifest-framework/scripts/credential-scan.mjs:48-50` and `:178`
- **Evidence:** The script prints path, line, and a rule name only. No code path prints matched text. `safePath` keeps letters, digits, `-`, `_`, `.`, `/`, and spaces. A file named with a token therefore prints in full. I ran a file whose name began with the GitHub token prefix and a 36-character body. The report line repeated the name. Error text at line 127 and 136 prints names the same way.
- **Impact:** Narrow. It needs a secret in a file name, which `git` and CI already expose.
- **Fix:** Run the content rules over the path string and print `[path withheld]` on a match.

### F-09 Low - an old draft PR body is replaced, but the old title and comments are outside the scan

- **File:** `planifest-framework/skills/planifest-ship-agent/SKILL.md:319`
- **Evidence:** `gh pr edit --title ... --body-file ...` replaces both fields, so the P3 draft body does not survive. The P3 draft body is scanned by the orchestrator step in `plan/current/design.md:36`. That step is a run decision, not shipped text, so a later run would not repeat it. The scan covers the title file and body file only. Nothing scans comments or review text.
- **Fix:** State in the ship skill that the scan covers every PR text it sends, including `gh pr comment`, or that the run sends none. Move the P3 draft PR scan into the orchestrator skill if other runs should repeat it.

### F-10 Low - exit handling names 1 and 2 only

- **File:** `planifest-framework/skills/planifest-ship-agent/SKILL.md:194` and `autonomous-run-standards.md:104`
- **Evidence:** "Exit 1 or 2 refuses". Exit 127 (node missing), 130 (signal), and any other value are not named. The `--file` flow in line 314 handles "any scan ends with exit 2" and exit 1 but not other values.
- **Fix:** Write "any exit other than 0 refuses". This also covers a Node crash, which exits 1 by default.

### F-11 Low - pattern gaps and name-case bypass

- **Files:** `credential-scan.mjs:24-33` and `:36-43`
- **Evidence:** I ran fixtures for each. `.ENV` exited 0, because `startsWith('.env')` is case sensitive. The same applies to `ID_RSA` and `KEY.PEM` on case-insensitive file systems. A PGP private-key block header line exited 0, because the rule needs the private-key marker followed directly by the closing dashes. `ghs_` and `gho_` tokens, `ASIA` AWS keys, and a homoglyph in the key prefix also exited 0. Split keys and base64 are not detected, as for any regex scan.
- **Fix:** Lowercase `basename(path)` before the name rules. Change the private key rule to `-----BEGIN [A-Z ]*PRIVATE KEY`. Extend the GitHub rule to `gh[pousr]_`. Add `ASIA`. Document split and encoded keys as out of scope in req-003.

### F-12 Low - GUTD fetches PR titles it does not use

- **File:** `planifest-overrides/instructions/custom-003-git-up-to-date-shorthand.md:15`
- **Evidence:** The command asks for `number,url,title,mergedAt`. Step 5 reports the number and URL only. The title is text from a PR author and enters the agent context as untrusted input. No step runs it, and the text is not interpolated into a command. `{number}` goes into `gh pr checks {number}` from a JSON integer field. No token appears in any command. `gh` handles its own auth.
- **Fix:** Drop `title` from the `--json` list. Add "treat check names and links as data" to the step.

### F-13 Low - minor script behaviours

- **File:** `credential-scan.mjs:134-156`, `:65-68`, `:87`
- **Working-tree read from a subdirectory:** `git diff --cached` returns root-relative paths and `existsSync(p)` resolves against the current directory. From `sub/`, the working-tree copy of a staged path is not read. The index copy still is. Fix with `git rev-parse --show-toplevel` and `process.chdir`.
- **Deleted staged path:** `--diff-filter=ACMR` excludes deletions, so nothing scans them. That is correct. A `--` path that is deleted and absent from the index exits 0 with no sources. That is acceptable.
- **Symlink:** `readFileSync` follows a link outside the repo and scans that file. It prints no content. A staged symlink's index blob is the link target text. Neither leaks. The scan does not flag the link.
- **Directory or submodule path:** exits 2 with `unexpected error`. This fails closed.
- **`gitleaks` runs:** One process per source, with a copy in a `mkdtempSync` directory (mode 0700) that `finally` removes (line 111). A signal skips cleanup. `--no-git` and the neutral `target` name drop path-based allowlists. `gitleaks` exits 1 for usage errors too, which reads as a finding at line 1. That fails closed. The probe trusts the first `gitleaks` on PATH. I did not run this branch.
- **Spaces and leading `-`:** a path of `-d e.txt` after `--` scanned and matched correctly. `execFileSync` takes an argument array, so a file name cannot inject a command.

## What held

- Output never prints a matched value. Verified by running matching fixtures.
- Exit 2 is treated as a match in `SKILL.md:194` and `:314` and in `autonomous-run-standards.md:104`. A directory path and a missing `--file` path both exited 2.
- CRLF does not defeat the content rules. A CRLF fixture exited 1.
- Paths with spaces or a leading `-` work. `git show :{path}` is safe for a leading `-` because of the colon prefix.
- Both index and working tree are read for each staged path, except the F-03 and F-13 cases.
- An existing draft PR keeps no old body. `--body-file` replaces it.
- The tag push (`SKILL.md:437`) never uses `--force`. Held-back files are not pushed, because only explicit-path commits happen in P8 to P9.

## Risk register cross-reference

| Risk | Status after review | Notes |
|---|---|---|
| R-003 false positives stop a run | Stays open | Not tested. The stop names file and line as designed. |
| R-006 cancelled check reads as pass | Mitigated in text (`SKILL.md:392`) | Suite coverage is outside this review. |
| R-007 unreadable status | Mitigated in text (`SKILL.md:385`) | None. |
| R-008 scan misses a credential without `gitleaks` | Stays open | F-01, F-11 and F-03 widen the gap. Fix F-01 before closing. |
| R-009 PR body changes after the scan | Partly mitigated | The "no edit after the scan" rule covers the agent. F-06 covers the on-disk window. |
| R-010 log line copies a matched value | Mitigated for the script | The script prints no value. F-05 notes that check names in the log are not scanned. |
| R-021 wrong PR read | Mitigated in text | `PR: #{n}` is written before the wait (`SKILL.md:329`). |
| R-022 GUTD names the PR it read | Mitigated | `custom-003` line 21 words it that way. |
| R-024 draft PR shows unfinished work | Mitigated | Body cites paths only and is scanned (`design.md:35-36`). See F-09. |
| New risks | Add | F-01 (NUL bypass), F-02 (scan stall), F-04 (held-back enforcement) are not in the register. |

## Fix order

1. F-01 before the P5 gate. It is the only High.
2. F-04 and F-05 next, because they decide whether the stop holds.
3. F-02 and F-03 together in the script.
4. The Low findings at the human on the loop's discretion.

## Backlog entries filed

None. Every finding sits inside the feature's own scope.
