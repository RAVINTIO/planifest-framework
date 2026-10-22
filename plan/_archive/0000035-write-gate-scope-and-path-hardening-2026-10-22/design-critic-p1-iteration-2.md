# Design-Critic Verdict (iteration 2)
**Phase:** P1
**Mode:** on
**Mechanical check:** clean
**Overall:** REJECT

```
consistency-check: clean
```

The verdict rests on two major findings. One gap lets a Fast Path change unwire the hooks. One requirement contradicts a design constraint. Both are fixable in the requirement text.

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Each AC names an exit code, a file value, or a text check. Examples: req-001 lines 123 to 125, req-003 lines 67 to 69, req-007 lines 140 to 142. One test design is weak (m2). |
| 2 Traceability | pass | Each req has a `Source:` US on line 11. The 13 brief ACs (feature-brief lines 129 to 141) each map to a req AC. No story lacks a req, and each req holds 3 ACs. |
| 3 ADRs record real decisions | n/a | No ADRs exist at P1. req-002 line 27 and execution-plan line 91 commit P2 to an ADR for `set-product-release.mjs`. |
| 4 Consequences honest | n/a | No ADRs exist at P1. |
| 5 Scope boundaries | pass | scope.md lines 62 to 66 exclude work someone would plausibly build, such as seeding from `_done/` and relaxing the root-file gate. |
| 6 Risks specific and mitigated | pass | R-001 to R-019 are specific to this feature. R-005 records the self-authorisation as an accepted risk with the P0 citation. R-012, R-004, R-003, and R-006 now match the reqs. See m1 and m4 for residual wording defects. |
| 7 NFRs measurable | pass | NFR-001 to NFR-005 (execution-plan lines 35 to 39) each give a number or a deterministic check. NFR-004 names the `ratchet-check.mjs` exception and backlog 0000128. |
| 8 Internal consistency | fail | See M1 and M2. |

## Prior findings (iteration 1)

| Prior finding | Status | Evidence |
|---------------|--------|----------|
| Critical: mechanical check exits 1 | resolved | The check reports clean. Cross-feature references now read `0000032 ADR 004`, which also removes the P2 false-match hazard. |
| Major: enforcement list omits wiring files, and scope conflicts | partly resolved | req-001 lines 54 to 73 add the files that setup writes, and scope.md lines 49 and 65 name the additions. Two gaps remain (M1). |
| Major: scope record is self-authorisation | resolved | req-001 lines 78 to 83 and R-005 record the accepted risk with its P0 citation. A stderr notice is added. See m1. |
| Major: AC-007.3 conflicts with the autonomous no-record rule | resolved | req-007 FR-007.11 lines 121 to 125 and execution-plan line 86 say how P4 reports the open AC. |
| Major: req-002 claims the gate admits the P7 write | resolved, with a new defect | The false claim is gone. The script now writes `product.yml` to avoid the gate, which conflicts with Hard Limit 8 (M2). |
| Minor: NFR-004 narrows the no-spawn rule | resolved | execution-plan line 38 names the `git status` exception and backlog 0000128. |
| Minor: "the Fast Path commit deletes the record" | resolved | req-001 lines 94 and 96 remove it before commit and add a `.gitignore` line. build-log line 111 records the deviation. Line 113 adds a suite check. |
| Minor: enforcement matching case | resolved | req-001 line 72 and test case line 110. |
| Minor: R-012 against req-004 | resolved | R-012 line 31 now follows req-004 lines 23 to 28. |
| Minor: R-004, R-006, and R-003 claims | resolved | R-004 names three streams. R-006 says entries are not resolved through links (req-001 line 31). R-003 drops the warning claim. See m4. |
| Minor: glossary out of date | resolved | glossary lines 29, 57, and 58. |
| Minor: req-002 and req-007 Skill link and status | resolved | Both use `../../../planifest-framework/...` and `status: "draft"`. The same broken link remains in execution-plan line 5 (m5). |
| Minor: req-002 "touches nothing else" | resolved | req-002 lines 24 and 25 give the ship agent every `components[]` edit through `--component`. |
| Minor: req-004 `realpathSync` failure | resolved in text | req-004 lines 26 to 28. The test that covers it doesn't reach that path (m2). |

