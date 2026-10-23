# Design-Critic Verdict (iteration 3)
**Mode:** on
**Mechanical check:** clean (`node planifest-framework/scripts/consistency-check.mjs plan/current` printed `consistency-check: clean`, exit 0)
**Overall:** APPROVE

Gate: P2. Artifacts reviewed: `design.md` (reference), `feature-brief.md`, `execution-plan.md`, `requirements/req-001` to `req-011`, `adr/ADR-001` to `ADR-012`, `scope.md`, `risk-register.md`, and `domain-glossary.md`. The iteration 2 verdict, `design-critic-p2-iteration-2.md`, was read only to check each finding.

The verdict is APPROVE. All five iteration 2 findings are resolved, and the NFR-003 import allowlist now matches the code. A fresh review found two minor findings and nothing that would cause a wrong build, a security gap, or an untestable requirement. Every ADR passes items 3 and 4.

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Each criterion names an exit code, an output string, or a suite result. req-008 AC 1 names exit 2 and the "not a regular file" line from both hooks. req-009 AC 1 and AC 2 name exit 2 and exit 0 for named targets in named fixture states. req-004 AC 3 names `interactive` for three forms. req-010 AC 1 names the stub probe, and its Tests section names `[unset]`. req-011 Tests explains that a ratchet criterion can't hold `\n`, so the em dash case covers it. |
| 2 Traceability | pass | Every requirement carries `**Source:** US-00n` with its backlog ID. US-001 to US-011 map one to one in the `execution-plan.md` directory and in `feature-brief.md` `## Features`. ADR-008 to ADR-012 link their requirement in Context. ADR-001 to ADR-007 name req-001, req-002, and req-008 to req-011 in Context or Decision. No story in the brief lacks a requirement. |
| 3 ADRs record real decisions | pass | Each ADR lists three to five alternatives with a rejection reason, and none restates its decision. ADR-001 rejects a `stat` spawn, an npm package, and a copied `shown()`. ADR-003 rejects skipping the prefix shortcut, an outright block, shrinking `ALWAYS_PERMITTED_FILES`, and a second list. ADR-007 rejects a downstream-only Target, a hand run, a P3 run, a seeded record, and a fresh-install skip. ADR-011 rejects immediate moves, agent-written approvals, a cross-file ratchet, the warning alone, and a limit of 3. |
| 4 Consequences are honest | pass | Each ADR has at least one negative that would hurt. ADR-002 blocks every `src/` write for a project that links `design.md`. ADR-003 stops a Fast Path fix to `hooks/enforcement/CLAUDE.md`. ADR-005 says `planifest-refresh-setup` can't clear the PowerShell 5.1 warning. ADR-007 says P4 to P6 run on the old installed hooks. ADR-009 says zero config no longer means no loops. ADR-012 removes the feature from `git log --oneline`. |
| 5 Scope boundaries | pass | `scope.md` Out of Scope excludes work someone might build: the shell-guard parser entries, the remaining 0000035 hardening entries, renumbering, changing what setup copies, the critic default at `on`, and a drift check that compares more than `SKILL.md` or re-runs setup. ADR-005, ADR-006, ADR-009, and ADR-010 each reject an alternative because it crosses one of these lines. |
| 6 Risks specific and mitigated | pass | Each risk names a file, hook, or suite action. R-010 now names `./read-stdin.mjs` and says the req-008 suite owns the check. R-012 names the 14 double-encoded skills and backlog 0000164. R-019 names the end-of-P6 order. R-024 names the seven suites. |
| 7 NFRs measurable | pass | Each NFR carries a number or a deterministic check. NFR-001 is under 500 ms, timed in the req-008 suite. NFR-002 is under 1 s on a full fixture install. NFR-003 is a source check over five named files, with a named allowlist that matches the code (see Verified claims). NFR-004 is a 5-second limit. NFR-005 is 72 characters through `hooks/commit-msg`. req-010 adds a 2-second runner check. |
| 8 Internal consistency | pass | NFR-003, R-010, ADR-001, and req-008 Tests now state the same allowlist and name the req-008 suite as owner. The end-of-P6 setup run agrees across `design.md`, `scope.md` (added sub-bullet), req-001 FR-001.3 and FR-001.7, ADR-006 Decisions 7 and 8, ADR-007 Decisions 4 to 7, and R-019. req-008 and ADR-002 agree on every `lstatSync` route. req-006 and ADR-009 agree on the default and on every other key. Two minor wording gaps remain (see Findings). |

## Iteration 2 findings

