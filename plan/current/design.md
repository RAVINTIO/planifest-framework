# Design - 0000038-token-efficiency-windows-shard

## Feature
- Problem: Claude Code sessions in this repo spend 78.4% of estimated cost on context, and a flaky Windows timing check failed PR #64.
- Adoption mode: standard-iterative (signal: `plan/_archive/` and `docs/about.md` exist)
- Feature ID: 0000038-token-efficiency-windows-shard
- Discovery: see `plan/current/discovery.md` (raw P0 findings; do not embed them here; this document records confirmed decisions only)

## Product Layer
- User stories:
  - US-001: As the human on the loop, I see CI fail only when a hook is slow, so that a red check means a real fault
  - US-002: As the human on the loop, I see subagents run on the tier the framework names, so that cheap work stops running on Opus
  - US-003: As an agent running the suite, I get only failures and totals, so that each run adds little context
  - US-004: As an agent past P0, I don't carry the P0 and Adoption Modes text, so that each request carries less context
  - US-005: As the human on the loop, I get a reset prompt after each passed gate, so that long sessions stop growing
  - US-006: As an agent, I dispatch a subagent only for work that needs its own reads, so that small units don't pay a fresh context
  - US-007: As an agent, I search or read a section of a file over about 20 KB, so that one read doesn't add 75 KB
- Acceptance criteria confirmed: 21 (three per story, set at P1)
- Constraints:
  - No quality gate weakens. Every hook, critic, security review, cross-model review, TDD loop, and test assertion stays. A change that would soften a gate drops out.
  - US-001 keeps the 200 ms limit and never retries. Each timed check makes one untimed warm-up call, then one timed call that must finish under 200 ms.
  - US-002 uses only `sonnet`, `opus`, `haiku`, or `fable`, the values the Claude Code Agent tool accepts. The tier for each task type doesn't change. A new test fails on any other value in the Claude Code column, the dispatch skeleton, or a skill's `model:` line.
  - US-003 adds a quiet mode to `run-tests.sh`. It prints only FAIL lines, the failed-suite list, and the totals. A suite that exits non-zero with no FAIL line still appears in the failed-suite list, and the run still exits non-zero. Full output stays the default, so CI output doesn't change. On a failure, the skills rerun only the failing suite in full.
  - US-004 moves Phase 0 and Adoption Modes, word for word, into reference files that the orchestrator loads at P0. The Framework Index lists them. Resume Detection loads them again when a resumed run is still at P0. Each test assertion that greps the moved text points to the new file. A new test checks that the moved text no longer sits in `SKILL.md`, so no grep passes on the wrong file.
  - US-005 stays advisory and never blocks a phase. The blocking reset after P9 (0000032 ADR-003) doesn't change. The prompt names `plan/current/` and the build log as the resume state, and works when no `pause.md` exists.
  - US-006 keeps the parallel critics and the Scope Lock drafts as they are.
- Integrations: the Claude Code Agent tool `model` parameter

## Architecture Layer
- Latency target: every timed hook call stays under 200 ms after one untimed warm-up call
- Availability target: not applicable (local tooling)
- Scalability target: not applicable
- Security: no auth change. Data classification: repository text.
- Data privacy: no regulated data
- Observability: the 0000230 measures. A one-week re-run after release compares context tokens per request, subagent and Opus share of cost, Bash bytes per call, and cost per request with the baseline.
- Cost boundary: aim for the 0000230 estimate of 19.9% to 26.1% saving from US-002 alone

## Engineering Layer
- Stack: unchanged. Bash, PowerShell, Node ES module hooks and scripts, Markdown, GitHub Actions. Build target: local.
- Components:
  - `planifest-framework`: orchestrator, ship, refactor, validate, and codegen skills, the agent dispatch standard, `templates/standard-boot.md`, `tests/run-tests.sh`, and the test suites
  - Outside the component: `planifest-overrides/instructions/custom-002-prefer-subagent-decomposition.md`
- Data ownership: `planifest-framework` owns `plan/current/`.
- Deployment: framework files ship through `setup.sh` and `setup.ps1`. The release needs a re-run-setup migration, because skills and the boot template change.
- API versioning: not applicable

