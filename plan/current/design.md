# Design - 0000036-pipeline-friction-and-gate-fixes

## Feature
- Problem: recent runs pay for the same workarounds at P0, P7, and P9. Installed copies drift from source. Two write-gate bypasses and two hook output gaps remain from the 0000035 review.
- Adoption mode: standard-iterative (signal: `plan/_archive/` holds prior features, and `docs/about.md` exists)
- Feature ID: 0000036-pipeline-friction-and-gate-fixes
- Version: `0.33.0` → `0.34.0` (Feature Pipeline, minor bump). `planifest-framework/component.yml` carries it. `product.yml` is set to match at P7.
- Discovery: see `plan/current/discovery.md` (raw P0 findings; do not embed them here; this document records confirmed decisions only)

## Product Layer
- User stories:
  - US-001: As the human on the loop in a downstream project, I get a migration that re-runs setup after I update the framework, so that my installed hooks and boot file match the framework version. (0000158)
  - US-002: As the human on the loop, I see which installed skills differ from source when a session starts, so that no phase runs on a stale skill copy. (0000154)
  - US-003: As the human on the loop, I see every ship commit pass the `commit-msg` hook whatever the feature ID length, so that P7 and P9 never stop on a rejected subject. (0000160)
  - US-004: As the human on the loop, I see `autonomous` restore after P0 whether the anchor line is bare or a list item, so that a format slip never needs a repair commit. (0000127)
  - US-005: As the human on the loop, I see every hard-limit citation name its rule, so that no agent mistakes the build-log rule for the Write-or-Edit rule. (0000157)
  - US-006: As the human on the loop, I see the design critic review P1 and P2 in every run mode by default, so that a fresh-context check catches drafting gaps before I read the artifacts. (0000122)
  - US-007: As the human on the loop, I see an agent ask whether a requirement holds two concerns before it grows past three criteria, so that a requirement is split rather than packed. (0000139)
  - US-008: As the human on the loop, I rely on the write gate to treat a folder or FIFO at `design.md` as no design, so that neither one admits a `src/` write. (0000143)
  - US-009: As the human on the loop, I rely on the write gate to judge a permitted file name inside an enforcement folder like any other path, so that the name can't bypass the enforcement list. (0000159)
  - US-010: As the human on the loop, I see `run-tests.sh` clear `CLAUDE_PROJECT_DIR` before any suite, so that a suite run inside Claude Code tests its fixture and not the real repo. (0000155)
  - US-011: As the human on the loop, I see every hook message escape the text it quotes, so that a crafted criterion or path can't forge or hide hook output. (0000149)
- Acceptance criteria confirmed: 31 (see `feature-brief.md`)
- Constraints:
  - 0000035 ADR 001 and 0000032 ADR 004: hooks use Node built-ins only, with no process spawn.
  - 0000003 ADR 005: hooks fail open on unexpected errors. US-008 narrows it for a non-regular `design.md` only.
  - 0000033 ADR 009: Fast Path never admits an enforcement path.
  - Every change goes through **Write** or **Edit**.
- Integrations: none

