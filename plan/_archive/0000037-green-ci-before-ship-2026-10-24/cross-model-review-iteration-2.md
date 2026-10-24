# Cross-model review: 0000037-green-ci-before-ship (end of P6, iteration 2)

**Verdict: APPROVE.** The iteration 1 major finding M-1 is closed. No new critical or major finding exists. Five minor findings remain open or partly open. None of them blocks P7.

## Models

| Role | Model id |
|------|----------|
| Implementing agents | `claude-sonnet-5-5` |
| Cross-model reviewer | `claude-opus-5-5` |

## Scope and method

- Fix diff reviewed: `git diff 990b94a..HEAD`, 19 files, 82 insertions and 46 deletions.
- Feature diff rechecked: `git diff c8b1036..HEAD`, 170 files, 9393 insertions and 278 deletions.
- Rubric: REJECT by default. An item passes only with evidence.
- Requirements: req-001 to req-011 with their `Amended` lines. ADRs: ADR-001 to ADR-014.

## Commands run

| Command | Result |
|---------|--------|
| `bash planifest-framework/tests/run-tests.sh` | Exit 0. Feature suites 109 passed, 0 failed. Regression suite 33 passed, 0 failed. Suites run: 142. |
| `node planifest-framework/scripts/skill-drift-check.mjs` | Exit 0. "21 skills match source for claude-code." |
| `grep` for em dashes in added `.md` lines of the fix diff | 0 hits |
| `grep` for semicolons in added prose outside tables and code | 0 new hits. The hits in orchestrator Hard Limit 7 sit in text that predates this feature. |
| Sentence-length scan of added prose in the fix diff | 2 new sentences of 25 words or more (see n-4). The Hard Limit 7 hits predate this feature. |
| `grep` for stale field lists and held-back wording in `plan/current/`, `docs/`, and shipped files | 4 stale artifact lines (see n-1 to n-3) |

## Iteration 1 finding status

| ID | Status | Evidence |
|----|--------|----------|
| M-1 | Closed | `req-003-pre-commit-credential-scan.md` lines 27 to 32 now state the unstage rule, `--safe-paths`, and `held back {path}`. Lines 42 and 45 add `Amended (P5)` lines under AC 003.2 and AC 003.3. `ADR-003` lines 35 to 43 add an `## Amended (P5)` section. `test-0000037-req-003-credential-scan.sh` lines 497 to 505 act out step 4 and assert `??` and no commit. The block title at line 483 and the assertion name at line 496 still read "stays staged" (see n-5). |
| m-1 | Closed | `req-002` line 21 and its line 39 `Amended (P5)` drop `title`. `ADR-005` lines 33 to 35 add an amendment. `design.md` line 25 adds an `Amended (P5)` line. The glossary still carries `title` (see n-2). |
| m-2 | Partly closed | `planifest-orchestrator/SKILL.md` line 26 now cites `### Scan-then-commit`. It still restates the rule and gets it wrong. See n-3. |
| m-3 | Closed | Each sentence that iteration 1 listed is now split. Examples: `quirks.md` lines 23 and 67, `decisions-index.md` line 6, ship skill lines 258 and 455, and the standard line 127. Two new long sentences arrived with the fix (see n-4). |
| m-4 | Partly closed | Ship skill line 213 now reads "Refused files stay uncommitted, so a refused file stays uncommitted even after the guard runs." The sentence still says one thing twice. |
| m-5 | Closed in shipped text | Ship skill line 336 requests `state`, and line 353 reuses a PR only when `state` is `OPEN`. `test-0000037-req-001-p9-ci-check.sh` lines 57 to 59 assert it. `docs/architecture-overview.md` line 407 matches. `req-001` and `ADR-002` still name the old field list (see n-1). |
| m-6 | Closed | `risk-register.md` lines 20 to 43 now give each risk `open`, `mitigated`, or `accepted`. R-011 line 30 cites ADR-014 and the 20-minute shards. R-008 cites backlog 0000216, which exists. |
| m-7 | Closed | `credential-scan.mjs` line 49 now explains the character class. The text `ASIA[0-9A-Z]{16}` cannot match its own rule, because `[` follows `ASIA`. |

## Findings

### Critical