## Checks requested by the orchestrator

| Check | Result |
|-------|--------|
| Ratchet integrity after the script edit | pass. `git diff 6ea6d0e d6e33ab` removes no `- [ ]` line and no In Scope line. The only removed scope line is the old Out of Scope enforcement line, now line 65. |
| Confirmed design edited after confirmation | Commit `b464ead` changed only the ADR reference format on four lines. No decision changed. |
| Known deviation on record removal | Accepted. build-log line 111 records it, and AC-001.3 states the sharper rule. |
| Brief cross-feature references | feature-brief lines 64, 102, and 103 keep `ADR-NNN` with a hyphen. The checker doesn't scan the brief, so no false match follows today. |

## Findings (severity-ordered)

- [major] req-001 lines 54 to 73, scope.md line 49: `FAST_PATH_ENFORCEMENT_PATHS` still leaves two routes to unwire the hooks.
  - `.claude/settings.local.json` exists in this repo. Claude Code loads hooks from it, and its `disableAllHooks` key turns every hook off. A record that lists it admits the write today, since no entry covers it. The file is usually git-ignored, so the PR wouldn't show the change.
  - The per-tool setup scripts in `planifest-framework/setup/`, such as `claude-code.sh` and `windsurf.sh`, set the wiring file paths and write their content. They sit outside `hooks/`, `scripts/`, and the `setup.sh` basename rule. A Fast Path edit there unwires hooks at the next setup run.
  - Fix: add `.claude/settings.local.json` and `planifest-framework/setup/` to the list, the `fast-path.md` prerequisites, and scope.md. Add a suite case for each. Check the other tools for a local settings file of the same kind.
- [major] req-002 lines 23 and 43, execution-plan lines 24 and 91, scope.md line 52: the script writes `product.yml` "through Node, so no write gate judges it". design.md line 23 lists Hard Limit 8 as a constraint. Hard Limit 8 bans changing a project file through a script. The requirement gives the gate bypass as the reason, so it contradicts the constraint on its face. No artifact reconciles the two. 0000033 ADR 010 is cited as precedent, but it never addresses Hard Limit 8. Fix: state in req-002 why a framework script that a skill step runs falls outside Hard Limit 8, and require the P2 ADR to record that rule. Otherwise keep **Edit** and require P0 to list `./product.yml` in Component Paths.
- [minor] req-001 lines 81 and 82, R-005 line 24: the notice goes to stderr on exit 0. The claim that it "shows in the hook output the human on the loop sees" has no evidence. Claude Code keeps exit-0 hook output out of the main view. Fix: name the channel the human sees and how a suite checks it, or soften the claim in req-001 and R-005.
- [minor] req-004 line 48: `chmod 000` on the parent makes `existsSync` report the folder as missing. The walk then stops at the parent, and `realpathSync` succeeds there. The case never reaches the `realpathSync` failure it targets. It exits 2 anyway, through req-003 or the no-design block, so it passes whatever the code does. Fix: say how the walk decides a folder exists (only `ENOENT` counts as missing). Have the case assert that stderr names the error code.
- [minor] req-007 FR-007.1 lines 23 and 30: P3 moves six files and deletes `.gitkeep`, but the req names no method. Hard Limit 8 bars `mv` and `rm` on project files. Fix: name `git mv` and `git rm`, as `archive-current.mjs` uses. Also, FR-007.11 on line 119 sits before FR-007.10 on line 127, so renumber them.
- [minor] risk-register.md R-006 line 25: the mitigation says "Accepted with R-005", but the status reads `open`. Fix: set the status to `accepted`, or drop the acceptance claim.
- [minor] execution-plan.md line 5: the Skill link `../skills/planifest-spec-agent/SKILL.md` resolves to `plan/skills/` and is broken. Fix: use `../../planifest-framework/skills/planifest-spec-agent/SKILL.md`, as scope.md line 9 does.
