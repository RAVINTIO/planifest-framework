# Design - 0000032-governance-continuity-and-write-gate-scope

## Feature
- Problem: Planifest stops governing a session at P7, requests after P9 skip triage, shell writes bypass the design gate, and `gate-write` blocks paths outside the repository with no visible reason.
- Adoption mode: standard-iterative
- Version: 0.31.0
- Feature ID: 0000032-governance-continuity-and-write-gate-scope
- Discovery: see `plan/current/discovery.md`
- Source: backlog 0000077 and 0000084, folded into `plan/current/feature-brief.md`

## Product Layer
- User stories (split at P2 from the four confirmed stories, so each has at most 3 criteria):
  - US-001 (req-001): As the human on the loop, I want the ship skill to delete the session markers in P9 before the tag, so that hooks treat P8 and P9 as part of the run.
  - US-002 (req-002): As the human on the loop, I want an interrupted close-out to resume from archive evidence, so that P8 and P9 finish as part of the same run.
  - US-003 (req-003): As the human on the loop, I want the auto-trigger hook to say no run is active and to require triage, so that the agent routes every new request into a track.
  - US-004 (req-004): As the human on the loop, I want each next step in a P9 handover note routed through a track, so that no follow-up code change skips the pipeline.
  - US-005 (req-005): As the human on the loop, I want P9 to end with a blocking context clear, so that every new request starts in a fresh session and goes through triage.
  - US-006 (req-006): As an agent, I want `gate-write` to ignore paths outside the repository, so that a write outside the repository never needs a design.
  - US-007 (req-007): As an agent, I want every enforcement hook that blocks to show its reason, so that I can act on a block without reading the hook's source.
  - US-008 (req-008): As the human on the loop, I want the shell guard to catch the common shell writers aimed at gated paths, so that auto mode cannot bypass the design gate through Bash.
  - US-009 (req-009): As the human on the loop, I want the shell guard to gate exactly the paths that **Write** and **Edit** gate, so that the two gates never disagree and read-only commands never block.
  - US-010 (req-010): As the human on the loop, I want both setup scripts to register the shell guard for Claude Code exactly once, so that every install runs the guard and a re-run never duplicates it.
  - US-011 (req-011): As the human on the loop, I want a migration that tells downstream projects to re-run setup, so that they gain the shell guard and the new hook messages.
  - US-012 (req-012): As the human on the loop, I want every boot file to require code changes through **Write** or **Edit**, so that the agent doesn't rely on the shell guard's heuristic.
- Acceptance criteria confirmed: 11 brief criteria (AC-1 to AC-11 in `feature-brief.md`), refined into 36 requirement criteria across 12 requirements
- Constraints:
  - No em dashes in Planifest artifacts. Write "human on the loop".
  - Hooks stay dependency-free Node ES modules that read stdin through `read-stdin.mjs`.
  - Markers stay committed (0000023 req-002). They're deleted and committed after P8 and before the Step 9 tag.
  - Push and PR stay optional per project settings and the human's choice.
- Integrations: Claude Code PreToolUse and UserPromptSubmit hooks. Windsurf and Cursor adapters relay hook stdout.

## Architecture Layer
- Latency target: each changed or new hook completes in under 200 ms per call on the CI runners
- Availability target: not applicable (local hooks). Every hook fails open on unexpected errors.
- Scalability target: not applicable
- Security: no auth. The hooks are local enforcement controls. Data classification: repository paths and shell command strings only, no credentials or PII.
- Data privacy: no regulated data
- Observability: block reasons on stderr, warnings on stderr when the shell guard can't parse a command
- Cost boundary: not constrained

## Engineering Layer
- Stack: JavaScript (Node ES modules) for hooks, Bash and PowerShell for setup, Markdown for skills. Tests are Bash suites under `planifest-framework/tests/`, run by `run-tests.sh` and the 0000031 CI jobs. Build target: local.
- Components: `planifest-framework`, the single component pack holding skills, hooks, templates, migrations, and setup scripts
- Data ownership: `planifest-framework` owns `plan/.orchestrator-active`, `plan/.orchestrator-ack`, and `plan/.run-mode` (written by the orchestrator, deleted by the ship skill). Hooks read them only.
- Deployment: copied into downstream projects by `setup.sh` or `setup.ps1`
- API versioning: not applicable

## Component Paths
- `planifest-framework/`
- `.claude/`
- `.github/`

