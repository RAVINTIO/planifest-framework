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
| End | `2026-10-22T05:49:00Z` |
| Wall-clock | `22200` |
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
- Progress: P1 done at 2026-10-22T05:49:00Z: seven requirements in three streams, critic approved on approach 2

### P2: ADRs

| Field | Value |
|-------|-------|
| Start | `2026-10-22T05:50:00Z` |
| End | `2026-10-22T06:16:07Z` |
| Wall-clock | `1567` |
| Streams | `3` |
| Model tier | primary |
| Skills loaded | planifest-adr-agent, planifest-loop-runner |
| Agents spawned | `9` |
| MCP calls | `0` |
| Parallel task batches | `1` |
| Notes | Skills inbox empty. One ADR agent per stream, in one parallel batch, each inside its own ADR block. |

- P2 exchange (acceptance-criteria warning): A: "There should still be a warning above 3 and less than 10 though for feedback. Just not a hard block."
- Decision (P2): `consistency-check.mjs` prints a `⚠` warning for 4 to 10 criteria and still exits 0. Above 10 stays a finding / reason: instruction from the human on the loop. Both governance suite copies pass, 96 tests each.
- P2 exchange (story split): Q: why no story split before adding criteria? / A (orchestrator): the fold aimed at the count and skipped the split the brief template asks for. Offered a split of req-002 into req-002 (P7 update) and req-008 (sanctioned scripts). Awaiting the answer of the human on the loop.
- P2 join: all three streams at-join with 15 ADRs (ADR-001 to ADR-008, ADR-010, ADR-011, ADR-015 to ADR-019). `stream-reconcile.mjs` exits 0. ADR-001 is the only stack ADR.
- Backlog filed (P2): 0000130 (no check ties setup wiring files to the Fast Path enforcement list).
- P2 exchange (story split) answered: "Yes split and repeat P1 and P2 assessing existing work. Put in a backlog item to always consider a split if acs grow."
- Decision (P2): split US-002 and req-002. req-002 keeps the P7 `product.yml` update. New US-008 and req-008 take the Hard Limit 8 sanctioned-scripts rule and the script input validation. req-008 joins `stream-02-release-manifest`, because it changes the same script / reason: instruction from the human on the loop. The split runs while no loop is active, so the ratchet stays unarmed.
- Decision (P2): after the split, the P1 critic loop reopens over the P1 artifacts. Then the P2 critic reviews the combined P1 and P2 set. Both assess the existing work, not a rewrite / reason: instruction from the human on the loop.
- Backlog filed (P2): 0000139 (consider a story split whenever acceptance criteria grow).
- req-002 split done: req-002 keeps the P7 update, req-008 (US-008) takes the carve-out. `consistency-check.mjs` clean with no warnings.
- P1 re-run critic: APPROVE (0 critical, 0 major, 5 minor), in `design-critic-p1-split.md`. Loop state set to `done`.
- Decision (P2): split req-001 into req-001 (scope record) and req-009 (Fast Path enforcement list, US-009) / reason: the critic named it a split candidate, and the enforcement list is its own concern with its own ADR-004. The human on the loop asked for a split whenever criteria grow.
- Decision (P2): split req-007 into req-007 (migration run-state behaviour) and req-010 (the one-off migration run in this repo, US-010) / reason: the critic named it a split candidate. Running the eight migrations here is a one-off task with its own exception flow.
- Deviation (P1, directed by the human on the loop): `consistency-check.mjs` allows up to 10 acceptance criteria and warns from 4 to 10, in commits `c7e7642` and `bb2d692`. No story in the brief covers it. ADR-012 records the decision, and `scope.md` lists it in scope.
- Decision (P2): req-009 joins stream 01 and req-010 joins stream 03, because each changes the same files as its source requirement. IDs req-009, req-010, US-009, and US-010 sit outside the stream blocks, because the orchestrator assigns them at the join.
- P2 gate loop iteration 1: design critic REJECT (0 critical, 1 major, 8 minor). M1: the criteria-limit change had no ADR. One fix agent resolved all nine and added ADR-012.
- P2 gate loop iteration 2: design critic APPROVE (0 critical, 0 major, 3 minor). The orchestrator fixed the three minors. Loop state set to `done`.
- Gate (P2): passed. Ten requirements with 3 criteria each, 16 ADRs. `consistency-check.mjs` clean with no warnings, `stream-reconcile.mjs` exits 0, run mode still `autonomous`.
- Progress: P2 done at 2026-10-22T06:16:07Z: 16 ADRs, three requirement splits, critic approved on iteration 2

