# Design-Critic Verdict (iteration 1)
**Phase:** P1
**Mode:** on
**Mechanical check:** 14 findings, exit 1 (verbatim below)
**Overall:** REJECT

```
consistency-check: 14 finding(s)
  ✖ requirements/req-001-fast-path-scope-record.md: references ADR-005 but no such file exists in adr/
  ✖ requirements/req-001-fast-path-scope-record.md: references ADR-004 but no such file exists in adr/
  ✖ requirements/req-001-fast-path-scope-record.md: references ADR-009 but no such file exists in adr/
  ✖ requirements/req-002-product-yml-in-p7.md: references ADR-010 but no such file exists in adr/
  ✖ requirements/req-002-product-yml-in-p7.md: references ADR-002 but no such file exists in adr/
  ✖ requirements/req-003-links-judged-by-real-target.md: references ADR-005 but no such file exists in adr/
  ✖ requirements/req-005-ratchet-check-shared-root.md: references ADR-005 but no such file exists in adr/
  ✖ requirements/req-005-ratchet-check-shared-root.md: references ADR-002 but no such file exists in adr/
  ✖ requirements/req-006-no-planted-root-marker.md: references ADR-005 but no such file exists in adr/
  ✖ requirements/req-007-migration-run-state.md: references ADR-005 but no such file exists in adr/
  ✖ design.md: references ADR-004 but no such file exists in adr/
  ✖ design.md: references ADR-009 but no such file exists in adr/
  ✖ design.md: references ADR-005 but no such file exists in adr/
  ✖ execution-plan.md: references ADR-005 but no such file exists in adr/
```

Every finding is a reference to another feature's ADR, such as `0000032 ADR-004` or `0000003-ADR-005`. The checker matches `ADR-\d{3}` with no feature prefix, so these are checker false positives (backlog 0000079 covers this limit). The skill still makes a non-zero exit an automatic REJECT.

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Every AC names an exit code, a file value, or a text check. Examples: req-001 lines 93 to 95, req-003 lines 66 to 68, req-007 lines 132 to 134. |
| 2 Traceability | pass | Each req has a `Source:` US (req-001 line 11 to req-007 line 11). All 13 brief ACs (feature-brief lines 129 to 141) map to a req AC. No story lacks a req. Each req holds 3 ACs. |
| 3 ADRs record real decisions | n/a | No ADRs exist at P1. |
| 4 Consequences honest | n/a | No ADRs exist at P1. |
| 5 Scope boundaries | pass | scope.md lines 51 to 57 exclude work someone would plausibly build, such as seeding from `_done/` and relaxing the root-file gate. |
| 6 Risks specific and mitigated | fail | R-005, R-006, and R-012 claim mitigations that no requirement specifies. R-004 describes a stream layout the plan doesn't use. See M2, m4, and m5. |
| 7 NFRs measurable | pass | NFR-001 to NFR-005 (execution-plan lines 35 to 39) each give a number or a deterministic check. See m1 for a scope gap. |
| 8 Internal consistency | fail | See M1, M3, M4, and m2. |

## Checks requested by the orchestrator

| Check | Result |
|-------|--------|
| Every P0 decision honoured | Mostly. The record life, fail-closed line, migration outcomes, and `not applicable` rule all appear in the reqs. The "Fast Path commit deletes the record" wording changed at P1 (m2). |
| At most 3 ACs per story | pass |
| Fail-open against fail-closed | req-003 lines 39 to 45 match design.md line 33. req-004 leaves one gap (m9). |
| Scope record lifecycle | Consistent across req-001, scope.md, and the brief, apart from m2. |
| Migration outcome values | req-007 FR-007.2 matches design.md line 32. AC-007.3 conflicts with the P1 autonomous decision (M3). |
| Who sets `product.yml` | The ship agent through a new script (req-002 line 24). The gate claim is wrong outside this repo (M4). |
| Scope record self-authorisation | Not mitigated (M2). |
| Path validation | req-001 lines 111 to 118 are strict and fail closed. Enforcement matching lacks a stated normalisation (m3). |
| Enforcement list against `fast-path.md` | The list covers every `fast-path.md` entry (lines 17 to 21). It omits hook wiring files and adds `.git/` (M1). |
| Git state without a spawn | Feasible. req-001 lines 35 to 40 read `HEAD`, loose refs, `commondir`, and `packed-refs`. Reftable and unborn branches make the state unreadable, so the gate fails closed. The branch and `HEAD` binding only stops staleness. It gives no security, because the agent that writes the record also reads both values. |

## Findings (severity-ordered)

