# Design-Critic Verdict (iteration 2)
**Mode:** on
**Mechanical check:** clean (`node planifest-framework/scripts/consistency-check.mjs plan/current` printed `consistency-check: clean`, exit 0)
**Overall:** REJECT

Gate: P2. Artifacts reviewed: `design.md` (reference), `feature-brief.md`, `execution-plan.md`, `requirements/req-001` to `req-011`, `adr/ADR-001` to `ADR-012`, `scope.md`, `risk-register.md`, and `domain-glossary.md`. The iteration 1 verdict, `design-critic-p2.md`, was read only to check each finding.

The verdict is REJECT for one reason. The fix to NFR-003 swapped one false claim for another. NFR-003, R-010, and ADR-001 now say the changed hooks import only `node:` modules and `./path-rules.mjs`. Four of those hooks import `./read-stdin.mjs` today, and this feature keeps that import. A suite built from that text fails on unchanged code, as in iteration 1. The fix is one phrase in three places. Every other iteration 1 finding is resolved, and every ADR passes items 3 and 4.

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Each criterion names an exit code, an output string, or a suite result. Examples: req-008 AC 1 names exit 2 and the "not a regular file" line from both hooks. req-004 AC 3 names `interactive` for three forms. req-010 AC 1 names `[unset]` through the stub probe. The ADRs add no criterion. |
| 2 Traceability | pass | Every requirement carries `**Source:** US-00n` with its backlog ID, and US-001 to US-011 map one to one in the `execution-plan.md` directory and in `feature-brief.md` `## Features`. ADR-008 to ADR-012 link their requirement in Context. ADR-001 to ADR-007 name req-001, req-002, and req-008 to req-011 in Context or Decision. |
| 3 ADRs record real decisions | pass | Each ADR lists three to five alternatives with a rejection reason, and none restates its decision. ADR-002 rejects an `EISDIR` catch, `statSync`, fail-open on a throwing `lstatSync`, a blanket block, and a worker thread. ADR-006 rejects manifest-based sets, a fallback fix, per-release migrations, a blanket rule, and no rule. ADR-007 now also rejects a P3 run, with the reason that P4 to P6 can change a setup-delivered file. |
| 4 Consequences are honest | pass | Each ADR has at least one negative that would hurt. ADR-002 blocks every `src/` write for a project that links `design.md`. ADR-005 says `planifest-refresh-setup` can't clear the PowerShell 5.1 warning. ADR-007 says P4 to P6 run on the old installed hooks. ADR-012 removes the feature from `git log --oneline`. |
| 5 Scope boundaries | pass | `scope.md` Out of Scope excludes work someone might build: the shell-guard parser entries, the critic default at `on`, renumbering, changing what setup copies, and a drift check that re-runs setup. ADR-003, ADR-006, and ADR-009 each reject an alternative because it crosses one of these lines. |
| 6 Risks specific and mitigated | pass | Each risk names a file, hook, or suite action. R-012 now names the 14 double-encoded skills and backlog 0000164. R-019 names the end-of-P6 order. R-010 inherits the NFR-003 defect (see the major finding). |
| 7 NFRs measurable | fail | NFR-001, NFR-002, NFR-004, and NFR-005 each carry a number and a named check. NFR-003 names a deterministic check, but its target fails on kept code. `gate-write.mjs:25`, `shell-write-guard.mjs:66`, `ratchet-check.mjs:61`, and `em-dash-guard.mjs:43` each import `./read-stdin.mjs`. |
| 8 Internal consistency | fail | NFR-003 and R-010 now agree with ADR-001 on the `ratchet-check.mjs` spawn. All three carry the same false import claim. NFR-003 also says a suite checks five files, ADR-001 assigns that check to the req-008 suite, and req-008 Tests checks `path-rules.mjs` only. Every other decision checked agrees across requirements and ADRs (see Verified claims). |

## Iteration 1 findings