### P3: Codegen

| Field | Value |
|-------|-------|
| Start | `2026-10-22T06:20:00Z` |
| End | `2026-10-22T06:50:13Z` |
| Wall-clock | `1813` |
| Streams | `3` |
| Model tier | primary |
| Skills loaded | planifest-codegen-agent |
| Agents spawned | `3` |
| MCP calls | `0` |
| Parallel task batches | `1` |
| Notes | Skills inbox empty. Live hooks run from the git-ignored copies under `.claude/hooks/`, so source edits can't block this session. |

- Decision (P3): one codegen agent per stream, in one parallel batch. Stream 01 builds req-006, req-004, req-003, req-005, req-001, then req-009 in sequence, because each changes `path-rules.mjs`. Stream 02 builds req-002, then req-008. Stream 03 builds req-007, then req-010 / reason: inside each stream, every requirement changes a file the one before it changes.
- Decision (P3): shared files. Stream 02 owns the boot templates and the ship skill. Stream 03 edits only Resume Detection step 1 of the orchestrator skill and "Check for pending migrations" in `pipeline-reference.md`. Stream 01 edits only Fast Path text in the orchestrator skill. Each agent re-reads a shared file right before each **Edit**. The orchestrator bumps `planifest-framework/component.yml` to `0.33.0` at the join / reason: section ownership avoids lost writes.
- Decision (P3): each agent commits only its own paths and retries on a git index lock. Build-log lines go back to the orchestrator, which writes them / reason: three agents share one working tree.
- Stream 02 at-join: req-002 (`61dd3cd`) and req-008 (`b019664`) GREEN. Suites: req-002 69 passed, req-008 161 passed, each RED first.
- Deviation (P3, unclassified): `planifest-framework/templates/product.template.yml` header comment now names P7 and `set-product-release.mjs --create`, not the first multi-component P9. The file sat outside stream 02's list, but `--create` copies the comment into every new `product.yml`.
- Deviation (P3, unclassified): `set-product-release.mjs` validates `--product-id` and `--product-name` whenever they appear, and checks the `--create` arguments even when `product.yml` exists. It still exits 0 and changes nothing then. req-002 says `--create` has no effect in that case.
- Deviation (P3, unclassified): `set-product-release.mjs` refuses any `product.yml` link, dangling ones included. req-008 says it refuses a link that resolves elsewhere. With a real-path root, every link resolves elsewhere.
- Deviation (P3, unclassified): `set-product-release.mjs` names an unknown argument by its position (`argument N`), so no raw value reaches stderr.
- Stream 03 at-join: req-007 GREEN (`b056396`, suite 112 passed, RED first). Six `_done/` files returned by **Write**, `cmp`, and `git rm` (`c9c45e7`). req-010: five records written (`afd2378`), suite 42 passed and 3 failed until the exception lines below exist.
- Migration records (P3): `0003-archive-dirname.md`, `migrate-adoption-mode-and-about-md.md`, and `migrate-product-yml-component-paths.md` `applied` with 0/0. `migrate-0.31.0-rerun-setup-for-shell-write-guard.md` and `migrate-remove-context-mode-and-telemetry.md` `not applicable` by target check.
- Decision (P3): the adoption-mode scan counts three archived designs as compliant: `0000013` holds the value in frontmatter only, `0000034` is a Change Pipeline design with no adoption-mode line, and `0000016` adds a bracketed note after `standard-iterative` / reason: each records a valid mode or needs none.
Exception waiting (P3, human review): 0001-date-format.md: a read-only scan of plan/, docs/ and planifest-framework/ found about 506 dates outside DD MMM YYYY in 283 files, mostly YYYY-MM-DD in prose (e.g. plan/changelog/0000028-...-iteration-log-2026-08-08.md:12). The target clashes with the house YYYY-MM-DD date rule, so answering none (skipped) may be right (R-013, A-002).
Exception waiting (P3, human review): 0002-british-english.md: a read-only scan of plan/ and docs/ found about 870 American spellings in prose across 307 files, mostly "artifact"/"artifacts" (e.g. plan/changelog/0000028-...-iteration-log-2026-08-08.md:21).
Exception waiting (P3, human review): retroactive-release-tags.md: two release commits on main have no tag: v0.14.0 at 6c145b5 and v0.15.0 at 928f1d4. Tagging needs human confirmation of the mapping.
- Deviation (P3, unclassified): `gate-write` blocked the FR-007.10 `README.md` edit, because `design.md` Component Paths doesn't list `README.md`. The req-007 suite holds a comment in place of that check.
- Deviation (P3, unclassified): `test-0000005-framework-governance.sh` and its regression copy now expect migrations at the top level, no `_done/`, and a migrator that names `plan/_migrations/`.
- Deviation (P3, unclassified): `test-0000032-req-011-rerun-setup-migration.sh` now asserts `_done/` is absent, a `## Record` heading, and `plan/_migrations/` text.
- Deviation (P3, unclassified): `migrate-adoption-mode-and-about-md.md` and `migrate-product-yml-component-paths.md` said "archive it". Both now say "record the outcome", so no file tells an agent to move a migration (AC-007.1). req-007 doesn't list either file.
- Deviation (P3, unclassified): both new stream 03 suites wrap migration name lists in `# BEGIN/END retired-integrations` markers, so the 0000030 residue check passes.
- Deviation (P3, unclassified): stream 03 also edited `planifest-framework/project-operations.md`, which FR-007.10 requires.
- Decision (P3): add `./README.md` to the `design.md` Component Paths, then make the FR-007.10 README edit and restore its suite check / reason: req-007 requires the README change, and the path list missed it. This resolves the README deviation above. The check failed first, then passed.
- Exception waiting count after the stream 03 join: three. The req-010 suite now passes 45 of 45.
- Stream 01 at-join: req-006 (`cdc1a9d`), req-004 (`cf05b31`), req-003 (`cbdaba4`), req-005 (`67315b8`), req-001 (`76eead2`), and req-009 (`745961f`) GREEN, each RED first. New suites pass 23, 26, 35, 19, 99, and 101.
- Deviation (P3, unclassified): `test-0000032-req-006-outside-repository-pass.sh` lines 364 to 366 and its regression copy now expect exit 2 for a deleted cwd writing `src/a.js`. req-004 planned this at P1.
- Deviation (P3, unclassified): `resolveRoot` also returns `null` when the cwd walk stops where `realpathSync` fails and `CLAUDE_PROJECT_DIR` gives no root. ADR-006 names `null` only for a non-string cwd. The extra case keeps the spec's fail-open exit 0 there.
- Deviation (P3, unclassified): `workflows/fast-path.md` writes the scope record in a named sub-step at the end of step 1, not a new numbered step. Steps 5 and 6 keep the numbers that ADR-002, `scope.md`, and the execution plan cite.
- Deviation (P3, unclassified): the ratchet suites `test-0000016-pipeline-governance.sh`, `test-0000017-req-002-ratchet-approve.sh`, and both regression copies gained `unset CLAUDE_PROJECT_DIR`. The ratchet now reads that variable, so they failed inside a Claude Code session. They sit outside the req-005 file list.
- Deviation (P3, unclassified): `resolveTarget` returns `outside` for a path too long to judge, which keeps the existing warn-and-allow result. Both gates check the length limit before they call it. ADR-005 doesn't name this case.
- Deviation (P3, unclassified): the admitted-write notice reads `[Planifest] Fast Path: admitted '<relPath>' through plan/.fast-path-scope.`, shared by both hooks. req-001 gave `[planifest] gate-write: admitted ...` as an example.
- Decision (P3): leave orchestrator skill line 161 as it is / reason: it names part of the enforcement list, stays true, and line 172 points to the full list in `fast-path.md`.
- P3 join: all three streams at-join. `planifest-framework/component.yml` set to `0.33.0` with feature `0000035-write-gate-scope-and-path-hardening`. `run-tests.sh` exits 0: 88 feature suites and 31 regression suites pass. `stream-reconcile.mjs` exits 0, and `consistency-check.mjs` reports clean.
- Gate (P3): passed. Every requirement has a GREEN suite. Three exceptions wait for the human on the loop (req-010 migrations).
- Progress: P3 done at 2026-10-22T06:50:13Z: ten requirements built test first, 88 feature suites green, three migration exceptions waiting