- [critical] design.md, execution-plan.md, req-001, req-002, req-003, req-005, req-006, req-007: the mechanical check exits 1 with 14 unresolved ADR references. All are cross-feature references. Fix: resolve backlog 0000079 so the checker skips feature-prefixed references, or have the human on the loop accept the findings. Also note a P2 hazard. Once this feature writes its own `adr/ADR-004` or `adr/ADR-005`, the checker will match these references to the wrong file and report clean.
- [major] req-001 lines 53 to 60 and scope.md line 56: `FAST_PATH_ENFORCEMENT_PATHS` omits the hook wiring files that `setup.sh` writes, such as `.claude/settings.json` and `.cursor/settings.json` (setup.sh lines 360 to 453). With no design, the gate blocks those files today. A record that lists one would let a Fast Path change unwire `gate-write` itself. The list also adds `.git/` and the `hooks/enforcement/` segment pair beyond `fast-path.md`. That conflicts with scope.md line 56, which puts any change to the enforcement path set out of scope. Fix: decide the list in one place. Either add the wiring files and amend scope.md line 56 to name the additions, or keep the list to `fast-path.md` and file a backlog entry for the gap.
- [major] req-001 and risk-register.md R-005 line 24: the scope record lets the agent authorise itself. It can list any path outside the enforcement list, including `src/`, and write it with no human step. R-005's mitigations are the enforcement list, the branch and `HEAD` binding, and a later review. The binding only stops staleness, and the review is a hope rather than an action. R-006 line 25 also says entries are "exact paths or folder prefixes only", which still admits `src/`. Fix: add one control to req-001, such as requiring `plan/.orchestrator-active`, or a stderr line on every admitted write that names the record. If the P0 decision accepts the residual risk, state it in R-005 as accepted, with the design.md line 27 citation.
- [major] req-007 FR-007.4 line 71, FR-007.9 line 113, execution-plan.md line 86, and req-007 AC-007.3 line 134: in `autonomous`, a scan with findings writes no record and the migration stays pending. AC-007.3 and the brief AC on line 141 still need a record for all eight. The two can't both hold if any scan in this repo finds content. Fix: state in req-007 how AC-007.3 is judged when an exception is waiting. For example, P4 reports the AC as blocked on the human, or P3 escalates before P4.
- [major] req-002 line 22: "While `design.md` exists, `gate-write` admits the update" holds only when the design lists `./product.yml`. This repo's design does (design.md line 64), but a downstream design lists its own component paths. The script writes through Node, so `gate-write` never judges it, and the sentence describes no real control. Line 37 creates `product.yml` from the template and names no tool. A **Write** there is blocked downstream unless the design lists the file. Fix: have `set-product-release.mjs` handle creation as well, or state that P0 must list `./product.yml` in Component Paths. Then correct line 22. The new script is also an architectural choice beyond the P0 text, so P2 needs an ADR for it, as 0000033 ADR-010 did for `archive-current.mjs`.
- [minor] execution-plan.md NFR-004 line 38 and req-005 line 33: design.md line 21 and feature-brief line 97 bar a process spawn in any hook. NFR-004 narrows the check to `path-rules.mjs`, and `ratchet-check.mjs` keeps its `git status` call. Fix: name the exception in NFR-004 and cite backlog 0000128.
- [minor] req-001 line 71, design.md line 27, and feature-brief line 131: the design and brief say the Fast Path commit deletes the record. req-001 removes it before the commit, so no commit can delete it. The P1 decision on execution-plan.md line 87 records this, but design.md and the brief still carry the old wording (Hard Limit 7). Nothing stops a mid-change `git add -A` from committing the record. Fix: add `plan/.fast-path-scope` to `.gitignore`, which is always permitted, and add a suite check. Cite the ship skill line 224 as the precedent for `rm -f` on a marker, given Hard Limit 8.
- [minor] req-001 lines 30 and 60: the 0000009-ADR-005 normalisation is stated for record paths only. The req doesn't say enforcement matching lowercases the real target. On a case-insensitive macOS volume, `Planifest-Framework/Hooks/x.mjs` must still match. Fix: state it and add a suite case.
- [minor] risk-register.md R-012 line 31: the mitigation blocks a repo-relative target when no marker is found. req-004 lines 23 and 24 take the nearest existing folder as the root instead. Fix: align R-012 with req-004, or add the rule to req-004.
- [minor] risk-register.md R-004 line 23, R-006 line 25, and R-003 line 22: R-004 says one stream per requirement, but the plan has three streams and stream-01 holds five reqs (execution-plan line 79). R-006 says each entry is judged by its real target, which req-001 never specifies. R-003 says the migration text warns of six pending migrations, which req-007 never specifies. Fix: align each mitigation with a requirement or remove the claim.
- [minor] domain-glossary.md lines 29, 57, and 59: the hop limit entry says no number exists, but req-003 line 32 sets 40. The "Resolution error" and "Migration count" notes are open, but req-003 line 42 and req-007 lines 23 to 29 settle them. Fix: update the glossary.
- [minor] req-002 line 9 and req-007 line 9: the Skill link `../skills/planifest-spec-agent/SKILL.md` resolves under `plan/` and is broken. The other reqs use `../../../planifest-framework/skills/...`. req-002 line 4 reads `status: "active"` while the others read `draft`.
- [minor] req-002 line 23: the update "touches nothing else", yet it may edit `components[]` when a component changes. The script has no option for that. Fix: name who edits `components[]`, or drop the clause.
- [minor] req-004 line 25: `resolveRoot` never throws and returns `null` only for a bad `cwd`. The req doesn't say what happens when `realpathSync` on the nearest existing folder fails, for example with `EACCES`. Under design.md line 33, that error inside the root should block. Fix: state the result.