## Scope
- In:
  - Ship skill: marker deletion before the Step 9 tag, the handover-note rule, and a blocking Step 12
  - Orchestrator skill: Resume Detection step 2a evidence rule, and Context Hygiene to match Step 12
  - `auto-trigger-orchestrator.mjs` message: no run is active, triage first
  - `gate-write.mjs`: pass paths outside the repository root, and stderr block reasons in every hook that exits 2
  - A new Bash PreToolUse shell-write guard sharing one path-rules module with `gate-write.mjs`
  - Setup registration for Claude Code, idempotent, in `setup.sh` and `setup.ps1`
  - A 0.31.0 migration telling downstream projects to re-run setup
  - Boot-file statement that code changes go through **Write** or **Edit**
  - ADRs superseding 0000015 ADR-001 and ADR-002
- Out:
  - Registering the shell guard for tools other than Claude Code
  - Extending `ratchet-check.mjs` to shell writes
  - Shell writes made by git commands, scripts, or variables the guard can't parse
  - Fast Path writes through `gate-write` (backlog 0000081)
  - Downstream product runbooks that push to `main`
- Deferred: nothing deferred

## Assumptions
- Claude Code shows a PreToolUse block reason from stderr when a hook exits 2. Impact if wrong: AC-7 fixes nothing for Claude Code.
- Claude Code passes the Bash command as `tool_input.command`. Impact if wrong: the shell guard never sees a command and always passes.
- Gitignored session markers aren't needed. Impact if wrong: the sentinel still can't cover the Step 11 confirmation.

## Risks
- The shell guard blocks a legitimate read-only command. Likelihood medium, impact medium. Mitigation: false-positive corpus, fail open with a warning on parse failure.
- The shell guard misses a real write. Likelihood high, impact low. Mitigation: detection corpus, boot-file rule, documented limits.
- Moving the marker deletion changes resume behaviour for runs already in progress downstream. Likelihood low, impact medium. Mitigation: step 2a stops and asks when no matching archive exists.
- Registering a new Bash matcher duplicates entries on repeated setup runs. Likelihood medium, impact low. Mitigation: AC-10 idempotence test.

## Dependencies
- Upstream: 0000031 CI jobs on the same branch run the new and changed suites
- Downstream: backlog 0000081 (Fast Path through gate-write) builds on the shared path-rules module. Backlog 0000096 (multi-release initiative run) depends on the run-lifecycle rules defined here.

## Active Skills
None

## Skill Map
| Requirement | Best-fit Skill | Rationale |
|-------------|----------------|-----------|
| REQ-001 - marker-clear-before-tag | planifest-codegen-agent | Skill-text edit with text-assertion tests |
| REQ-002 - resume-from-archive-evidence | planifest-codegen-agent | Skill-text edit with text-assertion tests |
| REQ-003 - no-run-triage-message | planifest-codegen-agent (test-writer, implementer, refactor) | Hook or setup change through TDD |
| REQ-004 - handover-note-routing | planifest-codegen-agent | Skill-text edit with text-assertion tests |
| REQ-005 - blocking-context-clear | planifest-codegen-agent | Skill-text edit with text-assertion tests |
| REQ-006 - outside-repository-pass | planifest-codegen-agent (test-writer, implementer, refactor) | Hook or setup change through TDD |
| REQ-007 - stderr-block-reasons | planifest-codegen-agent (test-writer, implementer, refactor) | Hook or setup change through TDD |
| REQ-008 - shell-writer-detection | planifest-codegen-agent (test-writer, implementer, refactor) | Hook or setup change through TDD |
| REQ-009 - shell-guard-path-parity | planifest-codegen-agent (test-writer, implementer, refactor) | Hook or setup change through TDD |
| REQ-010 - shell-guard-registration | planifest-codegen-agent (test-writer, implementer, refactor) | Hook or setup change through TDD |
| REQ-011 - rerun-setup-migration | planifest-codegen-agent | Migration document with text-assertion tests |
| REQ-012 - write-or-edit-boot-rule | planifest-codegen-agent | Boot template text with text-assertion tests |

## Repo Instructions
- `custom-001`: The agent may fetch, pull, push, and create pull requests without asking. Work on a `feat/` branch, never in a worktree. Committing to `main` and merging pull requests are human-only.
- `custom-002`: Prefer subagent decomposition for long or multi-unit tasks, and state the reason when a task can't be split.
- `custom-003`: `GUTD` means check out `main`, pull, and report untracked files.

## Confirmation
Human confirmed this design before proceeding: yes // Date and Time confirmed: 17 Oct 2026 @ 12:25 a.m. BST
