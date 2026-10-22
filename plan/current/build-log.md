---
title: "Build Log - 0000035-write-gate-scope-and-path-hardening"
summary: "Working log file maintained by the orchestrator throughout the pipeline run."
---
# Build Log - 0000035-write-gate-scope-and-path-hardening

> Created at P0. Appended by the orchestrator at each phase boundary. Survives session changes.

## Header

| Field | Value |
|-------|-------|
| Feature ID | `0000035-write-gate-scope-and-path-hardening` |
| Pipeline start | `2026-10-20T23:28:28Z` |
| Tool | `Claude Code` |
| Primary model | `claude-opus-5-5` |
| Cheaper model | `claude-sonnet-5-5` |
| Run mode | `autonomous` |
| Parallel streams | `pending` (resolved at P1 start) |

---

## Phase Log

### P0: Assess & Coach

| Field | Value |
|-------|-------|
| Start | `2026-10-20T23:28:28Z` |
| End | `2026-10-21T23:37:01Z` |
| Wall-clock | `1448` |
| Streams | `n/a` |
| Model tier | primary |
| Skills loaded | planifest-orchestrator |
| Agents spawned | `4` |
| MCP calls | `0` |
| Parallel task batches | `1` |
| P0 questions asked | `7` |
| Brief complete | `no` |
| Stack unchanged | `yes` |
| Notes | Fresh start after `/clear`. Pre-flight: `main` up to date with `origin/main`, no open PRs, branch `feat/0000035-write-gate-scope-and-path-hardening` created. Two migrations sit outside `migrations/_done/` (`migrate-0.31.0-rerun-setup-for-shell-write-guard.md`, `migrate-remove-context-mode-and-telemetry.md`). Both target downstream projects. Not run here, because this repo is the framework source and moving them to `_done/` would ship them as done. |

- P0 exchange (backlog pickup): Q: which work to start, with a recommended write-gate batch (0000081, 0000124, 0000125) / A: take those and asked what else fits.
- P0 exchange (release fill): Q: add 0000062, 0000106, 0000107, 0000109, 0000114, and 0000117, split into two waves? / A: all nine entries together, one single wave.
- Release budget: none, three-story rule. The human on the loop chose one wave over the rule's split.
- Backlog pickup: pull-in 0000062, 0000081, 0000106, 0000107, 0000109, 0000114, 0000117, 0000124, 0000125. Every other entry: leave.
- P0 exchange (Fast Path authorisation): Q: scope record or wider allowlist for Fast Path writes? / A: not yet answered. The human on the loop added a tenth item instead.
- Backlog filed: 0000126 (migration run state lives outside the framework folder), at the request of the human on the loop. Pull-in: 0000126, same single wave.
- P0 exchange (old migrations): Q: how many old migrations, and do they need state too? / A (orchestrator): eight migrations, each needs a record. Five of six `_done/` files arrived already in `_done/`, so downstream projects never ran them. Recommended scan-then-record with no seeding from `_done/`.
- P0 exchange (migration state and Fast Path): Q: scan-then-record, then scope record or wider allowlist? / A: "And yes confirmed scope". Read as scan-then-record and the scope record.
- Backlog pickup committed: ten entry folders deleted, folded into `feature-brief.md`.
- Version suggested: `0.32.0` → `0.33.0` (Feature Pipeline, minor). Confirmed with the design.
- Scope Lock dispatch: four `planifest-scope-lock-agent` instances in one parallel batch, tier cheaper (`claude-sonnet-5-5`). All four returned drafts. Three raised flags, which go to the human on the loop unchanged.
- P0 exchange (combined confirmation turn): Q: confirm the design, accept / edit / reject each Scope Lock draft, and pick a run mode / A: "3" (Autonomous). Design and Scope Lock items not yet answered, so neither counts as confirmed. Run mode not yet recorded, because the `Run mode confirmed:` line must share the commit that confirms the design.
- P0 exchange (confirmation follow-up): Q: confirm the design and accept / edit / reject each Scope Lock item, with recommended flag resolutions / A: "Yes accept all". Read as an explicit yes to the design and an explicit accept for each of the four named items.
- Scope Lock (happy path): a Fast Path change declares its paths in a scope record, the gate admits only matching non-enforcement writes, `product.yml` names the release before archive, path tricks are blocked, and migrations stay put with records in `plan/_migrations/` [source: agent-draft-edited]
- Scope Lock (first-run path): with no `plan/_migrations/`, every migration is pending, the migrator creates the folder, each scan decides, and a stale `product.yml` waits for the next P7 [source: agent-draft-edited]
- Scope Lock (error path): a stale scope record is overwritten by the next Fast Path, resolution errors inside the root block with exit 2, and an unreadable migration record counts as pending [source: agent-draft-edited]
- Scope Lock (cross-session continuity): the scope record expires when the branch or `HEAD` changes, an interrupted migration runs again, and the migration re-run and P7 `product.yml` update are idempotent [source: agent-draft-edited]
- Scope Lock complete. All four scenario paths captured.
- Adoption mode: standard-iterative, confirmed by human on 2026-10-22
- Version confirmed: 0.33.0
- Decision (P0): re-record the autonomous anchor in a new commit / reason: commit `38541a5` wrote the confirmation line as a list item, so `run-mode.mjs` found no line that starts with its prefix. A force push to amend it is a standing-rule breach. The new commit adds the line below and re-states the design Confirmation line, which the human on the loop confirmed at 2026-10-21T23:37:01Z.

