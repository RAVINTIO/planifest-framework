---
title: "Cross-model review (P6, iteration 1)"
summary: "Fresh-context REJECT-default review of the 0000038 feature diff."
status: "done"
---
# Cross-model review (P6, iteration 1)

**Verdict: REJECT**

| Field | Value |
|-------|-------|
| Feature | `0000038-token-efficiency-windows-shard` |
| Loop | `cross_model_review`, iteration 1, approach 1 |
| Reviewer model | `claude-opus-5-5` |
| Implementer model | `claude-sonnet-5-5` |
| Diff | `git diff main...HEAD` at `9c4e5432` |
| Suite | `run-tests.sh --quiet` exits 0. Feature suites 117 passed, regression 35 passed (152 of 152). |
| Counts | 0 critical, 2 major, 5 minor |

Two major findings block approval. Each one breaks a design constraint: a rule drops out of post-P0 context, and three test assertions narrow.

---

## What holds

- The moved text is byte-identical. Lines 239 to 588 and 768 to 818 of `SKILL.md` at `5966840` match the blocks in both reference files. `SKILL.md` minus those blocks differs from the new file only in the pointer section, Resume step 6d, two index rows, and the gate prompt.
- `SKILL.md` is 40,788 bytes, under 41,500.
- Quiet mode can't read a failed suite as passed. A non-zero exit, a signal, a `FAIL:` line with exit 0, and a capture error each count as failed. `INT` and `TERM` list the running suite. Default output is byte-identical, and CI still calls the runner without the flag.
- Each timed check makes one untimed warm-up call and one timed call. The 200 ms limit stays. The regression copies match the originals except for their paths.
- The model values hold only `sonnet` and `haiku` for Claude Code, and no tier changes. The P4 `haiku` dispatch reported `claude-haiku-5-5`.
- The size floor names all nine exempt roles and keeps the maker-checker split and the TDD steps. The after-P9 reset paragraph is byte-identical to the baseline.
- `setup.sh` rewrites reference links with portable `sed -i.bak`, after the reference copy and before standards are bundled. The installed orchestrator reference files match the source with the rewrite applied.
- New prose follows the repo style. Every em dash and semicolon in the diff sits in byte-identical moved text.

---

## Critical

None.

## Major

### M-1: rules for later phases now load only at P0

- `planifest-framework/skills/planifest-orchestrator/SKILL.md:250` says "Load neither file after P0".
- `planifest-framework/skills/planifest-orchestrator/references/phase-0-assess-and-coach.md:189` says "Repeat the skills inbox check at the start of every phase transition (P0→P1, P1→P2, etc.)".
- `phase-0-assess-and-coach.md:193` to `:209` hold the Capability Skills intake procedure, which runs for an inbox arrival at any phase transition.
- `SKILL.md:283` still says "see Capability Skills above" before P3. That section no longer exists in `SKILL.md`.
- `phase-0-assess-and-coach.md:55` says recommend-then-confirm "applies across all pipeline phases (P0–P9)". `SKILL.md:264` names the rule but no longer defines it.

Before 0000038, the orchestrator carried these rules in every phase. Now an agent past P0 doesn't load them. So the inbox check at each phase transition and the pre-P3 capability check lose their instructions. ADR-002 and the deviation review don't record this loss.

**Fix:** add a short pointer in `SKILL.md` that restates the per-transition inbox check and names `phase-0-assess-and-coach.md` `### Capability Skills` as the procedure. Narrow line 250 so the agent may read that one section after P0. The moved text stays byte-identical.

### M-2: three absence assertions no longer check `SKILL.md`

- `planifest-framework/tests/test-0000025-req-007-scope-lock-default-batch.sh:27` repoints `ORCH_SKILL` to the P0 file. The absence checks at `:131`, `:134`, and `:137` now read only that file.
- `planifest-framework/tests/test-0000033-req-008-p0-real-forks-only.sh:17` repoints `ORCH`. The whole-file `lacks` at `:75` now reads only the P0 file.
- `planifest-framework/tests/test-0000017-req-006-structured-discovery-pass.sh:38` asserts "No discovery pass needed" is absent from the Adoption Modes file only.
- Each regression copy under `planifest-framework/tests/regression/` has the same change.

Each check used to prove the whole orchestrator lacked a retired rule. Now a retired rule pasted back into `SKILL.md` passes. Every positive grep that moved still asserts the same thing. These negative greps assert less. The design says no test assertion weakens.

**Fix:** run each whole-file absence check against `SKILL.md` and the reference file together, for example on `cat "$ORCH" "$P0_REF"`.

## Minor

### m-1: req-009 timing proof is text-only

`planifest-framework/tests/test-0000038-req-001-stable-windows-timing.sh:47` to `:55` prove the req-009 change by string match. The `warm-up` check passes on the comment word at `test-0000032-req-009-shell-guard-path-parity.sh:301`. The req-003 and req-007 helpers get the behavioural stub test, but req-009 doesn't. Only the `-lt 200` check at `:76` covers the limit, and it needs only one match per file.

### m-2: docs overstate the link rewrite

`docs/architecture-overview.md:438` says setup "rewrites `../` links in those files, as it does for `SKILL.md`". Setup rewrites only `../standards/` and `../standards/reference/` in reference files (`planifest-framework/setup.sh:73` to `:75`, `planifest-framework/setup.ps1:199` to `:200`). The `SKILL.md` rewrite also covers `../templates/` and `../schemas/`.

### m-3: Windows PowerShell 5.1 adds a BOM to reference files

`planifest-framework/setup.ps1:201` writes with `Set-Content -Encoding UTF8`. Under Windows PowerShell 5.1 that adds a byte order mark before the `---` frontmatter. `SKILL.md` already had this at `:180`. Backlog 0000170 records a BOM that broke frontmatter once.

### m-4: the drift check skips reference files

`planifest-framework/scripts/skill-drift-check.mjs:9` compares `SKILL.md` only. About 37 KB of orchestrator rules now sit where a stale install goes unnoticed. This review filed backlog 0000235.

### m-5: cross-file "above" pointers in moved text

`phase-0-assess-and-coach.md:97` says "see Context Hygiene above", and `:226` says "(see above)" for the change protocol. Neither section sits in that file. The byte-identical rule keeps the wording, so a one-line note in each file header would help a reader.

---

## Pass condition

To approve, a later iteration must close M-1 and M-2 and show the full suite passing. The minor findings don't block.
