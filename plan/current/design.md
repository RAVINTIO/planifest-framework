# Design - 0000033-human-on-the-loop-run-mode

## Feature
- Problem: The framework keeps the human in the loop at about ten points even in `continuous` mode, and P0 asks too many questions. Products that run hands-off must fight the framework text with overrides.
- Adoption mode: standard-iterative
- Feature ID: 0000033-human-on-the-loop-run-mode
- Version: 0.31.0 to 0.32.0 (Feature Pipeline, minor bump)
- Discovery: see `plan/current/discovery.md` (raw P0 findings; do not embed them here; this document records confirmed decisions only)

## Product Layer
- User stories:
  - US-001: As the human on the loop, I choose `autonomous` at P0, so that the run goes from confirmed design to a raised PR with no gate waiting for me.
  - US-002: As the human on the loop, I get asked only for items on a declared exception list, and only in one final report, so that I know exactly when a run needs me.
  - US-003: As the human on the loop, I see a failed gate retried by a fresh-context checker with a changed approach, so that a cap or a no-progress halt doesn't stop an autonomous run.
  - US-004: As the human on the loop, I answer P0 questions only where the answer needs my judgement or changes what gets built, so that derivable items reach me once, in the design draft.
  - US-005: As the human on the loop, I set a release budget for my repo, so that P0 fills each release from the backlog up to that budget instead of a fixed three-story rule.
  - US-006: As the human on the loop, I see independent requirements move through the phases as parallel subagent streams with one owner for every join, so that a run with many small requirements finishes faster and leaves no seam unowned.
  - US-007: As the human on the loop, I get a P7 to P9 close-out that needs no glob delete and ends with a clean working tree, so that an autonomous run can finish without me.
  - US-008: As the human on the loop, I see the P4 checks run again after P6 edits, so that a doc edit can't break a check that already passed.
  - US-009: As the human on the loop, I read choice prompts that name who acts in each option, so that I never have to track a shifting "I".
  - US-010: As the human on the loop, I route a change with no `src/` component through a lightweight track, so that governance and documentation changes stop running the full Feature Pipeline.
- Acceptance criteria confirmed: 7 feature-level criteria in `feature-brief.md`. The spec-agent expands them per requirement.
- Constraints:
  - Merging a PR stays human-only in every mode.
  - Hard limits 2 and 3 (schema and destructive changes) stay human-gated in every mode.
  - `interactive` and `continuous` behave exactly as before.
  - No em dashes in framework prose.
- Integrations: none outside the framework.

## Design decisions (derived, confirmed with this design)

| Area | Decision |
|------|----------|
| Run mode | `autonomous` becomes a third `plan/.run-mode` value. 0000012-ADR-005 changes so `autonomous` is recognised. Unknown values still read as `interactive`. |
| Exception list | Only these wait for the human: schema and destructive changes, a gross deviation, human review of the running result, promotion beyond the candidate environment, a human-only input, and an exhausted budget. A product can add items in an override. |
| Gross deviation | A change the reversal protocol would class as *altering*: it changes the confirmed problem, users, or in-scope list. |
| Gates become loops | In `autonomous`, every phase gate runs as a loop under `planifest-loop-runner` with a fresh-context checker. Existing caps stay. At a cap, the run tries a different approach, up to 3 approaches per gate. The fourth becomes an exception. The reversal budget stays at 2. |
| Final report | One report at the end of P9: what shipped, every decision and deviation, the version, the PR and its CI result, and every exception waiting. |
| Visibility | A one-line progress entry per phase in the build log, and a human-touchpoint count that the P8 report flags. No push notifications. |
| P0 questions | P0 asks only real forks. Adoption mode, version, stack, NFRs, risks, the component split, and the feature ID go into the design draft for one confirmation, unless a conflict warning applies. The design, the Scope Lock batch, and the run mode confirm in one turn. The P0 build-log block records the question count. |
| Record sampling | If a design depends on existing records, discovery samples recent rows and states how often each value it relies on is usable. The design names that rate as an assumption. |
| Release budget | A new `planifest-overrides/release-budget.yml` holds a target and a ceiling in size points. P0 sizes each requirement as small (1), medium (2), or large (3) and fills the release from the backlog up to the target. If the file is absent, the three-story rule stays. |
| Parallel streams | Parallel dispatch is the default in every phase. Each phase skill lists the work units that always run in parallel. Independent requirements move through P1 to P4 as separate streams, each with a state file under `plan/current/streams/`. A new loop toggle, `parallel_streams`, defaults to `on` in `autonomous` and `off` otherwise. |
| Join owner | The orchestrator owns every join between streams or batches. After each join, a reconciliation step checks that every artifact one stream declares is consumed by another stream or by a requirement. |
| P7 archive | A new `scripts/archive-current.mjs` moves each tracked item with `git mv`, removes markers by explicit path, and prints what it moved. Each step is a separate command, so a resumed run repeats only unfinished steps. No glob delete. |
| Clean close-out | The P8 build report goes into the archive commit. P8 and P9 end with a scoped `git status --porcelain` check. Any leftover file is committed in `autonomous`, or listed for the human in other modes. |
| Revalidate after P6 | The docs agent reruns the P4 check set after its edits. A product can declare a smaller doc-check command in `planifest-overrides/`. |
| Choice prompts | Every two-option prompt names the actor in each option. The P9 push prompt is the first case, and a sweep covers the other phase skills. |
| Lightweight track | Fast Path's prerequisite relaxes to admit a change with no `src/` target. Its four criteria stay. The orchestrator's track table says so. |

