# Recommendations - write gate scope and path hardening

**Skill:** [docs-agent](../../planifest-framework/skills/planifest-docs-agent/SKILL.md)
**Feature:** 0000035-write-gate-scope-and-path-hardening
**Version:** 0.33.0

> These are not blockers - they are opportunities for future work.

## Recommendations

| ID | Category | Priority | Component | Recommendation | Rationale | Effort |
|----|----------|----------|-----------|---------------|-----------|--------|
| REC-001 | process | high | planifest-framework | Add a split check to `planifest-spec-agent` and `planifest-design-critic`. When a requirement passes 3 acceptance criteria, ask whether it holds two concerns before any fold (backlog 0000139). | A P1 fix took req-002 to six criteria. The orchestrator planned a fold to meet the count, and the human on the loop had to ask for the split. The critic then named two more splits: req-001 to req-009 and req-007 to req-010. Today only `feature-brief.template.md` names the split rule. | small |
| REC-002 | testing | high | planifest-framework | Add a P3 or P4 check that runs each gate path case under **Write**-tool semantics as well as shell semantics (backlog 0000156). The **Write** tool collapses `..` as text, and the kernel resolves it physically. | ADR-005 and the req-003 criteria specified physical `..` resolution only. The P3 suites, the P4 coverage audit, and the P4 verification run all used that model. Only P5 found G-S01, a High regression from `main`. Risk R-019 already noted that the gate needs **Write** semantics. | medium |
| REC-003 | operations | high | repository | After the merge, rerun setup here with `planifest-refresh-setup`. Then add a check that the installed `.claude/skills/` copies match the source skills before a phase loads them (backlog 0000154). | The installed ship skill has no Step 5b, so P7 must read the source copy by hand (P4 decision). 0000033 REC-003 asked for the same rerun, and the gap came back. | small |
| REC-004 | process | high | planifest-framework | The human on the loop answers the three migration exceptions in the build log (backlog 0000153). Consider answering `skipped` for `0001-date-format.md`. | AC-010.1 stays open until then. `0001-date-format.md` targets `DD MMM YYYY`, which clashes with the house `YYYY-MM-DD` rule. The scans found about 506 dates and about 870 American spellings. Two release commits have no tag. | small |
| REC-005 | security | medium | planifest-framework | At the PR, the human on the loop reviews the two accepted Medium risks: G-S08 (self-authorised scope record) and P-S13 (forged migration records). Pick up backlog 0000152 and 0000141 next. | Both rest on accepted risk (R-005 and R-021), not on a fix. `.gitignore` hides a stale scope record from `git status`. Any agent can write a `plan/_migrations/` record, because `plan/` is always permitted. | medium |
| REC-006 | security | medium | planifest-framework | Plan the three other open Medium items: G-S04 Windows path forms (backlog 0000144), G-S05 nearer root without `CLAUDE_PROJECT_DIR` (backlog 0000146), and G-S12 `design.md` as a folder or FIFO (backlog 0000143). | Overall risk after P5 stays Medium because of these items. G-S04 needs a Windows host to prove. G-S05 and G-S12 predate this feature. | medium |
| REC-007 | testing | medium | planifest-framework | Clear `CLAUDE_PROJECT_DIR` once in `run-tests.sh`, and drop the per-suite `unset` lines (backlog 0000155). | At least 20 suites and regression copies now unset the variable one by one. The ratchet suites failed inside a Claude Code session until P3 added the line. A new suite that forgets it passes on CI and fails locally. | small |
| REC-008 | process | medium | planifest-framework | Give the boot template rule and the orchestrator rule different numbers, or cite each by name (backlog 0000157). Then state the file-write rule in the agent dispatch template. | `standard-boot.md` Hard Limit 8 is the **Write** or **Edit** rule. Orchestrator Hard Limit 8 is the build-log rule. A P1 fix agent changed four shared artifacts through a Python script. Every later prompt had to restate the rule by hand. | small |
| REC-009 | process | medium | planifest-framework | Keep a release near the three-story rule, or set a release budget (backlog 0000103). | This run carried ten stories in one wave (R-004) with 124 commits on the branch. P1 took 22,200 seconds over three critic iterations and a second approach. P5 needed 11 agents and two fix batches. | small |
| REC-010 | process | low | planifest-framework | At P1, check that every file a functional requirement names appears in the `design.md` Component Paths. | `gate-write` blocked the FR-007.10 `README.md` edit at P3, because Component Paths didn't list it. A P3 decision added the path and restored the suite check. | small |
| REC-011 | process | low | planifest-framework | Let `run-mode.mjs` accept the list-item form of the confirmation line, or have the template show the bare form (backlog 0000127). | Commit `38541a5` wrote the line as a list item, so the script printed `interactive`. A second P0 commit had to re-record the anchor, because a force push breaches a standing rule. | small |

