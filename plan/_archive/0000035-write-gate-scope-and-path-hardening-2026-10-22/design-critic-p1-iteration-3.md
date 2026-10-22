# Design-Critic Verdict (iteration 3)
**Phase:** P1
**Mode:** on
**Mechanical check:** clean
**Overall:** REJECT

```
consistency-check: clean
```

The verdict rests on two major findings, both about the `set-product-release.mjs` carve-out. The orchestrator's choice to have a carve-out is not under review. Its wording is. As stated, the carve-out's limits can't be enforced, and the rule text that agents load still forbids the step.

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Each AC names an exit code, a file value, or a text check. Examples: req-001 lines 136 to 138, req-002 lines 65 to 76, req-004 lines 51 to 58. |
| 2 Traceability | pass | Each req has a `Source:` US on line 11. The 13 brief ACs (feature-brief lines 129 to 141) each map to a req AC. No story lacks a req. |
| 3 ADRs record real decisions | n/a | No ADRs exist at P1. req-002 lines 29 and 60 commit P2 to an ADR for the script and its carve-out. |
| 4 Consequences honest | n/a | No ADRs exist at P1. |
| 5 Scope boundaries | pass | scope.md lines 62 to 69 exclude work someone would plausibly build, such as seeding from `_done/` and relaxing the root-file gate. |
| 6 Risks specific and mitigated | pass | R-001 to R-019 are specific. R-005 and R-006 now name the changelog channel and read `accepted`. See m1 for a missing carve-out risk. |
| 7 NFRs measurable | pass | NFR-001 to NFR-005 (execution-plan lines 35 to 39) each give a number or a deterministic check. |
| 8 Internal consistency | fail | See M1 and M2. |

## Prior findings (iteration 2)

| Prior finding | Status | Evidence |
|---------------|--------|----------|
| Major M1: enforcement list misses `.claude/settings.local.json` and `planifest-framework/setup/` | resolved | req-001 lines 57, 64, and 73 to 77 add both, plus `opencode.jsonc` and the whole `.github/hooks/` folder. Suite cases sit on lines 120 and 121. I checked every `planifest-framework/setup/*.sh`. Each wiring file it writes is on the list. The Codex adapter at `.agents/hooks/adapters/` falls under the `hooks/adapters/` pair. |
| Major M2: script write conflicts with Hard Limit 8 | partly resolved | req-002 lines 51 to 61 now state a carve-out and require the P2 ADR to record it. The carve-out's limits don't hold as written (M1 below), and the rule text stays unchanged (M2 below). |
| Minor m1: stderr notice channel | resolved | req-001 lines 90 to 92 say the notice reaches the agent and transcript. The Fast Path changelog lists the record paths, and line 126 adds a source check. R-005 and R-006 match. |
| Minor m2: req-004 `chmod 000` case misses its target | resolved | req-004 lines 26 and 27 define the walk by `statSync` error code. Lines 51 to 57 build a case that reaches `realpathSync` and assert `EACCES` on stderr. See m3 for one stale phrase. |
| Minor m3: req-007 moves name no method, FR order | resolved | req-007 lines 31 to 35 use **Write**, a byte check, and `git rm`. FR-007.10 (line 124) now precedes FR-007.11 (line 135). See m2. |
| Minor m4: R-006 status | resolved | R-006 reads `accepted`. |
| Minor m5: execution-plan Skill link | resolved | execution-plan line 5 now reads `../../planifest-framework/...`. |

Every iteration 1 finding was resolved at iteration 2, apart from the two that iteration 2 carried forward as M1 and M2.

## Checks requested by the orchestrator

| Check | Result |
|-------|--------|
| Carve-out stated precisely | fail. The limit "writes only `{root}/product.yml`" depends on `--root`, which the agent sets freely. The agent also passes free-text values that the script writes into YAML (M1). |
| Carve-out stated safely | fail. The carve-out removes the gate's judgement, so the script's own checks must replace it. Neither the root nor the argument values have a stated check (M1). |
| Carve-out recorded where agents read it | fail. Hard Limit 8 in the boot templates still bans "a script" outright (M2). |
| Ratchet integrity | pass. `git diff 1a686c0 30f206a` removes no `- [ ]` line and no In Scope line. scope.md line 52 stays, and line 58 adds the carve-out clarification. The only rewritten list line is Out of Scope line 68. |
| Known deviation and ADR reference format | Accepted as recorded in the build log. |

## Findings (severity-ordered)

- [major] req-002 lines 28 and 53 to 61, execution-plan line 92, scope.md line 58: the carve-out claims limits that the stated rules can't enforce.
  - `--root <dir>` takes any folder, and no default is given. The real-path check on line 61 only compares the target with `{root}/product.yml`. A call with `--root src/foo`, or one run from a subfolder, writes a `product.yml` there with no gate judging it. So "refuses any other path" is not true.
  - The agent passes `--feature-id`, `--product-id`, `--product-name`, and `--component` as free text, and the script writes them into YAML. A value that holds a newline adds arbitrary keys, such as a new `versionPolicy`. That breaks "changes only the named fields" and "the agent never passes content". req-002 has no Input Validation section, unlike req-001 lines 149 to 162.
  - Fix: require `--root` to be the repository root, for example a folder that `resolveRoot` returns or one that holds `planifest-framework/`. Otherwise exit 2. Give each argument a character pattern and a length limit, with exit 2 on any break. Add a suite case for each rule, as line 74 does for the link case.
- [major] req-002 lines 51 to 61, `planifest-framework/templates/standard-boot.md` line 14, `cursor-boot.md` line 20, and root `CLAUDE.md` line 14: Hard Limit 8 still reads "Don't use `>`, `tee`, `sed -i`, `cp`, a script, or an interpreter one-liner". The carve-out lives only in req-002, which P7 archives, and in a P2 ADR that agents don't load. After ship, a downstream ship agent meets a P7 step that its binding rule forbids. The project rules tell an agent with conflicting requirements to stop, so an `autonomous` release can halt at P7. The "covers no other script" limit is also never stated where an agent reads it. Fix: have req-002 add one sentence to Hard Limit 8 in both boot templates. It should name the sanctioned scripts, `archive-current.mjs` and `set-product-release.mjs`, and say no other script is covered. Add a source check to the req-002 suite. Both templates sit under the `planifest-framework/` component path.
- [minor] risk-register.md: no risk covers the carve-out itself. The script writes a root file with no gate judging it. R-016 and R-017 cover drift only. Fix: add a security risk for an ungated write through the script, with the M1 checks as its mitigation.
- [minor] req-007 lines 31 to 35: the byte check in step 2 has no stated outcome on a mismatch. Fix: say that P3 keeps the old file, removes nothing, and writes an `Exception waiting` line.
- [minor] req-004 line 29: "the nearest existing folder" no longer matches lines 26 and 27. The walk can now stop at a path that doesn't exist, such as `locked/inner/gone` on line 52. Fix: say "the path where the walk stopped".
