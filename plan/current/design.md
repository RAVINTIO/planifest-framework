# Design - 0000037-green-ci-before-ship

## Feature
- Problem: PR #62 merged with a failing CI check that no agent reported, and the suites miss defects on Linux and Windows that macOS hides.
- Adoption mode: standard-iterative (signal: `plan/_archive/` holds 36 feature folders and `docs/about.md` exists)
- Feature ID: 0000037-green-ci-before-ship
- Discovery: see `plan/current/discovery.md` (raw P0 findings; do not embed them here; this document records confirmed decisions only)

## Product Layer
- User stories:
  - US-001: As the human on the loop, I see the PR's CI result in the P9 report, so that a red PR never looks done. (0000191)
  - US-002: As the human on the loop, I see the CI result of the last merged PR when I send GUTD, so that a red `main` never looks healthy. (0000191)
  - US-003: As the human on the loop, I know that an `autonomous` run scans staged files before each commit and push, so that a credential never reaches the remote. (0000192)
  - US-004: As the human on the loop, I know that the PR body cites paths and never raw output, so that the PR text leaks nothing. (0000192)
  - US-005: As the human on the loop, I see the P4 checks rerun after the P6 docs edits, so that a docs change can't break a green check before ship. (0000086)
  - US-006: As the human on the loop, I see each acceptance criterion name its test type at P1, and P3 run the requirement-ID scan before it closes, so that untested requirements surface before P4. (0000100)
  - US-007: As a framework maintainer, I run a test that executes the hook command string `setup.sh` writes, so that a broken wiring fails the suite. (0000071)
  - US-008: As a framework maintainer, I run a test that compares a re-run-setup migration's file list with the release diff, so that a wrong list fails the suite. (0000186)
  - US-009: As a framework maintainer, I run any suite from any working directory, and a lint flags unportable tool use, so that a GNU and BSD difference fails locally before CI. (0000089, 0000191)
  - US-010: As a framework maintainer, I see the suite run on Windows under Git Bash, so that Git Bash defects fail in CI. (0000093)
  - US-011: As a framework maintainer, I see `setup.ps1` run under Windows PowerShell 5.1, and the stale clean-up and retired-flag paths run live under PowerShell, so that Windows defects fail in CI. (0000092, 0000094)
- Acceptance criteria confirmed: 11 (one per brief criterion. P1 expands each story to up to 3.)
- Constraints:
  - CI keeps the `pull_request` trigger only (0000031-ADR-003). GUTD reads the checks of the last merged PR through `gh pr list --state merged --base main --limit 1` and `gh pr checks`, not a `main` run.
  - New CI jobs stay in this repository's workflow (0000031-ADR-002). Each keeps `permissions: contents: read`, no secrets, and `timeout-minutes: 10`.
  - The agent never merges and never pushes to `main`.
  - Windows PowerShell 5.1 becomes a supported runtime for `setup.ps1`. A new ADR amends 0000031-ADR-001.
- Integrations: GitHub through `gh` (read only for checks), `gitleaks` (optional, local)

## Architecture Layer
- Latency target: P9 waits at most 20 minutes for checks, then reports them as pending
- Red-check handling (confirmed at P0): P9 writes the PR number to the build log before it waits. On a failing check, P9 fixes it on the feature branch and pushes again, up to 3 attempts, then raises an exception-list item. A `cancelled` or timed-out check reads as unknown, never as a pass. A status that can't be read is reported, and the run doesn't read as done.
- Availability target: not applicable (local tooling)
- Scalability target: not applicable
- Security: no auth change. The credential scan covers staged files and the PR body. Data classification: repository text, with credentials treated as secret.
- Data privacy: no regulated data
- Observability: each check writes one build-log line (`CI checks (P9): ...`, `Credential scan (P{N}): ...`, `Revalidation (P6): ...`)
- Cost boundary: CI minutes for three new Windows legs, each capped at 10 minutes

## Engineering Layer
- Stack: unchanged. Bash, PowerShell, Node ES module hooks and scripts, Markdown, GitHub Actions. Build target: local.
- Components:
  - `planifest-framework`: ship, orchestrator, docs, spec, codegen, and validate skills, the autonomous run standard, templates, a new credential-scan script, a new portability lint, and the test suites
  - `setup-hook-integration`: `setup.ps1` under 5.1, and the code under test for the wired-command and live PowerShell tests
  - Outside both components: `.github/workflows/planifest.yml` and `planifest-overrides/instructions/custom-003-git-up-to-date-shorthand.md`
- Data ownership: `planifest-framework` owns `plan/current/build-log.md`. GitHub PR and check state is read only.
- Deployment: framework files ship through `setup.sh` and `setup.ps1`. The release needs a re-run-setup migration, because skills and scripts change.
- API versioning: not applicable

## Scope
- In:
  - P9 CI check after `gh pr create`, with a fix-and-push loop on the feature branch
  - GUTD CI check of the last merged PR
  - Pre-commit credential scan in `autonomous`, holding back the push on a match
  - PR body scan before `gh pr create`, and a rule that PR text cites paths only
  - Post-P6 revalidation, with an optional product-declared doc-check command in `planifest-overrides/`
  - "Verified by" field in the requirement template, and a P3 requirement-ID scan
  - Wired-command test and migration branch-diff test
  - Working-directory independence for every suite, and a portability lint in the suite
  - Windows Git Bash suite leg, Windows PowerShell 5.1 setup leg, and the live PowerShell clean-up test