## Decisions confirmed at P0
- Run mode: `autonomous`.
- Re-run-setup migration (US-001): one migration, `migrate-0.34.0-rerun-setup.md`, covers the setup-delivered changes in both 0.33.0 and 0.34.0. It follows the 0.31.0 migration's sections. This repo records it `applied` after P3 re-runs setup here.
- Drift check (US-002): a new `scripts/skill-drift-check.mjs` compares `SKILL.md` text only, source against the active tool's installed copy. It first applies setup's four path rewrites to the source and strips one leading byte order mark from both copies (P1 deviation, see the build log). It warns and never blocks. On drift, the orchestrator loads the source copy and recommends `planifest-refresh-setup`. It never re-runs setup itself.
- Ship subjects (US-003): every skill commit subject keeps placeholders out. Subjects name the phase and action only, as in `plan(p9): clear session markers`. The feature ID goes in the body.
- Run-mode anchor (US-004): `run-mode.mjs` accepts the bare line or one leading `- `. It keeps the one-commit rule and the design Confirmation check unchanged. The skill and template show the bare line in a code block as the preferred form.
- Hard-limit citations (US-005): cite by name and source, for example "the build-log rule (orchestrator Hard Limit 8)" and "the Write-or-Edit rule (boot Hard Limit 8)". No renumbering.
- Design critic default (US-006): an absent key reads as `report-only` outside `autonomous`, as the entry suggests. `autonomous` stays `on`. Moving the default to `on` waits until the false-positive rate is known. An ADR records the change.
- Split step (US-007): the step fires when a requirement would reach a fourth criterion. It asks whether the requirement holds two concerns. If it does, the agent splits it into a new requirement and story.
- Non-regular `design.md` (US-008): `lstat` runs before any read. Anything other than a regular file counts as no design. An ADR narrows 0000003 ADR 005 for this case only. A failed read of a regular file still fails open.
- Permitted names (US-009): the always-permitted shortcut skips paths inside the enforcement list. Those paths take the normal route, through the design scope or the Fast Path scope verdict. Every other path behaves as before.
- Drift check outcomes (US-002, from Scope Lock flags): exit 0 when every copy matches, 1 on drift or a missing copy, and 2 when it can't compare. A project with no installed copies reports "not installed" with exit 1 and a setup recommendation. If the active tool is unknown, the check covers every installed tool folder it finds. The orchestrator runs the check again after any setup run in the same session.
- `lstat` failure (US-008, corrected at P1): if `lstat` throws, for example with `EACCES`, the gate reads it as no design, as `existsSync` does today. Fail-open would turn today's block into a pass. Only a failed open or read of a regular file still fails open under 0000003 ADR 005.
- Anchor fallback (US-004, from Scope Lock flags): a forged, uncommitted, or missing anchor reads as `interactive`, as `run-mode.mjs` does today.
- Toggle file (US-006, from Scope Lock flags): a missing `loop-toggles.yml` reads the same as a missing key. Critic verdicts go to the build log, with no dismissal step.
- Migration on a fresh 0.34.0 install (US-001): the migration still applies. Setup is safe to re-run, and the migrator writes the record only when the run completes.
- Release fill: eleven backlog entries in one wave, chosen by the human on the loop over the three-story rule.

## Architecture Layer
- Latency target: each hook call stays under 500 ms. The drift check finishes under 1 s on this repo.
- Availability target: not applicable (local hooks and scripts)
- Scalability target: not applicable
- Security: no auth. The write gate and the hook output are the controls under change. Every new block exits 2 with its reason on stderr. Quoted text in hook output goes through `shown()`. Data classification: repository files only, no regulated data.
- Data privacy: no regulated data
- Observability: standard defaults. Block reasons and drift warnings go to stderr.
- Cost boundary: `report-only` adds one critic subagent at each of the P1 and P2 gates outside `autonomous`.

## Engineering Layer
- Stack: JavaScript ES modules on Node built-ins / Bash and PowerShell setup / Markdown skills / no database / no ORM / no IaC / no cloud / no compute / GitHub Actions CI / Build target: local. Stack unchanged.
- Components:
  - `planifest-framework`: hooks, scripts, skills, standards, templates, migrations, and tests.
  - `setup-hook-integration`: setup integration docs, touched only if setup behaviour changes.
- Data ownership:
  - `plan/_migrations/` run records: owned by the migrator skill, read by orchestrator resume detection.
  - The build-log run-mode anchor: owned by the orchestrator, read by `run-mode.mjs`.
  - Installed copies under tool folders: owned by the setup scripts, read by the drift check.
- Deployment: framework files ship by copy through `setup.sh` and `setup.ps1`.
- API versioning: not applicable

## Component Paths
- `planifest-framework/`
- `src/setup-hook-integration/`
- `.claude/skills/`
- `.github/workflows/`
- `./product.yml`

## Scope
- In: backlog entries 0000122, 0000127, 0000139, 0000143, 0000149, 0000154, 0000155, 0000157, 0000158, 0000159, and 0000160. One re-run-setup migration for 0.34.0, with its record in this repo.
- Out:
  - Shell-guard parser entries 0000105, 0000108, 0000115, and 0000116. They wait on 0000118 and 0000119.
  - The remaining 0000035 hardening entries.
  - Renumbering the hard limits.
  - Changing what setup copies or where.
