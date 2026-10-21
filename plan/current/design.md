# Design - 0000035-write-gate-scope-and-path-hardening

## Feature
- Problem: the write gate blocks Fast Path and P9 writes that the framework sanctions, five path tricks get writes past the gates, and migration run state can't differ between the framework repo and a downstream project.
- Adoption mode: standard-iterative (signal: `plan/_archive/` holds prior features, and `docs/about.md` exists)
- Feature ID: 0000035-write-gate-scope-and-path-hardening
- Version: `0.32.0` → `0.33.0` (Feature Pipeline, minor bump). `planifest-framework/component.yml` carries it. `product.yml` is set to match at P7.
- Discovery: see `plan/current/discovery.md` (raw P0 findings; do not embed them here; this document records confirmed decisions only)

## Product Layer
- User stories:
  - US-001: As the human on the loop, I see a Fast Path change written through **Write** and **Edit** against a declared scope record, so that Fast Path never needs a shell workaround or a hand copy. (0000081, 0000125, 0000062)
  - US-002: As the human on the loop, I see `product.yml` name the released version and feature after every run, so that an `explicit` version policy never blocks a correct release. (0000124)
  - US-003: As the human on the loop, I rely on the gates to judge where a write lands after symbolic links resolve, so that a link under `plan/` can't carry a write into `src/`. (0000106, 0000117)
  - US-004: As the human on the loop, I rely on the gates to find the repository root when the working directory no longer exists, so that they never fail open on a write into `src/`. (0000107)
  - US-005: As the human on the loop, I rely on `ratchet-check` to find the active loop from any subfolder, so that a weakening write is blocked wherever the agent runs it. (0000109)
  - US-006: As the human on the loop, I rely on the gates to ignore a `.git` marker planted under an always-permitted name, so that a moved folder can't become a new root. (0000114)
  - US-007: As the human on the loop, I see every migration stay in `planifest-framework/migrations/` with its run state recorded in `plan/_migrations/`, so that the framework repo and each downstream project track their own runs. (0000126)
- Acceptance criteria confirmed: 13 (see `feature-brief.md`)
- Constraints:
  - 0000032 ADR 004: hooks use Node built-ins only, with no process spawn.
  - 0000033 ADR 009: Fast Path never admits an enforcement path.
  - Hard Limit 8: changes go through **Write** or **Edit**.
- Integrations: none

## Decisions confirmed at P0
- Fast Path authorisation: a scope record at `plan/.fast-path-scope` lists the change's target paths. `gate-write` and the shell-write guard accept it in place of `design.md` and match each write against the listed paths. Enforcement paths stay gated whatever the record lists. The Fast Path commit deletes the record.
- `product.yml`: the ship agent updates `version` and `feature` in P7, before Step 6 archives `design.md`, and commits the update with the archive. The gate stays unchanged for root files.
- Migration state: migration files never move. Each project writes one record per migration under `plan/_migrations/`. A migration with no record is pending. The `_done/` folder goes away, and its six files return beside the others.
- Existing migrations: no seeding from `_done/`. In this repo, P3 runs each migration's scan and writes the record from the result. The two downstream-only migrations get `not applicable`. A downstream project runs each scan on first use, and a compliant project gets a clean result and a record.
- Release fill: ten backlog entries in one wave, chosen by the human on the loop over the three-story rule.
- Migration records: a `not applicable` entry counts as a record. The migrator creates `plan/_migrations/` on its first record. A record that can't be read counts as pending. Downstream projects treat the two downstream-only migrations as applicable, and each scan decides.
- Fail-closed line: a link loop, a chain past the hop limit, or any resolution error for a path inside the repo root blocks with exit 2. Only errors outside path resolution still fail open (0000003 ADR 005).
- Scope record life: the record stores the branch and `HEAD` commit it was written at. The gate ignores a record once either one changes. The next Fast Path overwrites a stale record.
- Idempotence: a migration re-run and the P7 `product.yml` update each give the same result when run twice. A stale `product.yml` stays as it is until the next P7 corrects it.
- Run mode: `autonomous`.

## Architecture Layer
- Latency target: each hook call stays under 500 ms on a 10-hop link chain
- Availability target: not applicable (local hooks)
- Scalability target: not applicable
- Security: no auth. The gates are the control under change. Every new block path exits 2 with its reason on stderr. Unexpected errors still exit 0 (0000003 ADR 005). Data classification: repository files only, no regulated data.
- Data privacy: no regulated data
- Observability: standard defaults. Block reasons go to stderr.
- Cost boundary: not constrained