| # | Iteration 1 finding | Status | Evidence |
|---|---------------------|--------|----------|
| 1 | [major] NFR-003, R-010, and ADR-001 forbid the kept `git` spawn and local imports | partly resolved | The spawn part is resolved. NFR-003, R-010, and ADR-001 "One kept spawn" allow the `ratchet-check.mjs:150` spawn by name and cite backlog 0000128. The local-import part is not resolved. The new allowlist omits `./read-stdin.mjs` (see the major finding). ADR-001's positive consequence "with no process start" still has no `ratchet-check.mjs` exception, though its Risks section names the spawn. |
| 2 | [major] ADR-005 and A-001 claim no false drift under PowerShell 5.1 | resolved | ADR-005 Context and Consequences name the double-encoding, the 14 skills, and backlog 0000164. The positive consequence now limits the claim to `setup.sh` and PowerShell 7. A-001 and R-012 agree. I counted 15 non-ASCII source skills, with only the orchestrator holding a byte order mark. |
| 3 | [minor] ADR-002 omits the `chmod 000` bypass | resolved | ADR-002 Decision "Kept bypass" and Risks name it. Backlog 0000162 exists. |
| 4 | [minor] ADR-004 says a missing import exits 0 | resolved | ADR-004 Negative now says Node exits 1, which Claude Code treats as non-blocking. |
| 5 | [minor] ADR-009 says setup never writes `planifest-overrides/` | resolved | The setup row now says setup writes `setup-config/{tool}.md` but never `loop-toggles.yml`. |
| 6 | [minor] ADR-003 says no entry matches below `plan/` today | resolved | ADR-003 Risks now says the gap exists today and the feature leaves it open. |
| 7 | [minor] ADR-010 miscounts the Hard Limits lists | resolved | ADR-010 Context lists ten sources. Decision says the set is open and how a new source gets its name. req-005 matches. |
| 8 | [minor] ADR-012 miscounts the suite files | resolved | ADR-012 Affected Components names three suites, two regression copies, and five files. |
| 9 | [minor] ADR-005 treats 0000035 ADR 001 as binding on scripts | resolved | ADR-005 Context cites `run-mode.mjs:52` and chooses no spawn on its own grounds. Related ADRs marks 0000035 ADR 001 as related-to. |
| 10 | [minor] ADR-006 and ADR-007 don't order the setup run | resolved | ADR-006 Decisions 7 and 8 and ADR-007 Decisions 4 to 7 move the run to the end of P6 and repeat it before the P9 push. `design.md`, `scope.md`, req-001 FR-001.3 and FR-001.7, and R-019 agree. |
| 11 | [minor] req-007 and the boot file disagree on who writes `.ratchet-approve` | resolved | req-007 states the rule the skills will carry, cites 0000017 ADR 001 and ADR-011, and names the conflict under backlog 0000167. |
| 12 | [minor] req-005 Suite wording reads as excluding `docs/` | resolved | req-005 and ADR-010 now read "scans `planifest-framework/` without `tests/`, and also scans `docs/` and `src/*/docs/`". |
| 13 | [minor] Glossary omits links and some Hard Limits lists | resolved | "Non-regular file" names a symbolic link. "Hard limit" names the ship agent, migrator, and loop runner. |

## Findings (severity-ordered)