- Deferred: nothing deferred.
- Release size: three-story rule (no `release-budget.yml`). Eleven stories in one wave, by the choice of the human on the loop.

## Assumptions
- Setup copies each `SKILL.md` with four relative-path rewrites (`setup.sh:80-85`, `setup.ps1:176-180`), and PowerShell 5 adds a byte order mark. The drift check reproduces both - impact if wrong: a future change to setup's rewrites makes the drift check report false drift. P1 corrected the P0 assumption that setup copies byte for byte.
- The drift check can tell the active tool from its install marker, `.claude/.planifest-setup-flags` or the tool's equivalent - impact if wrong: the check falls back to checking every installed tool folder it finds.
- No existing records: `discovery.md` `## Record Samples` reads None.

## Risks
- `report-only` critic findings slow P1 and P2 outside `autonomous`. Likelihood medium, impact low. The verdict blocks nothing.
- Accepting a `- ` anchor widens what `run-mode.mjs` trusts. Likelihood low, impact high. The one-commit rule and the design Confirmation check stay unchanged, and the suite rejects forged forms.
- Changing `shown()` truncation shifts the text of existing block messages. Likelihood medium, impact low. Suites that match exact text get updated with it.
- Eleven stories in one run exceed the three-story rule. Likelihood medium, impact medium. The run uses parallel work by file ownership, with `path-rules.mjs` in one stream.

## Dependencies
- Upstream: 0000035 `path-rules.mjs`, the migration records, and the sanctioned-scripts sentence. 0000033 `run-mode.mjs` and the loop toggles.
- Downstream: every project that refreshes the framework gets the 0.34.0 migration, the drift check, and the new critic default.

## Active Skills
None

## Skill Map
| Requirement | Best-fit Skill | Rationale |
|-------------|----------------|-----------|
| REQ-001 - rerun-setup-migration | planifest-codegen-agent | Migration doc, policy sentence, and suite |
| REQ-002 - skill-drift-check | planifest-codegen-agent | New Node script and orchestrator text, test first |
| REQ-003 - ship-commit-subjects | planifest-codegen-agent | Skill template edits plus a suite check |
| REQ-004 - run-mode-anchor-format | planifest-codegen-agent | `run-mode.mjs` matching, test first |
| REQ-005 - hard-limits-cited-by-name | planifest-codegen-agent | Text edits across skills and templates plus a suite check |
| REQ-006 - design-critic-default | planifest-codegen-agent | Toggle text and one flipped assertion |
| REQ-007 - story-split-step | planifest-codegen-agent | Skill text plus a suite check |
| REQ-008 - non-regular-design-md | planifest-codegen-agent | `path-rules.mjs` change, test first |
| REQ-009 - permitted-names-in-enforcement-paths | planifest-codegen-agent | `path-rules.mjs` change, test first |
| REQ-010 - run-tests-clears-project-dir | planifest-codegen-agent | Runner and suite edits |
| REQ-011 - escaped-hook-output | planifest-codegen-agent | `shown()` and two hooks, test first |

## Repo Instructions
- `custom-001-local-git-only.md`: fetch, pull, push, and `gh pr create` without asking. Work on a `feat/` branch. Committing to `main` and merging PRs stay human-only. Commit after every meaningful artifact write.
- `custom-002-prefer-subagent-decomposition.md`: split long or multi-unit work into parallel subagents by default. State the reason when work can't be split.
- `custom-003-git-up-to-date-shorthand.md`: `GUTD` means check out `main`, pull, and report untracked files.
- `custom-004-file-backlog-entries-immediately.md`: file out-of-scope problems as backlog entries at once, commit and push them, and report the ID.
- `custom-005-p9-push-and-raise-pr.md`: at P9, push the branch and tag and raise the PR without asking. Never merge, and never push to `main`.

## Confirmation
Human confirmed this design before proceeding: yes // Date and Time confirmed: 22 Oct 2026 @ 10:33 p.m. BST