None.

### Major

None.

### Minor

**n-1. req-001 and ADR-002 still request the old `gh pr view` fields.**

- Files: `plan/current/requirements/req-001-p9-ci-check.md` line 21 and `plan/current/adr/ADR-002-p9-polls-pr-checks-and-fixes-red.md` line 33.
- Evidence: both read `gh pr view --json number,url,isDraft`. The ship skill, line 336, ships `number,url,isDraft,state` and an `OPEN` check. Neither artifact has an amendment for the m-5 fix.
- Fix: add an `Amended (P6)` line under the req-001 bullet and a note in ADR-002. Each states the `state` field and the `OPEN` rule.

**n-2. The domain glossary still describes the replaced rules.**

- File: `plan/current/domain-glossary.md` lines 20 and 28.
- Evidence: line 20 lists `--json number,url,title,mergedAt`. Line 28, "Held-back push", says "The files stay staged."
- Fix: drop `title` from line 20. Rewrite line 28 to say that a held-back file staged as new leaves the index.

**n-3. Hard Limit 7 still contradicts scan-then-commit.**

- File: `planifest-framework/skills/planifest-orchestrator/SKILL.md` line 26.
- Evidence:
  - It says "every commit follows the `### Scan-then-commit` procedure". The standard limits that procedure to P7 to P9.
  - It says "the commit names only that safe list after `--`". Scan-then-commit step 6 passes the list through `--pathspec-from-file` with no `--`.
  - It closes with "Every commit names explicit paths after `--`", which repeats the same claim.
- Fix: replace the last three sentences with one pointer. For example: "In `autonomous`, every commit follows the pre-commit credential scan rule in `planifest-framework/standards/autonomous-run-standards.md`, and P7 to P9 commits follow its `### Scan-then-commit` procedure."

**n-4. The fix added two sentences of 25 words or more.**

- Evidence:
  - `plan/current/build-log.md` line 390, "In shipped text, the held-back fixture acts out ... `OPEN`.", 27 words
  - `plan/current/requirements/req-003-pre-commit-credential-scan.md` line 42, the first `Amended (P5)` sentence, 25 words
- Fix: split each sentence at its conjunction.

**n-5. Two req-003 test names still say "stays staged".**

- Files: `planifest-framework/tests/test-0000037-req-003-credential-scan.sh` lines 461, 483, and 496.
- Evidence:
  - Line 461 asserts the standard holds "stay staged" under the name "standard keeps files staged". The only match is "Clean staged files stay staged", so the name describes a rule that no longer exists.
  - Line 483 titles the block "a held-back file stays staged". Line 496 names its assertion "the held-back file stays staged". Both describe the state before step 4.
- Fix: rename line 461 to "standard keeps clean files staged". Retitle the line 483 block to "a held-back file leaves the index and shows in the clean-tree check". Rename line 496 to "before step 4 the held-back file is staged". Iteration 1 asked for the retitle, and it did not land.

Also, the m-4 residual at ship skill line 213 stays open. Fix it by deleting the clause after the comma.

## Requirement coverage recheck

The fix diff changes no behaviour outside req-001, req-002, and req-003. The coverage table in `plan/current/cross-model-review.md` still holds for req-004 to req-011.

| Req | Met | Evidence |
|-----|-----|----------|
| req-001 | Yes, with drift | Step 10 now checks `state`. The artifact lags the shipped text (n-1). |
| req-002 | Yes | Override, req-002, ADR-005, and `design.md` agree on `number,url,mergedAt`. The glossary lags (n-2). |
| req-003 | Yes | req-003, ADR-003, the standard, and the ship skill agree on scan-then-commit. The test models the unstage. |

## Install and setup

- The build log line 391 records a second `setup.sh claude-code --strict-orchestrator` run after the fixes, with exit 0.
- The drift check passes for all 21 skills.
- `planifest-overrides/setup-config/claude-code.md` records the new `writtenAt` and the same flag.

## Backlog

This review filed no backlog entry. Every finding sits in this feature's scope.

## Pass condition

M-1 was the only blocker, and it is closed. The suite passes, and the installed skills match source. n-1 to n-5 and the m-4 residual can land in one commit before P7. They do not block on their own.