- Out:
  - A `push` trigger on `main`
  - Any merge by the agent
  - Changes to the consumer workflow at `planifest-framework/hooks/planifest.yml`
- Deferred: nothing deferred
- Release size: three-story rule. 11 stories from 10 backlog entries, confirmed by the human on the loop as one run, above the rule.

## Assumptions
- `gh` is signed in where P9 and GUTD run - impact if wrong: the check reports "CI status could not be read", and the run doesn't read as done (per the red-check handling above).
- `gitleaks` may be absent - impact if wrong: none, since the regex patterns still run, but recall is lower.
- Windows runners have Git Bash and Windows PowerShell 5.1 preinstalled - impact if wrong: the new legs need an install step.
- `gh run list --branch main`, conclusion of the latest `main` run: 0/10 usable (0%) - impact if wrong: none, because the design reads the last merged PR's checks instead.
- `gh run list`, conclusion of `pull_request` runs: 10/10 usable (100%) - impact if wrong: the P9 and GUTD checks would find no result to report.
- `.github/workflows/planifest.yml` trigger: `pull_request` only, 1/1 usable - impact if wrong: a future `push` trigger makes the merged-PR lookup redundant but not wrong.

## Risks
- The Git Bash leg fails many suites on first run (likelihood high, impact medium). Mitigation: fix or skip each suite with a recorded reason, per 0000093.
- Windows PowerShell 5.1 differs from PowerShell 7 in encoding and JSON handling (likelihood medium, impact medium). Mitigation: guard each difference in `setup.ps1` and test it.
- The credential scan flags false positives and stops an `autonomous` run (likelihood medium, impact low). Mitigation: a stop names the file and line, and the human on the loop clears it.
- `gh pr checks --watch` waits on a slow or queued runner (likelihood medium, impact low). Mitigation: a 20-minute cap, then report checks as pending.
- Eleven stories in one run stretch P3 and P4 (likelihood medium, impact medium). Mitigation: parallel streams split by file ownership.

## Dependencies
- Upstream: GitHub Actions runners, `gh` CLI, optional `gitleaks`
- Downstream: projects that install the framework get the new skills and scripts through a re-run-setup migration

## Active Skills
None

## Skill Map
| Requirement | Best-fit Skill | Rationale |
|-------------|----------------|-----------|
| REQ-001 - p9-ci-check | planifest-ship-agent | The change lives in the ship skill's Step 10 |
| REQ-002 - gutd-ci-check | planifest-codegen-agent | Edits the GUTD override instruction |
| REQ-003 - pre-commit-credential-scan | planifest-codegen-agent | New script plus a rule in the autonomous run standard, built through TDD |
| REQ-004 - pr-body-scan | planifest-ship-agent | Runs before `gh pr create` in the ship skill |
| REQ-005 - post-p6-revalidation | planifest-docs-agent | The docs agent owns the step after its edits |
| REQ-006 - verified-by-and-p3-scan | planifest-spec-agent | Template field for P1, with a codegen scan at P3 |
| REQ-007 - wired-command-test | planifest-test-writer | A test-only change |
| REQ-008 - migration-branch-diff-test | planifest-test-writer | A test-only change |
| REQ-009 - portable-suites-and-lint | planifest-codegen-agent | Suite fixes plus a new lint, built through TDD |
| REQ-010 - windows-git-bash-leg | planifest-validate-agent | CI workflow change verified by a real CI run |
| REQ-011 - windows-powershell-coverage | planifest-validate-agent | CI leg and `test_setup.ps1` change verified by a real CI run |

## Repo Instructions
Five files in `planifest-overrides/instructions/`:
- `custom-001-local-git-only.md`: fetch, pull, push, and `gh pr create` without asking. Work on a `feat/` branch with no worktrees. Committing to `main` and merging PRs are human-only. Commit after every meaningful artifact write.
- `custom-002-prefer-subagent-decomposition.md`: split long or multi-unit work into parallel subagents by default, or state why it can't be split.
- `custom-003-git-up-to-date-shorthand.md`: GUTD means check `git status`, check out `main`, pull, and report untracked files. This feature adds a CI check to it.
- `custom-004-file-backlog-entries-immediately.md`: file an out-of-scope problem as a backlog entry at once, commit it, push it, and report its ID.
- `custom-005-p9-push-and-raise-pr.md`: at P9, push the branch and tag, and run `gh pr create` without asking. Never merge, and never push to `main`.

## Version
- Last known version: 0.34.0 (`product.yml` and `docs/about.md`). `planifest-framework/component.yml` reads 0.34.1.
- Suggested version: 0.35.0 (Feature Pipeline, minor bump)

## Confirmation
Human confirmed this design before proceeding: yes // Date and Time confirmed: 24 Oct 2026 @ 12:46 AM BST
