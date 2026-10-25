# Design - 0000039-ravintio-rebrand

## Feature
- Problem: the pack, its skills, variables, markers, and prose still say Planifest, but the org and the ecosystem name the product RAVINTIO Framework.
- Adoption mode: standard-iterative (`plan/_archive/` holds feature folders, and `docs/about.md` exists)
- Feature ID: 0000039-ravintio-rebrand
- Version: 0.36.0 to 0.37.0, a minor bump. The human on the loop set it on 2026-10-25. This overrides the major bump in backlog 0000237.
- Discovery: see `plan/current/discovery.md` (raw P0 findings; do not embed them here; this document records confirmed decisions only)

## Product Layer
- User stories:
  - US-001: As a human on the loop, I see RAVINTIO Framework in every live path, identifier, and prose line, so that the pack matches the RAVINTIO org.
  - US-002: As a human on the loop with a consumer repo on 0.36.0, I run one migration that moves it to the RAVINTIO pack and keeps a backup of the old pack, so that I upgrade without losing files.
  - US-003: As a human on the loop, I get a failing test when a live file brings back the old name, so that the rename stays complete.
- Acceptance criteria confirmed: 3 at brief level. P1 writes about 3 per requirement.
- Constraints:
  - History stays byte-identical: `plan/_archive/`, `plan/changelog/`, `plan/_migrations/`, and the bodies of shipped migrations.
  - Old feature ids, ADR ids, backlog ids, and sibling repo names stay as written.
  - Bash suites must pass under Bash 3.2 and Bash 5. Line loops use `done <<< "$(...)"`, never `done < <(...)`.
- Integrations: consumer repos through `setup.sh`, `setup.ps1`, and the consumer migration. GitHub through the repo rename after merge.

## Architecture Layer
- Latency target: not applicable (no service)
- Availability target: not applicable (no service)
- Scalability target: not applicable
- Security: no auth. The migration helpers move files in a consumer repo. They refuse symbolic links and junctions. They move the old pack to a backup and never delete it. Data classification: public source code.
- Data privacy: no regulated data
- Observability: standard defaults. Hook and setup output changes its prefix from `[Planifest]` to `[RAVINTIO]`.
- Cost boundary: not constrained

## Engineering Layer
- Stack: unchanged. Bash, PowerShell 5.1 and 7, Node `.mjs` scripts, Bash test suites, GitHub Actions CI, `Build target: local`.
- Components:
  - `ravintio-framework` (renamed from `planifest-framework`): the pack.
  - `setup-hook-integration`: hook wiring tests, path references updated.
- Data ownership: `ravintio-framework` owns the pack files and the consumer marker files. Consumer repos read them.
- Deployment: consumers copy the pack in, run the migration, then run setup.
- API versioning: not applicable
- Rename map:
  - Prose: `RAVINTIO Framework`, with RAVINTIO in block capitals.
  - Paths and identifiers: lowercase `ravintio`. That covers `ravintio-framework/`, `ravintio-overrides/`, the 21 `ravintio-*` skills, the workflow file `ravintio.yml`, and the `product.yml` and `component.yml` ids.
  - Variables: `PLANIFEST_*` becomes `RAVINTIO_*`.
  - Markers: `.ravintio-session`, `.ravintio-manifest`, `.ravintio-setup-flags`, and `<!-- ravintio-overrides:instructions:start -->`.
  - Other names: the `@ravintio` npm scope, the `[RAVINTIO]` log prefix, and the `RAVINTIO Strict Pipeline` workflow name.
  - Repo links: `github.com/RAVINTIO/ravintio-framework`. The sibling `planifest-docs` links stay, with allowlist entries.
  - Vendored upstream text under `external-skills/` stays as written. Only pack-authored lines change.
- Old names that setup still reads through 0.x, removed at 1.0.0:
  - `PLANIFEST_SESSION_ID`, read only when `RAVINTIO_SESSION_ID` is unset, with no warning
  - the old boot-file markers and ignore-file headers, which setup replaces so no block appears twice
  - `.planifest-setup-flags`, which setup and refresh-setup read once and then remove
  - All other variables rename with no fallback, because only the pack sets them.
- Consumer migration `migrate-0.37.0-ravintio-rename.md`, with `.sh` and `.ps1` helpers:
  1. The consumer copies `ravintio-framework/` in, runs the helper, then runs setup.
  2. The helper moves `planifest-overrides/` to `ravintio-overrides/`. It renames the workflow and rewrites only the pack's own names in it.
  3. It removes the old marker files. It stops git tracking of the old pack and moves the pack to `.ravintio-backup/planifest-framework/`. It never deletes it.
  4. A clash, such as an existing `ravintio-overrides/` or `.ravintio-backup/`, stops the helper before it moves anything. Every step can run again safely.
  5. Setup stops while `planifest-framework/` or `planifest-overrides/` exists, and names the migration.
  6. The migration warns that branch protection must require `RAVINTIO Strict Pipeline` in place of the old check name.
  7. An "Applies when" check skips this source repo. This repo writes its own `plan/_migrations/` record with outcome `not applicable`, per 0000035 ADR 010.