### P4: Validate

| Field | Value |
|-------|-------|
| Start | `2026-10-22T06:53:00Z` |
| End | `2026-10-22T07:07:18Z` |
| Wall-clock | `858` |
| Streams | `n/a` (joined at P3) |
| Model tier | primary |
| Skills loaded | planifest-validate-agent, planifest-verify-by-execution |
| Agents spawned | `2` |
| MCP calls | `0` |
| Parallel task batches | `1` |
| Notes | CI has no lint, typecheck, or build step. Its checks are code and doc parity, `self-description-check.mjs`, `run-tests.sh`, and `test_setup.ps1`. Locally, `self-description-check.mjs` passes and `run-tests.sh` exits 0. PowerShell isn't installed here, so `test_setup.ps1` runs on CI only. No stream changed a PowerShell file. |

- Decision (P4): one agent checks semantic coverage for all ten requirements, and one agent verifies by execution, in one parallel batch / reason: CI already passes, and the two checks read different things.
- Verify by execution: 35 passed, 0 failed, 2 deferred, in `verification-report.md` (`788fdde`). Deferred: req-002 AC-3 to P7, and req-010 AC-010.1 to the human on the loop.
- Semantic coverage: 69 of 71 criteria covered, in `validation-report.md` (`96b34d4`). The two open criteria are the same two deferred ones. 19 test gaps closed with new tests, and no production code changed.
- P4 self-correct cycle 1 of 5: Check: req-004 suite. Error: `gate-write passes a cwd of 42 / "" / null` expected 0, got 2. Root cause: test bug, a non-string stdin cwd falls back to `process.cwd()`. Fix: a `resolveRoot` unit check and a shell-guard case. Result: pass.
- Backlog filed (P4): 0000140 (hook branch tests past the acceptance criteria).
- Decision (P4): at P7 the orchestrator reads the source ship skill at `planifest-framework/skills/planifest-ship-agent/SKILL.md`, not the installed copy / reason: the git-ignored copy under `.claude/skills/` predates req-002 and has no `set-product-release.mjs` step. Rerunning setup mid-run would rewrite this session's live hooks and skills.
- Decision (P4): the `resolveRoot` contract mismatch between its doc comment and req-004 goes to the P6 deviation review / reason: the P3 deviation already records the extra `null` case, and P6 brings req-004 and ADR-006 into line with the code.
- Gate (P4): passed. `run-tests.sh` exits 0 with 88 feature suites and 31 regression suites. No criterion failed. Two deferred criteria have named owners.
- Progress: P4 done at 2026-10-22T07:07:18Z: 69 of 71 criteria covered, 35 verified by execution, two deferred

