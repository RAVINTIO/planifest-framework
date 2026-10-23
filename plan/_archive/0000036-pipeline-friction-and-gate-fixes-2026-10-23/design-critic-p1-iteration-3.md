# Design-Critic Verdict (iteration 3)
**Mode:** on
**Mechanical check:** clean (`node planifest-framework/scripts/consistency-check.mjs plan/current` printed `consistency-check: clean`, exit 0)
**Overall:** APPROVE

Gate: P1. Artifacts reviewed: `design.md` (reference), `feature-brief.md`, `execution-plan.md`, `requirements/req-001` to `req-011`, `scope.md`, `risk-register.md`, and `domain-glossary.md`. No ADRs exist at P1, so items 3 and 4 don't apply. The ratchet hook freezes existing criteria and in-scope lines, so this review reads each criterion together with its Functional Requirements section and notes.

Every applicable rubric item has cited positive evidence. The remaining findings are all minor. None would cause a wrong build, a security gap, or an untestable requirement.

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | pass | Each criterion names an exit code, an output string, or a suite result. Examples: req-002 AC-002.1 (exit 0, 1, and 2), req-007 FR "Suite" (ratchet case, exit 0 for an added file and exit 2 for a removed criterion), req-008 AC 1 (exit 2 plus the "not a regular file" line from both hooks), req-009 AC 1 and AC 2 (exit 2 and exit 0 per fixture state), req-010 AC 1 (the `[unset]` probe), req-011 AC 2 (prefix of the escaped text). |
| 2 Traceability | pass | Every requirement carries `**Source:** US-00n`. US-001 to US-011 each map to one requirement in the `execution-plan.md` Functional Requirements Directory. The brief holds 31 criteria, which matches `design.md` Product Layer. No story is orphaned. |
| 3 ADRs record real decisions | n/a | No ADRs at P1. req-006 and req-008 each name the P2 ADR they need. |
| 4 Consequences are honest | n/a | No ADRs at P1. |
| 5 Scope boundaries | pass | `scope.md` Out of Scope excludes work someone might plausibly build: the shell-guard parser entries, moving the critic default to `on`, renumbering hard limits, changing what setup copies, and a drift check that re-runs setup. req-008 Out of scope names `check-design.mjs` and backlog 0000161. |
| 6 Risks specific and mitigated | pass | Each risk names a file, a hook, or a suite action. R-011 now cites the req-008 timed case. R-012 names the rewrite-and-strip rule and a suite that checks the rewrite list against both setup scripts. R-019 orders the setup re-run before the record write. |
| 7 NFRs measurable | pass | `execution-plan.md` NFR-001 to NFR-005 each carry a number and a named check. NFR-002 now measures a full fixture install of every source skill, so CI measures a real comparison. req-009 and req-011 name the req-008 timed case as their measurement. |
| 8 Internal consistency | pass | req-007 "Splitting while a loop is active" now matches `ratchet-check.mjs:238-248`. A split adds a file and lines only, and the hook returns early for a file it can't read, so a new requirement file passes. req-008, req-009, the glossary, and `design.md` agree on the `lstat` route and the kept `plan/` and `docs/` prefix shortcut. See the minor findings for wording gaps. |

## Iteration 2 findings

| # | Iteration 2 finding | Status | Evidence |
|---|---------------------|--------|----------|
| 1 | [major] req-007 split moves criteria while the ratchet is active | resolved | "The split step" now splits by addition only. "Splitting while a loop is active" defers each move until no loop is active or a human writes the approve line. A pending move goes to the build log in `autonomous`. The suite adds a ratchet case for both routes. Verified: `checkWeakening` (`ratchet-check.mjs:238-240`) returns when the current file can't be read, so a new file passes. |
| 2 | [minor] req-007 keep answer has no recorded place | resolved | A keep answer goes to a `Decision (P{N}): split step for req-NNN: keep` build-log line and a `Split step: keep` note in the requirement file. The critic row names both places. |
| 3 | [minor] req-001 FR-001.1 skill counts and `_version-policy.md` | resolved | FR-001.1 now says four skills omit `bundle_standards` and five set it to `[]`, and names them. It adds sub-path entries such as `library-standards/_version-policy.md`. Verified: the counts match each skill's frontmatter, and codegen, validate, and orchestrator name that file. |
| 4 | [minor] req-008 ordered list and the "not a regular file" line | partly resolved | The list now names the record state for each outcome. It states that outcomes 1, 2, 3, 4, and 6 carry the line. The suite still has no stale-record case (see the new finding below). |
| 5 | [minor] req-005 missed two `src/setup-hook-integration/docs/` files | resolved | "Files to change" lists both, and the suite scan covers `src/*/docs/`. Verified: the `Hard Limits? [0-9]+` matches in `planifest-framework/` (without `tests/`), `docs/`, and `src/*/docs/` equal the listed files and lines. |
| 6 | [minor] req-009, req-011, and R-011 timing with no test | resolved | req-009 and req-011 Non-functional now name the req-008 timed case and add no timing test. R-011 cites the same case. |
| 7 | [minor] NFR-002 timed case compares nothing on CI | resolved | NFR-002 and FR-002.6 now build a fixture install of all 21 source skills with the `setup.sh` rewrites and a `claude-code` marker. The no-`--root` case is no longer the measurement. |
| 8 | [minor] `scope.md` says "bytes" | partly resolved | The In Scope bullet gains a P1-correction sub-bullet with the rewrites and the BOM strip. The ratchet freezes the original bullet. The Out of Scope line "compare anything but `SKILL.md` bytes" still says bytes and isn't guarded. |
| 9 | [minor] Glossary "Always-permitted name" overstates the change | resolved | The row now limits the change to file names and says the `plan/` and `docs/` prefix shortcut stays. |
| 10 | [minor] Brief Integration Points omits `shell-write-guard.mjs` | resolved | The row now lists `shell-write-guard.mjs` as an importer. Verified at `shell-write-guard.mjs:65`. |