## Engineering Layer
- Stack: JavaScript ES modules on Node built-ins / Bash and PowerShell setup / Markdown skills / no database / no ORM / no IaC / no cloud / no compute / GitHub Actions CI / Build target: local. Stack unchanged.
- Components:
  - `planifest-framework`: hooks, scripts, skills, workflows, templates, migrations, and tests.
  - `setup-hook-integration`: setup integration docs and quirks, touched only if setup behaviour changes.
- Data ownership:
  - `plan/_migrations/` run records: owned by the migrator skill, read by orchestrator resume detection.
  - `plan/.fast-path-scope`: owned by the Fast Path workflow, read by `gate-write` and the shell-write guard.
  - `product.yml`: owned by the ship agent, read by `product-version.mjs`.
- Deployment: framework files ship by copy through `setup.sh` and `setup.ps1`.
- API versioning: not applicable

## Component Paths
- `planifest-framework/`
- `src/setup-hook-integration/`
- `.claude/skills/`
- `.github/workflows/`
- `./product.yml`

## Scope
- In: backlog entries 0000062, 0000081, 0000106, 0000107, 0000109, 0000114, 0000117, 0000124, 0000125, and 0000126. Setting `product.yml` to the current release. A `plan/_migrations/` record for each of the eight existing migrations in this repo.
- Out:
  - Shell-guard parser entries 0000105, 0000108, 0000115, and 0000116. They wait on 0000119.
  - A hook that enforces the post-P9 refusal (0000112).
  - Running the two downstream-only migrations in this repo.
- Deferred: nothing deferred.
- Release size: three-story rule (no `release-budget.yml`). Seven stories in one wave, by the choice of the human on the loop.

## Assumptions
- Claude Code passes `CLAUDE_PROJECT_DIR` to hooks - impact if wrong: the deleted-cwd fix falls back to the nearest existing parent only. 0000118 has not checked this live.
- The scans in the six older migrations still run against today's layout - impact if wrong: a scan reports false findings, and P3 brings them to the human on the loop.
- No existing records: `discovery.md` `## Record Samples` reads None.

## Risks
- Resolving each path segment through links adds file-system calls to every hook call. Likelihood medium, impact low. The latency NFR and the existing length limits bound it.
- A scope record left after an interrupted Fast Path keeps admitting writes to its paths. Likelihood medium, impact medium. The requirement must bound its life, for example by checking it against the branch or a timestamp.
- A downstream project sees six old migrations as pending after refresh. Likelihood high, impact low. Each scan finds nothing on a compliant project.
- Seven stories in one run exceed the three-story rule. Likelihood medium, impact medium. The run uses parallel work by file ownership.

## Dependencies
- Upstream: 0000032 `path-rules.mjs` and the shell-write guard. 0000033 Fast Path admission.
- Downstream: every project that refreshes the framework gets the new migration layout and the Fast Path scope record.

## Active Skills
None

## Skill Map
| Requirement | Best-fit Skill | Rationale |
|-------------|----------------|-----------|
| REQ-001 - fast-path-scope-record | planifest-codegen-agent | Hook logic plus workflow text, built test first |
| REQ-002 - product-yml-in-p7 | planifest-codegen-agent | Ship-skill reorder plus a close-out suite |
| REQ-003 - links-judged-by-real-target | planifest-codegen-agent | `path-rules.mjs` resolution, test first |
| REQ-004 - root-when-cwd-deleted | planifest-codegen-agent | `resolveRoot` change, test first |
| REQ-005 - ratchet-check-shared-root | planifest-codegen-agent | `ratchet-check.mjs` imports the shared rules |
| REQ-006 - no-planted-root-marker | planifest-codegen-agent | `markedRoot` trust rule, test first |
| REQ-007 - migration-run-state | planifest-codegen-agent | Migrator and orchestrator text, file moves, records, suites |

## Repo Instructions
- `custom-001-local-git-only.md`: fetch, pull, push, and `gh pr create` without asking. Work on a `feat/` branch. Committing to `main` and merging PRs stay human-only. Commit after every meaningful artifact write.
- `custom-002-prefer-subagent-decomposition.md`: split long or multi-unit work into parallel subagents by default. State the reason when work can't be split.
- `custom-003-git-up-to-date-shorthand.md`: `GUTD` means check out `main`, pull, and report untracked files.
- `custom-004-file-backlog-entries-immediately.md`: file out-of-scope problems as backlog entries at once, commit and push them, and report the ID.
- `custom-005-p9-push-and-raise-pr.md`: at P9, push the branch and tag and raise the PR without asking. Never merge, and never push to `main`.

## Confirmation
Human confirmed this design before proceeding: yes // Date and Time confirmed: 22 Oct 2026 @ 12:37 a.m. BST (run-mode anchor re-recorded in the next commit, see the P0 build log)
