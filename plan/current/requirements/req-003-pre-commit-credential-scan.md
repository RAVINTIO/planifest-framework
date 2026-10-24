---
title: "Requirement: req-003 - pre-commit-credential-scan"
summary: "An autonomous run scans staged files for credentials before each commit and holds back the push on a match."
status: "draft"
version: "0.1.0"
---
# Requirement: req-003 - pre-commit-credential-scan

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000037-green-ci-before-ship
**Source:** US-003
**Priority:** must-have

## User Story

As the human on the loop, I know that an `autonomous` run scans staged files before each commit and push, so that a credential never reaches the remote.

## Functional Requirements

- A new script, `planifest-framework/scripts/credential-scan.mjs`, scans the staged files. The script detects and reports. It does not stop a commit.
- The script scans two sources for every path in the commit. It reads the index blob with `git show :{path}` and the working-tree file. The paths come from `git diff --cached --name-only` plus any path named after `--` in the commit command. The framework's commit form `git commit -m ... -- {path}` commits the working-tree content and ignores the index, so a scan of the index alone would miss a change made after `git add`. A match in either source counts as a match.
- The script applies the P8 guard rules: the refused file names (`.env*`, `*.pem`, `*.key`, `id_rsa*`, `*.p12`, `.npmrc`, `credentials.json`, `*.keystore`, `.netrc`) and the content regex from the P8 credential guard in the ship skill.
- If `gitleaks` is on PATH, the script also runs it over each staged file. If `gitleaks` is absent, the regex alone runs and the script prints `scan mode: regex only (gitleaks not found)`. Otherwise it prints `scan mode: regex and gitleaks`.
- Exit codes: `0` for clean, `1` for at least one match, `2` if the scan could not run. Exit `2` counts as a match, so the commit stops.
- On a match, the script prints one `{path}:{line}` entry per hit and the rule name. It never prints the matched text.
- **Who enforces the stop:** the skill rule enforces it, not a script or a git hook. The script only sets the exit code. A new standing rule in `planifest-framework/standards/autonomous-run-standards.md` orders every `autonomous` commit to run the script first and to stop on exit `1` or `2`. The rule text states that the script scans both the index blob and the working-tree file for every path in the commit. Orchestrator Hard Limit 7 points to that rule. This feature adds no git hook.
- On a match in `autonomous`, the agent commits no held-back file and pushes none. A held-back file that is staged as a new file leaves the index, through `git --literal-pathspecs restore --staged -- {path}`. A tracked held-back file stays out of the commit list and needs no unstage. The agent edits nothing to hide the match.
- A `--safe-paths {out-file}` mode in the script decides each P7 to P9 commit. The script writes the paths with no hit to `{out-file}`, separated by NUL bytes. The agent commits that list with `git --literal-pathspecs commit --pathspec-from-file="{out-file}" --pathspec-file-nul`, behind an empty-list guard. An empty list skips the commit, because git would otherwise commit the whole index. The procedure is `### Scan-then-commit` in `planifest-framework/standards/autonomous-run-standards.md`.
- The agent writes `Credential scan (P{N}): held back {path}` for each held-back path, and `Exception waiting (P{N}, 7): credential sighting in {path}:{line}`. It finishes work that doesn't depend on those files. The final report lists each path and line, never the secret.
- A clean scan writes `Credential scan (P{N}): clean ({scan mode})`. A regex-only scan says so in the line.
- **Clean-tree check:** a held-back file is no longer staged, so the P8 and Step 10b clean-tree checks list it as a leftover. The P8 credential guard runs the same script, refuses the file again, and leaves it uncommitted. The guard reports it by path only.
- **Resume detection:** a resumed run does not treat a held-back file as new work. It does not commit it or push it. It reruns the scan before any commit. A file that now scans clean (the human on the loop removed the secret) commits in the normal way. Orchestrator Resume Detection says so.
- The P8 credential guard and the Step 10b guard in the ship skill call the script in place of their own inline `grep`, so only one pattern list exists.
- Outside `autonomous`, the script is available and the commit flow is unchanged.

## Acceptance Criteria
- [ ] `credential-scan.mjs` reads the staged index content, applies the P8 file-name and content patterns, adds `gitleaks` when present, says "regex only" when it isn't, exits `0`, `1`, or `2`, and prints path and line without the secret. Verified by: shell test that stages a fixture credential in a temp repository, with and without `gitleaks` on PATH.
  - Verified by: integration - shell test that stages a fixture credential in a temp repository, with and without `gitleaks` on PATH
  - Amended (P1): the script scans the index blob and the working-tree file for every path in the commit. A fixture credential added after `git add` and committed with `-- {path}` exits `1`.
- [ ] The autonomous run standard orders the script before every `autonomous` commit. On a match, no commit and no push happen, the files stay staged, and the build log and final report name path and line with `Exception waiting (P{N}, 7)`. Verified by: shell test over the standards, orchestrator, and ship skill text.
  - Verified by: integration - shell test over the standards, orchestrator, and ship skill text
  - Amended (P5): a held-back file that is staged as new leaves the index, and a tracked held-back file stays out of the commit list. The `--safe-paths` mode decides each P7 to P9 commit, committed with `git --literal-pathspecs commit --pathspec-from-file` behind an empty-list guard. The log line is `Credential scan (P{N}): held back {path}`.
- [ ] A held-back file stays staged and shows in the clean-tree check. The P8 guard refuses it again by path only, and a resumed run rescans it and never commits it while the match stands. Verified by: shell test over the ship skill and orchestrator text, plus verify-by-execution in a temp repository.
  - Verified by: integration - shell test over the ship skill and orchestrator text, plus execution in a temp repository
  - Amended (P5): a held-back file that is staged as new leaves the index and shows in the clean-tree check as a leftover. A tracked held-back file stays out of the commit list. The P8 guard refuses either file again by path only, and a resumed run rescans it and never commits it while the match stands.

## Dependencies
- The P8 credential guard in `planifest-framework/skills/planifest-ship-agent/SKILL.md` (0000033 P5), the source of the patterns.
- Orchestrator Hard Limit 6 (credentials rule) and exception item 7.
- `gitleaks` (optional, local).
- req-004 (reuses the script for the PR body).

## Input Validation

- [ ] Input source: staged file paths from `git diff --cached --name-only`, and staged file content
- [ ] Allowed character pattern: `[A-Za-z0-9\-_./ ]` in printed paths, all other characters replaced with `?` before output
- [ ] Maximum length: 200 characters per printed path, content beyond this limit is truncated
- [ ] Failure behaviour: exit `2` and print `scan could not run: {reason}`, which the caller treats as a match
- [ ] Logging policy: matched content never logged, path and line number only

Split step: not triggered. The requirement holds three criteria, and no fourth is added.