- [major] `execution-plan.md` NFR-003, `risk-register.md` R-010, and `adr/ADR-001-stack-unchanged-node-built-ins-no-spawn.md` Decision "No new spawn": each says the changed hooks import only `node:` modules and `./path-rules.mjs`. `gate-write.mjs:25`, `shell-write-guard.mjs:66`, `ratchet-check.mjs:61`, and `em-dash-guard.mjs:43` import `./read-stdin.mjs`, and no requirement removes it. A suite built from that allowlist fails at P4 on unchanged code. A fix loop could then remove a working import. Add `./read-stdin.mjs` to the allowlist in all three places, or reword it as "no import outside `node:` and the existing `./` modules". Also name the suite that owns the five-file check. ADR-001 says the req-008 suite, but req-008 Tests checks only that `path-rules.mjs` imports no `node:child_process`. Add the five-file check to req-008 Tests, or point NFR-003 and ADR-001 at the suite that holds it.
- [minor] `adr/ADR-001-stack-unchanged-node-built-ins-no-spawn.md` Decision "One kept spawn": "It adds one import to that hook, `./path-rules.mjs`." `ratchet-check.mjs:60` already imports `shown` and five other names from `./path-rules.mjs`, as ADR-001's own Context says. Say the hook gains no new import.
- [minor] `adr/ADR-001-stack-unchanged-node-built-ins-no-spawn.md` Consequences: "Hook latency stays bounded by file-system calls, with no process start" still has no exception for `ratchet-check.mjs`. The Risks bullet names the spawn, so a reader can reconcile them. Add "except the existing `git` spawn in `ratchet-check.mjs`".
- [minor] `requirements/req-002-skill-drift-check.md` FR-002.6, `risk-register.md` R-012, and `adr/ADR-005-drift-check-warn-only-node-script.md` Risks: R-012 promises a suite that asserts the script's rewrite list matches `setup.sh` and `setup.ps1`. ADR-005 says `setup.sh` only. FR-002.6 has no such case. It asserts the tool map against `setup/{tool}.sh`, but not the rewrite list. The fixture cases apply "the `setup.sh` `sed` expressions" without saying whether the suite reads them from `setup.sh` or hardcodes them. If they're hardcoded, a fifth rewrite in setup passes the suite. Add a case that reads the rewrites from `setup.sh` and `setup.ps1` and compares them with the script's list, and align ADR-005 with R-012.
- [minor] `adr/ADR-007-rerun-setup-migration-targets-framework-source.md` Decision: the rationale paragraph sits between items 7 and 8, so the list breaks and item 8 renders as a new list. Move the paragraph after item 9, as ADR-006 does.

Counts: 0 critical, 1 major, 4 minor.

## Verified claims

- `ratchet-check.mjs:53` imports `execFileSync` from `node:child_process`, and `:150` calls `execFileSync("git", ["status", ...])`. `:60` imports `shown` from `./path-rules.mjs`, `:255` routes paths through it, and `:267` prints each removed criterion raw.
- `em-dash-guard.mjs` imports only `node:path` and `./read-stdin.mjs`, and `:120` prints `relTarget` raw. `path-rules.mjs` imports only `node:fs` and `node:path` and runs no top-level code, so importing it from `em-dash-guard.mjs` adds no side effect.
- `shown()` at `path-rules.mjs:120-130` escapes through `CONTROL_RE` and ends with `escaped.slice(0, max)`. `:772` holds the `isAlwaysPermitted` shortcut, and `:774-782` hold `existsSync`, then `readFileSync` with a fail-open `catch`.
- `run-mode.mjs:60` sets `LINE_PREFIX`. `:134` filters with `startsWith`, and `:154-155` match `-` and `+` followed directly by the prefix, as req-004 says.
- `planifest-ship-agent/SKILL.md:157`, `:244`, and `:364` hold the three `{feature-id}` subjects. `:207` and `:354` pass the ID as a second `-m`. `planifest-orchestrator/SKILL.md:687` quotes the P9 marker subject.
- The loop runner Toggle Protocol reads an absent key as `off`, and its `autonomous` list names the five keys ADR-009 cites.
- `setup.sh:80-85` applies the four `sed` rewrites. `setup.ps1:175` reads with `Get-Content -Raw` and no `-Encoding`, and `:180` writes with `-Encoding UTF8`.
- 21 source skills hold a `SKILL.md`. 15 hold non-ASCII text. Only `planifest-orchestrator/SKILL.md` starts with `ef bb bf`, so 14 install double-encoded under PowerShell 5.1, as ADR-005 says.
- 25 suite files mention `CLAUDE_PROJECT_DIR` and 21 hold an `unset` line. Exactly the seven files req-010 lists name an enforcement hook and hold no `unset` line.
- Backlog entries 0000128, 0000161, 0000162, 0000164, 0000167, and 0000170 exist under `plan/backlog/`.