## Findings (severity-ordered)

- [minor] `requirements/req-008-non-regular-design-md.md` File-type check: the table sends a throwing `lstatSync` (`EACCES`) to the no-design route. The text then says every block "on the non-regular route" carries the "not a regular file" line. It doesn't say whether the `EACCES` route is part of that route. If it is, the line is false, because the file may be regular. State which line, if any, the `EACCES` route appends, and add a suite assertion for it.
- [minor] `requirements/req-008-non-regular-design-md.md` Tests: iteration 2 asked for a stale-record case, and the suite still has none. Outcome 3 (an ignored record plus the "not a regular file" line) has no test. Add a case with a folder at `design.md` and a record whose branch or head differs.
- [minor] `requirements/req-007-story-split-step.md` The split step: a yes answer adds a user story to the brief after the human on the loop confirmed `design.md`. `design.md` Product Layer lists every story and the criteria count. The requirement doesn't say whether the agent updates that list or records the split as a deviation. Name where the new story appears in `design.md`, or say that the gate summary carries it to the human on the loop for reconfirmation.
- [minor] `requirements/req-011-escaped-hook-output.md` AC 1 and Tests: AC 1 names `\n` for a removed criterion. `guardedLines` splits on `/\r?\n/` (`ratchet-check.mjs:98`), so a criterion line can never hold a newline. The AC reads as "or", so it stays testable. State in Tests that the ratchet case uses ESC and U+202E, and the em dash case adds `\n`.
- [minor] `scope.md` Out of Scope: "Having the drift check compare anything but `SKILL.md` bytes" still omits the rewrites and the BOM strip. This section isn't guarded by the ratchet. Change "bytes" to "text", as `design.md` says.
- [minor] `requirements/req-008-non-regular-design-md.md` Current behaviour: "`gate-write.mjs:40` ... reach this code through `evaluateWrite`" is off by one. `gate-write.mjs:39` calls `judgeWrite`, which calls `evaluateWrite` at `path-rules.mjs:820`. The conclusion holds. Correct the citation.

## Verified claims

- `path-rules.mjs:50` imports `lstatSync`. `:55`, `:72`, `:100`, `:118`, `:120-129`, `:422`, `:510`, `:521`, `:702`, `:745`, `:759`, `:772`, `:775`, and `:781` match the lines req-008, req-009, and req-011 cite.
- `scopeVerdict` (`:702-742`) runs absent, enforcement path, ignored, non-ASCII, listed, then not listed, as req-008 outcomes 1 to 6 describe.
- `FAST_PATH_ENFORCEMENT_PATHS` (`:478`) holds `**/hooks/enforcement/`, so req-009's `.claude/hooks/enforcement/AGENTS.md` target matches and `src/a/CLAUDE.md` doesn't.
- `ratchet-check.mjs:60` imports `shown`. `:255` wraps paths in `shown()`, and `:267` prints `removed` lines raw. `em-dash-guard.mjs:41-43` imports nothing from `path-rules.mjs`, and `:120` prints `relTarget` raw.
- `setup.sh:67-148` copies `SKILL.md`, applies the four `sed` rewrites at `:80-84`, and falls back to copy-all for an absent or empty key. `setup.ps1:176-178` applies the same rewrites.
- Bundle keys: six skills omit `bundle_templates` and three set `[]`. Four omit `bundle_standards` and five set `[]`. Only the orchestrator `SKILL.md` starts with `ef bb bf`.
- Seven suites name an enforcement hook file and hold no `unset CLAUDE_PROJECT_DIR`, exactly the seven req-010 lists. No suite with the unset places it after its first `node` call.
- `run-tests.sh` runs both loops in one shell after `set -uo pipefail`, so one `unset` covers both, as req-010 says.
- `test-0000033-req-003-gates-as-loops.sh:76-77`, loop runner `:27` and `:39`, and template `:7-9` and `:17` match req-006.
- `consistency-check.mjs:65-72` warns above 3 and fails above 10, and `feature-brief.template.md:27` holds the P0 split rule, as req-007 says.