Run mode confirmed: autonomous (2026-10-21T23:37:01Z)

- Progress: P0 done at 2026-10-21T23:37:01Z: design confirmed, ten backlog entries in one wave, autonomous run

### P1: Spec

| Field | Value |
|-------|-------|
| Start | `2026-10-21T23:39:00Z` |
| End | `2026-10-22T02:10:00Z` |
| Wall-clock | `9060` |
| Streams | `3` |
| Model tier | primary (stream 01), cheaper (streams 02 and 03, shared artifacts) |
| Skills loaded | planifest-spec-agent, planifest-loop-runner |
| Agents spawned | `13` |
| MCP calls | `0` |
| Parallel task batches | `2` |
| Notes | Run mode from `run-mode.mjs`: autonomous. P1 checker re-check: no `loop-toggles.yml`, so no checker key is off. |

Toggle record (P1, binding for the run):

| Toggle | Value | Source |
|--------|-------|--------|
| `design_critic` | `on` | autonomous default |
| `verify_by_execution` | `on` | autonomous default |
| `cross_model_review` | `on` | autonomous default |
| `reversal_protocol` | `on` | autonomous default |
| `parallel_streams` | `on` | autonomous default |
| `p0_completeness` | `off` | absent default |

Streams formed (dependency test: stories that change the same file share a stream):

| Stream | Stories | Requirements | ID blocks |
|--------|---------|--------------|-----------|
| `stream-01-gate-rules` | US-001, US-003, US-004, US-005, US-006 | req-001, req-003, req-004, req-005, req-006 | ADR-001 to ADR-009, backlog 0000128 to 0000132 |
| `stream-02-release-manifest` | US-002 | req-002 | ADR-010 to ADR-014, backlog 0000133 to 0000135 |
| `stream-03-migration-state` | US-007 | req-007 | ADR-015 to ADR-019, backlog 0000136 to 0000138 |