## Deferred Items

| Scope Item | Recommendation | When to Address |
|-----------|---------------|-----------------|
| Shell-guard parser entries 0000105, 0000108, 0000115, and 0000116 (`scope.md` Out of Scope) | Decide the long-term shell-guard design first (backlog 0000119). | Next feature that touches `shell-write-guard.mjs` |
| A hook that enforces the post-P9 refusal (`scope.md` Out of Scope) | See backlog 0000112. | Next governance feature |
| G-S04: Windows path forms escape the gate | See backlog 0000144. | When a Windows host is available to prove the fix |
| G-S05 and G-S06: nearer root and null root without `CLAUDE_PROJECT_DIR` | See backlog 0000146. | After backlog 0000118 confirms the variable in a live session |
| G-S12: `design.md` as a folder or FIFO fails open | See backlog 0000143. | Next feature that changes `path-rules.mjs` |
| P-S13 and P-S14: forged or self-attested migration records (R-021, R-022) | See backlog 0000141. | Before the next migration ships with "Safe to skip: No" |
| A-001: `CLAUDE_PROJECT_DIR` reaches hooks, and hook commands use relative paths | See backlog 0000118 and 0000145. | One live Claude Code session covers both |
| Migrations carry no target project kind | See backlog 0000136. | Before the next framework-only migration |
| A migration progress file under `planifest-framework/migrations/_progress/` | See backlog 0000137. | Next change to the migrator |
| G-S08: a stale scope record stays hidden from `git status` (R-002, R-005) | See backlog 0000152. | Next Fast Path or gate change |
| AC-010.1: three migration exceptions wait for the human on the loop | See backlog 0000153. | At the 0000035 PR review |
| Installed skills under `.claude/` stay stale until setup reruns (P4 decision) | See backlog 0000154. | After the 0000035 merge |

## Tech Debt

| ID | Component | Description | Impact if Ignored | Suggested Fix |
|----|-----------|-------------|-------------------|--------------|
| TD-001 | planifest-framework | `ratchet-check.mjs` spawns `git status` from a hook (backlog 0000128). | The no-spawn source check can't cover the ratchet, and a slow `git` delays every guarded write. | Read the index state from `.git` files, as `path-rules.mjs` does. |
| TD-002 | planifest-framework | The ratchet misses criteria that hold a lone CR, U+2028, or U+2029 (backlog 0000148). | Removing such a line during a loop passes. | Match guarded lines with a pattern that accepts every line terminator. |
| TD-003 | planifest-framework | Three hook outputs still print raw text (backlog 0000149). | A crafted criterion or target can print control or bidirectional characters. | Route every output through `shown()`. |
| TD-004 | planifest-framework | `set-product-release.mjs` rewrites invalid UTF-8 and keeps NEL in key lines (backlog 0000150). | A line the script should leave alone changes. | Read and write bytes, and refuse NEL. |
| TD-005 | planifest-framework | `promote-to-regression.sh` leaves partial state and has a read race (backlog 0000151). | A bad manifest leaves the test copy behind. | Check the manifest first, and read the source through one descriptor. |
| TD-006 | planifest-framework | `archive-current.mjs` accepts a free `--root` (backlog 0000142). | A sanctioned script can move content to a place no gate judges. | Bind `--root` to the `resolveRoot` result, as `set-product-release.mjs` does. |
| TD-007 | planifest-framework | No check ties the setup wiring files to `FAST_PATH_ENFORCEMENT_PATHS` (backlog 0000130). | A new tool's wiring file can be listed in a scope record and unwire `gate-write`. | Add a suite that reads the setup scripts' target paths. |
| TD-008 | planifest-framework | Some hook branches have no test of their own (backlog 0000140). | A regression in those branches passes the suites. | Add one case per branch. |
| TD-009 | planifest-framework | `run-mode.mjs` rejects a list-item confirmation line (backlog 0000127). | Each new run can lose its `autonomous` anchor. | See REC-011. |
| TD-010 | planifest-framework | The ratchet blocks undoing an uncommitted criteria addition (backlog 0000129). | An `autonomous` run stops for a `.ratchet-approve` line. | Compare against the last commit as well as the file on disk. |
| TD-011 | planifest-framework | Suites inherit `CLAUDE_PROJECT_DIR` from the session, and each unsets it on its own (backlog 0000155). | A new suite fails locally and passes on CI. | See REC-007. |
| TD-012 | planifest-framework | No pipeline step checks hook path cases against **Write**-tool semantics (backlog 0000156). | A spec that assumes shell semantics ships a gate bypass, as G-S01 did. | See REC-002. |
| TD-013 | planifest-framework | Hard Limit 8 names two different rules in `standard-boot.md` and the orchestrator skill (backlog 0000157). | Agents and prompts cite the wrong rule. | See REC-008. |