## Scope
- In:
  - US-001: the three timed suites (`test-0000032-req-003`, `req-007`, and `req-009`) and their regression copies
  - US-002 to US-007: backlog 0000230 changes 1 to 6
  - a re-run-setup migration
  - deleting backlog 0000230 at the design commit, because this feature pulls it in
- Out:
  - raising or removing any timing limit
  - changes to CI output
  - any gate, critic, or review removal
- Deferred: the one-week usage re-run. It needs a week of sessions after release, so it runs outside this pipeline.
- Release size: three-story rule, overridden by the human on the loop (seven stories in one run)

## Assumptions
- The Claude Code Agent tool honours `model: "sonnet"` and `model: "haiku"` - impact if wrong: US-002 saves nothing, and the re-run shows Opus still carrying subagent cost.
- PR #64 Windows shard 1 failed once at 203 ms, 1/1 usable sample, most likely on a cold call - impact if wrong: if warm calls also pass 200 ms, the check stays red, and the hook needs a speed fix under P4.
- The 0000230 profile covers one week and 6,430 requests, and this run can't re-read it - impact if wrong: the savings estimate moves.

## Risks
- US-004 breaks a test grep on moved text. Likelihood: high. Impact: medium. Mitigation: P3 moves each assertion with its text and runs the full suite.
- Quiet mode hides a failure. Likelihood: low. Impact: high. Mitigation: a test feeds a failing suite through quiet mode and checks that the FAIL line and the totals print.
- Seven stories overrun one session. Likelihood: medium. Impact: medium. Mitigation: US-005 gate resets and `pause.md`.
- The warm-up hides cold-start cost that real sessions pay. Likelihood: medium. Impact: low. Mitigation: the hook still runs as a fresh Node process on every timed call. Only disk caches warm.
- US-002 can't prove inside the run that a subagent ran on its tier. Likelihood: medium. Impact: medium. Mitigation: P4 dispatches one `haiku` subagent and checks the model it reports. The one-week re-run confirms the cost shift.

## Dependencies
- Upstream: Claude Code Agent tool `model` values
- Downstream: every repo that installs the framework through `setup.sh` or `setup.ps1`

## Active Skills
None

## Skill Map
| Requirement | Best-fit Skill | Rationale |
|-------------|----------------|-----------|
| REQ-001 - stable-windows-timing | planifest-codegen-agent | test helper change with a TDD cycle |
| REQ-002 - model-tiers-take-effect | planifest-codegen-agent | standard and skill edits with a new values test |
| REQ-003 - quiet-test-output | planifest-codegen-agent | runner flag plus skill edits |
| REQ-004 - phase-scoped-orchestrator | planifest-codegen-agent | word-for-word move with test greps moved |
| REQ-005 - context-reset-at-gates | planifest-codegen-agent | one skill section edit |
| REQ-006 - decomposition-size-floor | planifest-codegen-agent | instruction and standard edit |
| REQ-007 - partial-reads | planifest-codegen-agent | boot template edit |

## Repo Instructions
Five files in `planifest-overrides/instructions/`:
- `custom-001-local-git-only.md`: fetch, pull, push, and `gh pr create` without asking. Work on a `feat/` branch with no worktrees. Committing to `main` and merging PRs are human-only. Commit after every meaningful artifact write.
- `custom-002-prefer-subagent-decomposition.md`: split long or multi-unit work into parallel subagents by default, or state why it can't be split. US-006 changes this file.
- `custom-003-git-up-to-date-shorthand.md`: GUTD means check `git status`, check out `main`, pull, report untracked files, and report the last merged PR's checks.
- `custom-004-file-backlog-entries-immediately.md`: file an out-of-scope problem as a backlog entry at once, commit it, push it, and report its ID.
- `custom-005-p9-push-and-raise-pr.md`: at P9, push the branch and tag, and run `gh pr create` without asking. Never merge, and never push to `main`.

## Version
- Last known version: 0.35.0 (`product.yml`, `docs/about.md`, and `planifest-framework/component.yml`)
- Suggested version: 0.36.0 (Feature Pipeline, minor bump)

## Confirmation
Human confirmed this design before proceeding: no // Date and Time confirmed: pending