- Decision (P1): US-001, US-003, US-004, and US-006 share one stream / reason: each changes `path-rules.mjs`. US-005 joins them because `ratchet-check.mjs` consumes `resolveRoot` from the same file.
- Decision (P1): shared artifacts (scope, risk register, domain glossary) go to one extra subagent, and the orchestrator writes the execution plan after the join / reason: the execution plan summarises the requirements, so it can't start first.
- Decision (P1): the scope record is line-based text with `branch`, `head`, and `paths`, capped at 16 KiB and 64 paths / reason: a fixed grammar lets the gate reject any malformed record whole.
- Decision (P1): the gate reads branch and `HEAD` from `.git` files, following `gitdir:` and `commondir`, and ignores the record when git state can't be read / reason: hooks spawn no process (0000032 ADR-004), and ignoring the record fails closed.
- Decision (P1): the link hop limit is 40 / reason: it matches Linux `MAXSYMLINKS`.
- Decision (P1): `set-product-release.mjs` carries the P7 `product.yml` update / reason: a script can be run twice and tested in a fixture, as `archive-current.mjs` is.
- Decision (P1): migration outcomes are `applied`, `not applicable`, and `skipped` / reason: a findings state would break the rule that no record means pending, and `skipped` keeps the migrator's `none` answer.
- Decision (P1): a migration with findings in this repo gets no record, and its findings go to the final report as an exception waiting for human review / reason: the confirmed design says a scan with findings records nothing until the human on the loop confirms the fix.
- Deviation (P1, unclassified): the scope record never enters a commit. Fast Path removes it before `git commit`, where the brief said the Fast Path commit deletes it.
- Deviation (P1, unclassified): a missing cwd now blocks a write into `src/`, which supersedes the 0000032 assertion in `test-0000032-req-006-outside-repository-pass.sh` lines 364 to 366.
- Backlog filed (P1): 0000128 (`ratchet-check.mjs` spawns `git status`), 0000136 (a framework-only migration becomes pending downstream), and 0000137 (the migration progress file lives in the framework folder).
- P1 join: all three streams at-join. `stream-reconcile.mjs` first reported 12 self-consumer findings, because each stream listed artifacts its own requirements consume. No artifact crosses streams, so the orchestrator cleared the Declares rows. The second run exited 0.
- P1 gate loop iteration 1: design critic REJECT (1 critical, 4 major, 9 minor). Fixes dispatched to three agents by file ownership.
- Deviation (P1, unclassified): the shared-artifact fix agent wrote `execution-plan.md`, `scope.md`, `risk-register.md`, and `domain-glossary.md` through a Python script, which breaks Hard Limit 8. The orchestrator checked the diff by hand, and no In Scope or acceptance-criteria line changed. Every later dispatch prompt states Hard Limit 8.
- Decision (P1): the Fast Path enforcement list adds hook wiring files from setup, `hooks/adapters/`, and `.git/`, and `fast-path.md` changes in step / reason: a scope record must never unwire enforcement.
- Decision (P1): the scope record is self-authorisation accepted at P0, and each admitted write prints a stderr notice / reason: the critic asked for a real control or an accepted-risk entry, and the run takes both.
- Decision (P1): `set-product-release.mjs` also creates `product.yml` with `--create` and owns `components[]` through `--component` / reason: every `product.yml` write then goes through one Node path.
- P1 gate loop iterations 2 and 3: REJECT each time. Approach 1 hit the cap of 3. Approach 2 makes the script carve-out a standing rule: the boot templates name the sanctioned scripts, and req-002 validates every script argument.
- Decision (P1): sanctioned scripts for Hard Limit 8 are `archive-current.mjs`, `set-product-release.mjs`, `promote-to-regression.sh`, `refresh-delete-boot-files.sh` and `.ps1`, and `setup.sh` and `setup.ps1` / reason: these are the scripts skill text runs to write files.
- Human touchpoint (P1): req-002 holds six acceptance criteria after an approach 2 fix, and folding three back needs a human `.ratchet-approve` line [outside list]
- Backlog filed (P1): 0000129 (the ratchet blocks undoing an uncommitted acceptance-criteria addition).
- P1 exchange (acceptance-criteria limit): Q: write the `.ratchet-approve` line to fold req-002 back to three criteria? / A: "Change to allow 10 acceptance criteria but favour 3."
- Decision (P1): `consistency-check.mjs` allows up to 10 acceptance criteria per requirement, and the feature brief template asks for 3 / reason: instruction from the human on the loop. req-002 keeps its six criteria, so no fold and no `.ratchet-approve` line are needed.
- Human touchpoint (P1) resolved: `consistency-check.mjs` exits 0 on `plan/current`. Governance suite and its regression copy pass, 95 tests each.
- P1 gate loop, approach 2 iteration 1: design critic APPROVE (0 critical, 0 major, 5 minor). The orchestrator fixed all five minors. `design.md` gains a "Decisions added at P1" section for the carve-out and the criteria limit. Loop state set to `done`.
- Gate (P1): passed. `consistency-check.mjs` clean, run mode still `autonomous`.
- Progress: P1 done at 2026-10-22T02:10:00Z: seven requirements in three streams, critic approved on approach 2