## Architecture Layer
- Latency target: not applicable. The framework is skill text and local scripts.
- Availability target: not applicable.
- Scalability target: a run with 10 or more independent requirements uses parallel streams. The P8 report records subagent count and wall-clock time per phase.
- Security: no auth. Data classification: internal framework text, no regulated data. The exception list keeps schema changes, destructive operations, and merges human-only.
- Data privacy: no regulated data.
- Observability: build-log progress lines, question count, and touchpoint count, assessed at P8.
- Cost boundary: not constrained.

## Engineering Layer
- Stack: Markdown skills and standards / Node `.mjs` scripts and hooks / no database / no ORM / no IaC / no cloud / no compute / GitHub Actions CI / Build target: local
- Components: `planifest-framework`: skills, standards, templates, hooks, and scripts. Every change lands here.
- Data ownership: `planifest-framework` owns `plan/.run-mode`, `plan/current/`, and `plan/current/streams/`. The product's human owns `planifest-overrides/`, and the framework only reads it.
- Deployment: shipped as framework source. Downstream products receive it when they refresh `planifest-framework/` and re-run setup.
- API versioning: not applicable. The run-mode file keeps back-compat: an older framework reads `autonomous` as `interactive`.

## Scope
- In: backlog entries 0000078, 0000076, 0000101, 0000103, 0000104, 0000082, 0000075, 0000073, 0000086, 0000059, and 0000062.
- Out:
  - Decomposing the orchestrator skill (0000020).
  - Quality gates for agent workflow evaluation (0000097), beyond the touchpoint count.
  - Shell-guard, setup, and Windows entries.
  - Push notifications.
- Deferred: nothing deferred.

## Assumptions
- A fresh-context checker can stand in for the human at a phase gate. Impact if wrong: autonomous runs ship defects a human would have caught. The human still reviews before merging.
- Three approaches per gate is enough for most failures. Impact if wrong: more runs end with an exception. The P8 report shows how often.
- Downstream overrides like ovelunor's keep working. Impact if wrong: a product's hands-off runs change behaviour on upgrade. The first-run path says overrides win.

## Risks
- The orchestrator skill grows further, at 9,276 words already. Likelihood: high. Impact: medium. Mitigation: put new detail in standards files and link to them. 0000020 follows this run.
- Parallel streams break the order the gates rely on. Likelihood: medium. Impact: high. Mitigation: streams join at every review gate, and the orchestrator owns each join.
- Back-compat regressions in `interactive` or `continuous`. Likelihood: medium. Impact: high. Mitigation: every existing suite must pass unchanged, plus new tests for each mode.
- Run size. This run holds 10 stories, against today's three-story rule. Likelihood: medium. Impact: medium. Mitigation: four parallel streams, and P4 runs the full suite.

## Dependencies
- Upstream: 0000016 loop engineering (`planifest-loop-runner`, toggles, caps), 0000025-ADR-003 Scope Lock batching, 0000032 session markers and context clear.
- Downstream: every product that uses Planifest. `ovelunor` can retire its `autonomous-after-p0.md` and `p0-ask-only-real-forks.md` overrides.

## Active Skills
None

## Skill Map
| Requirement | Best-fit Skill | Rationale |
|-------------|----------------|-----------|
| US-001 to US-003 - autonomous mode, exceptions, gates as loops | planifest-codegen-agent | Changes the orchestrator, loop-runner, validate, codegen, and ship skill text, with text-level tests |
| US-004 - P0 real forks and record sampling | planifest-codegen-agent | Changes the orchestrator's P0 and the discovery template |
| US-005 - release budget | planifest-codegen-agent | A new override template and P0 sizing text |
| US-006 - parallel streams and join owner | planifest-codegen-agent | Changes the dispatch standards, phase skills, and loop toggles |
| US-007 - close-out | planifest-codegen-agent | A new archive script with TDD tests, and ship-agent text |
| US-008 - revalidate after P6 | planifest-codegen-agent | Docs-agent text |
| US-009 - choice prompts | planifest-codegen-agent | A sweep of phase skill text |
| US-010 - lightweight track | planifest-codegen-agent | Fast Path workflow and orchestrator routing text |

## Repo Instructions
- `custom-001-local-git-only.md`: fetch, pull, push, and `gh pr create` without asking. Work on a `feat/` branch. Committing to `main` and merging PRs stay human-only. Commit after every meaningful artifact write.
- `custom-002-prefer-subagent-decomposition.md`: split long or multi-unit work into parallel subagents by default. State the reason when work can't be split.
- `custom-003-git-up-to-date-shorthand.md`: `GUTD` means check out `main`, pull, and report untracked files.

## Confirmation
Human confirmed this design before proceeding: pending