| # | Iteration 2 finding | Status | Evidence |
|---|---------------------|--------|----------|
| 1 | [major] NFR-003, R-010, and ADR-001 omit `./read-stdin.mjs`, and no suite owns the five-file check | resolved | NFR-003, R-010, and ADR-001 "No new spawn" each list `node:` modules, `./path-rules.mjs`, and `./read-stdin.mjs`. req-008 Tests gains a bullet that runs the check over all five files and allows the `ratchet-check.mjs` spawn by name. NFR-003 and R-010 name the req-008 suite as owner. The imports in all five files match the allowlist. |
| 2 | [minor] ADR-001 says `ratchet-check.mjs` gains a `./path-rules.mjs` import | resolved | ADR-001 "One kept spawn" now says the hook already imports `./path-rules.mjs` at `:60` and gains no import. NFR-003 says the same. |
| 3 | [minor] ADR-001 latency consequence has no `ratchet-check.mjs` exception | resolved | The positive consequence now reads "with no new process start" and names the kept `git` spawn. |
| 4 | [minor] No case checks the rewrite list against both setup scripts | resolved | req-002 FR-002.6 gains a rewrite-list case that reads `setup.sh` `copy_skills()` and `setup.ps1` `Copy-PlanifestSkills`. ADR-005 Risks now names both scripts, as R-012 does. See the new minor finding on comparison order. |
| 5 | [minor] ADR-007 rationale paragraph breaks the Decision list | resolved | The paragraph is now indented under item 7, so items 8 and 9 continue the same list. |

## Findings (severity-ordered)

- [minor] `requirements/req-002-skill-drift-check.md` FR-002.6 rewrite-list case, and `adr/ADR-005-drift-check-warn-only-node-script.md` Risks: the case asserts that the script's list "matches both" setup scripts. The two scripts apply the rewrites in different orders. `setup.sh:80-84` runs `../standards/` before `../standards/reference/`. `setup.ps1:176-179` runs `../standards/reference/` before `../standards/`. Both orders give the same output, but an ordered comparison can't match both. Say that the case compares the from and to pairs as a set, ignoring order. The added sub-bullet can carry this.
- [minor] `adr/ADR-003-permitted-names-skip-enforcement-paths.md` Affected Components: "three enforcement targets, a case variant, and one path outside the list" reads as four enforcement targets. req-009 Tests lists three targets inside enforcement paths, one of which is the case variant `Claude.MD`, plus `src/a/CLAUDE.md`. Reword as "three enforcement targets, one a case variant, and one path outside the list".

Counts: 0 critical, 0 major, 2 minor.

## Verified claims

- `gate-write.mjs:24-25` imports `./path-rules.mjs` and `./read-stdin.mjs` only. `shell-write-guard.mjs:63-66` imports `node:os`, `node:path`, `./path-rules.mjs`, and `./read-stdin.mjs`. `em-dash-guard.mjs:41-43` imports `node:path` and `./read-stdin.mjs`. `path-rules.mjs:50-51` imports `node:fs` and `node:path`. `ratchet-check.mjs:53` imports `node:child_process`, `:60` imports `./path-rules.mjs`, `:61` imports `./read-stdin.mjs`, and `:150` spawns `git`. The NFR-003 allowlist covers all of them.
- `path-rules.mjs:105-107` lowercases in `norm()`, and `ALWAYS_PERMITTED_FILES` holds `claude.md` and `agents.md`. The req-009 case variant `Claude.MD` therefore meets the shortcut today, so the case tests the change. `FAST_PATH_ENFORCEMENT_PATHS` at `:478` holds `planifest-framework/hooks/` and `**/hooks/enforcement/`.
- `path-rules.mjs:759-797` holds `evaluateWrite`. The sentinel step, the `isAlwaysPermitted` shortcut at `:772`, `existsSync` at `:775`, and the fail-open `catch` match req-008, req-009, and ADR-002. `shown()` at `:120-130` ends with `escaped.slice(0, max)`.
- `ratchet-check.mjs:98` splits on `\r?\n`, and `:267` prints `removed: "${l}"` raw. `em-dash-guard.mjs:120` prints `relTarget` raw.
- `setup.sh:344-349` copies every `*.mjs` in `hooks/enforcement/`. `setup.sh:80-84` and `setup.ps1:176-179` hold the four rewrites in the orders noted above.
- The `Hard Limits? [0-9]+` scan over `planifest-framework/` without `tests/`, `docs/`, and `src/*/docs/` finds exactly the files req-005 lists. No migration file holds a bare citation.
- Exactly seven suites name an enforcement hook and hold no `unset CLAUDE_PROJECT_DIR` line, as req-010 lists. The two 0000035 suites that set the variable name no enforcement hook, so the suite rule doesn't catch them.
- The only commit subjects with a placeholder are `planifest-ship-agent/SKILL.md:157`, `:244`, and `:364`, and the quote at `planifest-orchestrator/SKILL.md:687`, as req-003 says.
- Nine source skills hold a `## Hard Limits` heading, as req-005 and ADR-010 say.
- The loop runner Toggle Protocol at `:26` reads an absent key as `off`. The toggles template sets `p0_completeness: off` explicitly. `docs/decisions-index.md:171` and `docs/architecture-overview.md:122` hold the "absent = all off" text req-006 names.
- Backlog entries 0000128, 0000161, 0000162, 0000164, 0000167, and 0000170 exist under `plan/backlog/`.
