---
title: "Cross-model review (P6, iteration 2)"
summary: "Fresh-context REJECT-default re-review of the 0000038 feature diff after the iteration 1 fixes."
status: "done"
---
# Cross-model review (P6, iteration 2)

**Verdict: REJECT**

| Field | Value |
|-------|-------|
| Feature | `0000038-token-efficiency-windows-shard` |
| Loop | `cross_model_review`, iteration 2, approach 1 |
| Reviewer model | `claude-opus-5-5` |
| Implementer model | `claude-sonnet-5-5` |
| Diff | `git diff main...HEAD` at `51c49672` |
| Iteration 1 fix commit | `78430f9` |
| Suite | `run-tests.sh --quiet` exits 0. Feature suites 117 passed, regression 35 passed (152 of 152). |
| Counts | 0 critical, 1 major, 2 minor |

One major finding blocks approval. The M-1 fix covers three cross-phase rules from the moved Phase 0 block. Two more cross-phase rules sit in that block, and the new pointer now forbids reading them after P0.

---

## Iteration 1 findings

| ID | Status | Evidence |
|----|--------|----------|
| M-1 | Partly fixed | `SKILL.md:250` to `:257` now re-reads `### Capability Skills` at each transition and before P3, names recommend-then-confirm, and explains the "above" cites. `SKILL.md:290` names the reference file. Two other cross-phase rules stay unreachable. See M-1 below. |
| M-2 | Fixed | The absence checks in `test-0000025-req-007-scope-lock-default-batch.sh:135` to `:141`, `test-0000033-req-008-p0-real-forks-only.sh:77`, and `test-0000017-req-006-structured-discovery-pass.sh:38` to `:41` read `SKILL.md` and the reference files together. The regression copy of the 0000017 suite matches. The other two suites have no regression copy. Every other repointed negative check reads a section that moved whole, so each is as strong as before. |
| m-1 | Fixed | `test-0000038-req-001-stable-windows-timing.sh:50` strips comment lines and `:56` counts code `spawnSync` calls. The `main` version has one such call, so the check now fails on the old code. |
| m-2 | Fixed | `docs/architecture-overview.md:438` now states each rewrite set correctly. |
| m-3 | Fixed | `setup.ps1:180` and `:201` write with `WriteAllText` and a no-BOM `UTF8Encoding`. Both paths are absolute. `$ProjectRoot` comes from `$MyInvocation.MyCommand.Path` at `setup.ps1:64` to `:65`, so `$destDir` and `$destRef` are full paths and the .NET working directory doesn't matter. |
| m-4 | Filed | Backlog `0000235-drift-check-skips-skill-reference-files` exists. |
| m-5 | Fixed | `SKILL.md:255` maps each cross-file "above" to `SKILL.md`. |

---

## What holds

- The moved blocks are byte-identical. Lines 239 to 588 of `SKILL.md` at `5966840` (33,261 bytes) sit whole in `phase-0-assess-and-coach.md`. Lines 768 to 818 (4,673 bytes) sit whole in `adoption-modes.md`. The fix commit doesn't touch either reference file.
- `SKILL.md` is 41,281 bytes, under 41,500. The margin is now 219 bytes.
- The full quiet suite passes 152 of 152.

---

## Critical

None.

## Major

### M-1: two per-gate rules still load only at P0

- `planifest-framework/skills/planifest-orchestrator/references/phase-0-assess-and-coach.md:183` says "Re-evaluate and update the `## Skill Map` section at each phase gate before proceeding to the next phase".
- `phase-0-assess-and-coach.md:254` to `:257` say that in interactive mode, each phase gate the human confirms appends `Gate accepted: P{N} ({ISO-8601 timestamp})` to the build log.
- `planifest-framework/skills/planifest-orchestrator/SKILL.md:257` says "Read nothing else from either file after P0".

Neither rule appears anywhere in `SKILL.md`. No other skill or standard carries them. Before 0000038, every phase held both rules. Archived build logs, such as 0000033, record `Gate accepted:` lines, and 0000012 ADR-005 defines them. After this change, an orchestrator at the P1 to P6 gates neither refreshes the Skill Map nor writes the gate-accepted line. The pointer at `SKILL.md:252` lists three rules, so it now states that only three rules apply after P0.

**Fix:** add both rules to the pointer at `SKILL.md:252` to `:257`, and make the count match. For example, "At each phase gate, update `## Skill Map` in `design.md`. In interactive mode, also append `Gate accepted: P{N} ({timestamp})` to the build log." Add positive greps to `test-0000038-req-004-phase-scoped-orchestrator.sh`. The 219-byte margin is tight, so cut wording elsewhere in the pointer if needed. The moved text stays byte-identical.

## Minor

### m-1: the recommend-then-confirm rule is named but not reachable

`SKILL.md:254` says the recommend-then-confirm rule in `### How you coach` applies in every phase. `SKILL.md:257` then forbids reading that section after P0. The rule's format and its "one decision per message" clause sit only in `phase-0-assess-and-coach.md:47` to `:55`. A post-P0 agent sees the rule's name without its content. Either allow a re-read of `### How you coach`, or restate the rule in one sentence.

### m-2: the pointer counts its own rules

`SKILL.md:252` says "Three rules". The third bullet at `:255` is a reading note, not a rule. A fixed count also goes stale once M-1 adds rules. Drop the number.

---

## Pass condition

To approve, a later iteration must close M-1 and show the full suite passing with `SKILL.md` under 41,500 bytes. The minor findings don't block.