### P5: Security

| Field | Value |
|-------|-------|
| Start | `2026-10-22T07:08:00Z` |
| End | `pending` |
| Wall-clock | `pending` |
| Streams | `n/a` |
| Model tier | primary |
| Skills loaded | planifest-security-agent |
| Agents spawned | `pending` |
| MCP calls | `0` |
| Parallel task batches | `pending` |
| Notes | No API, IaC, network surface, or new dependency. The review covers the write gates and the new script. |

- Decision (P5): two reviewers in one parallel batch. One covers the gate hooks (`path-rules.mjs`, `gate-write.mjs`, `shell-write-guard.mjs`, `ratchet-check.mjs`, the scope record). The other covers `set-product-release.mjs`, the sanctioned-scripts carve-out, and migration records. The orchestrator writes `security-report.md` from both / reason: the two areas share no code path except `resolveRoot`.
- Gates review: High. Two confirmed bypasses through **Write** alone. G-S01: `resolveTarget` resolves `..` physically, while Claude Code's **Write** collapses `..` as text, so `docs/L/../../src/a.js` passes `gate-write` and `ratchet-check` (regression from `main`). G-S02: the enforcement match lowercases only, while APFS folds `ſ` to `s`, so a record admits `.claude/ſettings.json`. Medium: `.github/workflows/planifest.yml` missing from the enforcement list (G-S03), plus predating items.
- Scripts review: Medium. Medium: the sanctioned sentence covers `promote-to-regression.sh` with any source (P-S09) and `setup.sh add-skill` (P-S10), and a forged `plan/_migrations/` record can stop a needed migration (P-S13). Low: `set-product-release.mjs` hard link, read race, non-atomic write, raw exceptions, unchecked manifest paths, and `CLAUDE_PROJECT_DIR` redirect.
- Decision (P5): fix in this feature, in three parallel agents split by file ownership. Agent 1 (gates): G-S01 dual verdict in `gate-write` and `ratchet-check`, G-S02 Unicode folding for enforcement matching, G-S03 list entry, and G-S11 escaping of targets in stderr, with req-003, req-009, ADR-004, ADR-005, and `fast-path.md` kept in step. Agent 2 (scripts): harden `set-product-release.mjs`, narrow the `Sanctioned scripts:` sentence to the invocations skill text uses, and bind `promote-to-regression.sh` sources to the tests folder, with req-008 and ADR-011 kept in step. Agent 3 (records): risk register entries and backlog entries for out-of-scope items / reason: both High findings break this feature's own acceptance intent, so the run can't ship them. Each fix then gets a fresh-context re-review.
- Records agent: R-021 (record spoofing), R-022 (self-attested outcomes), and R-023 (other sanctioned scripts) added. R-002, R-005, R-018, and R-020 updated (`7a84cbe`).
- Backlog filed (P5): 0000141 (surface suspect migration records), 0000142 (bind the `archive-current.mjs` root), 0000143 (`design.md` as a folder or FIFO fails open), 0000144 (Windows path forms escape the gate), 0000145 (hook commands use relative paths), and 0000146 (nearer root and null root without `CLAUDE_PROJECT_DIR`), in `7cf56cb`.
- Scripts fix: P-S03 to P-S08 in `a6b1cd1`, P-S10 in `02ca3c2`, and P-S09 in `eb09fc8`. Each new case RED first, then GREEN. The req-008 suite holds 248 assertions.
- Gates fix: G-S01 in `5a5ad24`, G-S02 in `f82f12d`, G-S03 in `3d8cb71`, and G-S11 in `f535ff2`. Each new case RED first, then GREEN. The reviewer's probes for G-S01 and G-S02 now exit 2.
- Deviation (P5, unclassified): P-S03 to P-S08 share one commit, because the fixes share functions and partial staging needs interactive git.
- Deviation (P5, unclassified): `test-regression-pack.sh` and its regression copy now use a fixture tree, because `PLANIFEST_REGRESSION_DIR` no longer redirects and sources must sit in `tests/`.
- Deviation (P5, unclassified): the G-S11 escaping also covers the admitted notice, the enforcement reason, the unresolvable reason, the too-long warning, and the shell guard's unresolvable reason. Otherwise a listed folder still lets a newline target forge a line.
- Deviation (P5, unclassified): `resolveTargetText` resolves a target below the cwd from the cwd's real path, so a link in the cwd's own path doesn't count as a hop.
- Deviation (P5, unclassified): `ratchet-check.mjs` moved its weakening check into `checkWeakening(...)`, which returns a verdict, so the hook can check two placements.
- Deviation (P5, unclassified): the req-005 checklist line still names `resolveTarget`. The hook now imports `resolveTargetBoth`, which wraps it. A new FR line explains the change, and the line itself stays unchanged.
- Backlog filed (P5): 0000147 (the `promote-to-regression.sh` temp file isn't link-checked).
- P5 fixes verified by the orchestrator: `run-tests.sh` exits 0 with 88 feature suites and 31 regression suites. `consistency-check.mjs` clean, run mode still `autonomous`.