- Brand guard: a Bash suite reads `git ls-files` minus the history paths and `plan/current/`. It fails on any `planifest` hit, in any case, in a path or a line. The only exceptions are allowlist entries, each a path regex plus a line regex with a reason. A stale entry also fails. A second case plants the old name and expects a failure.
- Bulk rename method (human decision, 2026-10-25): one scripted pass in P3, a recorded exception to Hard Limit 8.
  1. **Write** creates the script in the scratchpad, never in the repo.
  2. The script uses `git mv` for paths and a replace that skips the protected list.
  3. The human on the loop approved the scripted pass at P0 on 2026-10-25. The run doesn't stop for it. The script runs once P1 has listed the protected names and their tests are in place.
  4. It runs once. Its output, the `setup.sh claude-code` re-run, and the build-log update land in one commit.
  5. Every follow-up fix uses **Edit**.
- Before the pass: P1 lists every split or built name, every history-reading suite, and the `setup.sh` mojibake lines. Each one gets a test or a protected-list entry.

## Scope
- In:
  - the rename map above, across every live file and path
  - setup handling of old markers and the old pack folder
  - the consumer migration and its two helpers
  - the brand guard suite
  - the 0.37.0 version bump
- Out:
  - `plan/_archive/`, `plan/changelog/`, `plan/_migrations/` records, and shipped migration bodies
  - sibling repos, including RAVINTIO Zero and `planifest-docs`
  - the local clone folder and the `C:\d\planifest\framework\` path in the refresh script
  - every other backlog entry
- Deferred:
  - `gh repo rename ravintio-framework` and the `origin` update run after the human on the loop merges the PR. Repo links resolve once the repo rename runs.
  - The old-name reads go at 1.0.0.
- Release size: `three-story rule`. Three stories, so it fits.

## Assumptions
- Consumers set no `PLANIFEST_*` variable except `PLANIFEST_SESSION_ID` - impact if wrong: a consumer setting loses effect silently after upgrade.
- No consumer depends on the `@planifest` npm scope outside the OpenCode plugin path - impact if wrong: that consumer's plugin import breaks.

## Risks
- A split or built old name escapes the replace or breaks a test. Likelihood high, impact medium. P1 lists them first, and the brand guard catches the rest.
- A suite that reads history or archived paths fails after the rename. Likelihood high, impact medium. P1 lists all 43 suites and protects their history paths.
- This run's own skills and hooks change name mid-run. Likelihood high, impact high. The rename and the setup re-run land in one commit, and the resume step names the new skill.
- The PowerShell helper fails to parse or acts on a junction. Likelihood medium, impact high. The helper never deletes, and CI runs both PowerShell legs.
- Bash 3.2 hides lines in a guard loop on the macOS leg. Likelihood medium, impact medium. The guard and new suites use the safe loop form.
- A consumer's branch protection still requires the old check name. Likelihood medium, impact low. The migration warns.

## Dependencies
- Upstream: RAVINTIO Zero 0000160 and 0000164 as prior art. No code dependency.
- Downstream: every consumer repo on 0.36.0 or earlier. Backlog 0000225 and 0000238 follow this release.

## Active Skills
None

## Skill Map
| Requirement | Best-fit Skill | Rationale |
|-------------|----------------|-----------|
| REQ-001 - pack-paths-and-identifiers | planifest-codegen-agent | The scripted pass plus manifest edits |
| REQ-002 - runtime-names | planifest-codegen-agent | Setup, hooks, markers, and CI wiring, under TDD |
| REQ-003 - environment-variables | planifest-codegen-agent | Variable rename and the one fallback, under TDD |
| REQ-004 - brand-prose | planifest-docs-agent | Docs, README, and link text |
| REQ-005 - history-and-split-name-protection | planifest-test-writer | Tests first for every split name and history reader |
| REQ-006 - consumer-migration | planifest-codegen-agent | Helpers under TDD, then the security review |
| REQ-007 - brand-guard | planifest-test-writer | The guard suite and its allowlist |
| REQ-009 - migration-ordering-and-old-paths | planifest-codegen-agent | Split from REQ-006 at P1: migrator order, old-path mapping, and the Applies when check |
| REQ-008 - emitted-names | planifest-codegen-agent | Split from REQ-002 at P1: names the hooks and setup emit, under TDD |

## Repo Instructions
Five files in `planifest-overrides/instructions/`, read at P0. They move to `ravintio-overrides/instructions/` with the rename.
- `custom-001-local-git-only.md`: fetch, pull, push, and `gh pr create` need no prompt. Work on a `feat/` branch. Committing to `main` and merging PRs stay human-only. Commit after every meaningful artifact write.
- `custom-002-prefer-subagent-decomposition.md`: split long or multi-unit work into parallel subagents, above the size floor.
- `custom-003-git-up-to-date-shorthand.md`: `GUTD` means check out `main`, pull, list untracked files, and report the last merged PR's checks.
- `custom-004-file-backlog-entries-immediately.md`: file out-of-scope problems as backlog entries at once, then commit and push them.
- `custom-005-p9-push-and-raise-pr.md`: at P9, push and raise the PR without asking. Never merge.

## Confirmation
Human confirmed this design before proceeding: yes // Date and Time confirmed: 25 Oct 2026 @ 02:12 AM GMT
