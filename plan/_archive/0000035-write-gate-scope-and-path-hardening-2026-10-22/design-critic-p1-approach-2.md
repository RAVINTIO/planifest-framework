# Design-Critic Verdict (approach 2, iteration 1)
**Phase:** P1
**Mode:** on
**Mechanical check:** clean
**Overall:** APPROVE

```
consistency-check: clean
```

The open item from iteration 3 is resolved. Hard Limit 8 gains a standing `Sanctioned scripts:` rule in both boot templates. req-002 now treats every script argument as untrusted. No critical or major finding remains. Five minor findings follow, and none blocks the gate.

req-002 holds six acceptance criteria. The limit is now 10 (commit c7e7642), so the count is not a defect. A split would not clearly help, because the extra criteria all test the one script and its carve-out.

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Each AC names an exit code, a file value, or a text check. Examples: req-002 lines 97 and 100 to 102, req-004 lines 51 to 58, req-007 lines 140 to 142. |
| 2 Traceability | pass | Each req has a `Source:` US on line 11. The 13 brief ACs (feature-brief lines 129 to 141) each map to a req AC. No story lacks a req. The boot-template AC on req-002 line 102 traces to US-002 through the carve-out. |
| 3 ADRs record real decisions | n/a | No ADRs exist at P1. req-002 lines 29, 60, and 84 commit P2 to an ADR for the script, its carve-out, and the sanctioned list. |
| 4 Consequences honest | n/a | No ADRs exist at P1. |
| 5 Scope boundaries | pass | scope.md lines 65 to 72 exclude work someone would plausibly build, such as seeding from `_done/` and relaxing the root-file gate. |
| 6 Risks specific and mitigated | pass | R-001 to R-020 are specific. New R-020 (risk-register line 39) covers the ungated script write, and each mitigation maps to a req-002 rule. See m2 for one overstated claim. |
| 7 NFRs measurable | pass | NFR-001 to NFR-005 (execution-plan lines 35 to 39) each give a number or a deterministic check. |
| 8 Internal consistency | pass | req-002 matches execution-plan lines 93 to 95 and scope.md lines 58 to 60. Stream 02 owns both templates (execution-plan line 81). See m4 and m5 for record gaps. |

## Prior findings (iteration 3)

| Prior finding | Status | Evidence |
|---------------|--------|----------|
| Major M1: `--root` and free-text arguments are unbounded | resolved | req-002 lines 114 to 130 add an Input Validation section. `--root` must equal the real path that `resolveRoot` returns, with a `planifest-framework/` check (lines 117 and 118). Each value has a full-match pattern and a length cap. A break exits 2, writes nothing, and never echoes the value (lines 127 to 129). Line 64 writes values only as double-quoted scalars. ACs on lines 100 and 101 test each rule and the newline injection. See m2. |
| Major M2: boot templates still ban every script | resolved | req-002 lines 66 to 84 add a `Sanctioned scripts:` sentence to Hard Limit 8 in `standard-boot.md` and `cursor-boot.md`. I confirmed both template lines (14 and 20). Every per-tool setup script (`.sh` and `.ps1`) takes its boot file from one of these two templates. The root `.gitignore` lists `CLAUDE.md` and `AGENTS.md` (lines 10 and 11), so editing only the templates is correct. AC line 102 adds a source check. See m3 and m4. |
| Minor m1: no risk covers the carve-out | resolved | R-020, risk-register line 39. |
| Minor m2: req-007 byte check has no mismatch outcome | resolved | req-007 lines 35 and 36: one rewrite, then an `Exception waiting` line, and neither file is removed. |
| Minor m3: req-004 "nearest existing folder" | resolved | req-004 lines 29 and 30 now say "the path where the walk stopped". |

### Sanctioned list check

req-002 lines 71 to 78 claim exactly seven scripts. I grepped `planifest-framework/skills/` and `planifest-framework/workflows/` for every script call. The writers are `archive-current.mjs`, `promote-to-regression.sh`, both `refresh-delete-boot-files` forms, and both `setup` forms, plus the new script. The other called scripts only read: `run-mode.mjs`, `product-version.mjs`, `consistency-check.mjs`, and `stream-reconcile.mjs` hold no file-write call. `skill-sync.sh` and `roo-code.sh` appear only as text, not as calls. The list is accurate.

## Findings (severity-ordered)

- [minor] req-002 lines 35 and 43: the `max-component-version` row runs `product-version.mjs`, which reads `product.yml` from disk.
  - Under `--create`, no `product.yml` exists yet, so `product-version.mjs` exits 4 and the row can't apply as written.
  - With `--component`, the derivation reads the old `components[]` list, not the new one.
  - Fix: state that the script derives the version from the new content before it writes. For example, it builds the new text, writes it to a temporary file under `{root}`, and runs `product-version.mjs --root` against that. Or it applies the same max-component rule in process. Add a suite case where `--component` changes the derived version.
- [minor] req-002 line 62 and risk-register R-020 line 39: "binds it to the repository root" overstates the rule. `resolveRoot` returns the nearest trusted folder holding `planifest-framework/` above cwd or `CLAUDE_PROJECT_DIR`, and the agent sets both. A `planifest-framework/` folder nested inside a component path, such as `.github/workflows/x/`, becomes the root. The write still lands under a path the gate already admits, so the risk is low. Fix: reword line 62 and R-020 to name the real bound. Optionally also reject a root that has a marked ancestor, and add a nested-marker suite case.
- [minor] req-002 line 69: the sentence names the scripts but doesn't say when they count. An agent could read it as leave to run `setup.sh` or `archive-current.mjs` at any time. Fix: say each script is sanctioned only when the skill step that names it runs it, with the arguments that step gives.
- [minor] req-002 line 83: this repo's own `CLAUDE.md` keeps the old Hard Limit 8 until setup runs again. No artifact reruns setup between P3 and P7, so this feature's own P7 meets the old text. The `archive-current.mjs` precedent shows this hasn't halted a run, but the gap is the one iteration 3 M2 described. Fix: add a P3 or P4 step that reruns `setup.sh claude-code` in this repo after stream 02 lands, or record the reliance on the precedent in the build log.
- [minor] design.md lines 23 and 67, and domain-glossary.md: the confirmed design still lists Hard Limit 8 as "changes go through **Write** or **Edit**" with no carve-out. Its Scope line omits the acceptance-criteria limit change in `consistency-check.mjs`, which ships on this branch (scope.md line 61). The glossary has no "sanctioned script" entry. Hard Limit 7 asks for the record to match. Fix: add a design.md note under Decisions that cites req-002 and scope.md line 61. Add a glossary entry for "Sanctioned script".
