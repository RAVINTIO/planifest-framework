# Cross-model review: 0000037-green-ci-before-ship (end of P6)

**Verdict: REJECT.** One major finding blocks approval. The shipped held-back rule contradicts req-003 and ADR-003, and neither artifact was amended. Every other requirement is met, and the full suite passes.

## Models

| Role | Model id |
|------|----------|
| Implementing agents | `claude-sonnet-5-5` |
| Cross-model reviewer | `claude-opus-5-5` |

## Scope and method

- Diff reviewed: `git diff c8b1036..HEAD`, 167 files, 9099 insertions and 278 deletions.
- Rubric: REJECT by default. An item passes only with evidence.
- Loop format: `planifest-loop-runner`, one review pass, report only. This file is the record.
- Requirements: req-001 to req-011 with their `Amended` lines. ADRs: ADR-001 to ADR-014.

## Commands run

| Command | Result |
|---------|--------|
| `bash planifest-framework/tests/run-tests.sh` | Exit 0. Feature suites 109 passed, 0 failed. Regression suite 33 passed, 0 failed. Suites run: 142. |
| `git diff --name-only v0.34.0..HEAD` filtered to setup-delivered paths | 9 files, an exact match with the list in `migrate-0.35.0-rerun-setup.md` |
| `grep` for em dashes in added `.md` and `.yml` lines | 0 hits |
| `grep` for semicolons in added prose outside tables and code | 0 new hits. The one hit in orchestrator Hard Limit 7 sits in text that predates this feature. |
| American spelling scan of added prose | 0 new hits. `authorized` in Hard Limit 7 predates this feature. |
| Sentence-length scan of added prose | 15 sentences of 25 words or more (see m-3) |
| `grep -n "number,url,mergedAt" CLAUDE.md` | The generated boot file carries GUTD step 5 |

## Requirement coverage

| Req | Met | Evidence |
|-----|-----|----------|
| req-001 | Yes | Ship skill Step 10 and Step 10c, the `CI:` line in Step 11, and orchestrator Resume Detection "Resume at P9". `test-0000037-req-001-p9-ci-check.sh` passes. Stub and real `gh` rows pass in `verification-report.md`. |
| req-002 | Yes, with drift | `custom-003-git-up-to-date-shorthand.md` step 5. The field list drops `title` (m-1). |
| req-003 | Code yes, artifacts no | `scripts/credential-scan.mjs` meets the script criteria. The held-back rule contradicts the requirement text (M-1). |
| req-004 | Yes | Ship skill "PR text scan" and "PR text rule". `--file` mode verified by execution. |
| req-005 | Yes | Docs agent `## Post-P6 revalidation`, orchestrator P6 row, standard P6 row. Build log records cycle 1 fail and cycle 2 pass. |
| req-006 | Yes | Template, spec agent, codegen agent, and validate agent text. Suite passes. |
| req-007 | Yes | `test-0000037-req-007-wired-command.sh` passes. |
| req-008 | Yes | Build log P6 records the real comparison: 9 setup-delivered files, no skip. |
| req-009 | Yes | Lint reports 0 findings over 142 files. All 141 suites passed from three start directories. |
| req-010 | Yes | Seven Windows shards pass on PR #64. The skip table and guards match. |
| req-011 | Yes | `setup-powershell-51` job, `test_setup.ps1` section, and `docs/architecture-overview.md` line 165. |

## Findings

### Critical

None.

### Major

**M-1. req-003 and ADR-003 still describe a held-back file that stays staged.**

- Files:
  - `plan/current/requirements/req-003-pre-commit-credential-scan.md` lines 27, 28, 30, 31, 39, and 41
  - `plan/current/adr/ADR-003-credential-scan-script-skill-enforced.md` lines 33 and 63
  - `planifest-framework/tests/test-0000037-req-003-credential-scan.sh` lines 483 to 493
- Evidence:
  - req-003 says "The files stay staged. The agent unstages nothing." AC 003.2 and AC 003.3 repeat "stays staged".
  - The shipped standard does the opposite. `autonomous-run-standards.md` `### Scan-then-commit` step 4 unstages each held-back file that is staged as new. The ship skill P8 guard, line 213, does the same.
  - The P5 approach 2 change also added `--safe-paths` and `--pathspec-from-file` commits. ADR-003 names neither. The `component.yml` contract does name `--safe-paths`.
  - req-003 line 28 specifies `held back {n} file(s)`. The shipped line is `held back {path}`.
  - The build log records the change as `Deviation (P5, unclassified)` and P5 decisions. No `Amended (P5)` line exists in req-003, and ADR-003 has no amendment note.
  - The AC 003.3 test asserts `A ` (still staged) after a scan alone. It never models the shipped unstage step, so it passes against a superseded rule.
- Rule: the documentation rule (boot Hard Limit 7) needs the plan artifacts to match what shipped.
- Fix:
  1. Add `Amended (P5)` lines under req-003 AC 003.2 and AC 003.3. Each states that a held-back file staged as new leaves the index, and that a tracked one stays out of the safe list.
  2. Add an amendment section to ADR-003 for scan-then-commit, `--safe-paths`, and `--literal-pathspecs`. Add the `held back {path}` wording.
  3. Retitle the AC 003.3 test block. Add one assertion that models the rule: after `git restore --staged`, the clean-tree check shows `?? docs/leak.md`.

### Minor

**m-1. req-002, ADR-005, and `design.md` still request `title` in the GUTD lookup.**

- Files: `requirements/req-002-gutd-ci-check.md` line 81 and its AC 002.1 Amended (P1) line, `adr/ADR-005-gutd-reads-last-merged-pr-checks.md` line 24, and `design.md` line 24.
- Evidence: the override, line 15, requests `--json number,url,mergedAt`. P5 dropped `title` on purpose ("GUTD requests no titles").
- Fix: add an `Amended (P5)` line to req-002 and a note in ADR-005.

**m-2. Orchestrator Hard Limit 7 conflicts with scan-then-commit.**

- File: `planifest-framework/skills/planifest-orchestrator/SKILL.md` line 26.
- Evidence:
  - The added text says "A matched file leaves the index" and "every commit names explicit paths after `--`".
  - The standard unstages only a new file. It keeps a tracked held-back file in place and leaves it out of the safe list.
  - P7 to P9 commits use `--pathspec-from-file`, not `--`.
- Fix: point Hard Limit 7 at `### Scan-then-commit` in place of restating it.

**m-3. Some added sentences pass 25 words.**

- Evidence, from the scan:
  - `src/setup-hook-integration/docs/quirks.md` line 67, the "Resolved in 0000037" sentence, 36 words
  - `docs/decisions-index.md` line 6, 34 words
  - `planifest-framework/skills/planifest-ship-agent/SKILL.md` lines 258 and 455, "Create the out-file fresh ... or the skip", about 33 words each
  - `planifest-framework/standards/autonomous-run-standards.md` line 127, 29 words
  - `plan/_migrations/migrate-0.35.0-rerun-setup.md`, the record body, 29 words
  - `docs/architecture-overview.md` lines 419 and 423, 28 words each
- Fix: split each sentence at its conjunction.

**m-4. The ship skill P8 guard repeats one sentence.**

- File: `planifest-framework/skills/planifest-ship-agent/SKILL.md` line 213.
- Evidence: "Refused files stay uncommitted. A refused file stays uncommitted."
- Fix: delete one of the two sentences.

**m-5. Step 10 does not check the state of the PR it finds.**

- File: `planifest-framework/skills/planifest-ship-agent/SKILL.md` line 336.
- Evidence: req-001 asks for "an open PR". `gh pr view --json number,url,isDraft` requests no `state` field. A closed PR on the same branch could therefore be edited in place of raising a new one.
- Fix: request `state`, and reuse the PR only when it reads `OPEN`.

**m-6. Risk register statuses are stale.**

- File: `plan/current/risk-register.md`.
- Evidence:
  - All 24 risks read `open`.
  - R-001, R-012, and R-023 are resolved by P3 and P4 outcomes.
  - R-011 still says each new job keeps `timeout-minutes: 10`. ADR-014 gives the Windows shards 20.
- Fix: update the status of each resolved risk and amend R-011 to cite ADR-014.

**m-7. A stale code comment sits in the scan script.**

- File: `planifest-framework/scripts/credential-scan.mjs` line 49.
- Evidence: "Split so that this file does not match its own rule" sits above the `ASIA` rule. Nothing on that line is split.
- Fix: move the comment or remove it.

## Living docs and manifests

- `docs/architecture-overview.md`, `docs/component-registry.md`, `docs/decisions-index.md`, and `docs/dependency-graph.md` match the shipped workflow, script, and skills.
- The architecture overview states five jobs, seven Windows shards at 20 minutes, and 5.1 support. `.github/workflows/planifest.yml` matches.
- `planifest-framework/component.yml` is at 0.35.0 with responsibilities, scope, contract, and risk for this feature.
- `src/setup-hook-integration/component.yml` is at 0.7.0 and records the 5.1 support and the `git config` exit check.
- No drift beyond M-1 and m-1 to m-2.

## Migration

- `planifest-framework/migrations/migrate-0.35.0-rerun-setup.md` lists the 9 setup-delivered files. This matches `git diff --name-only v0.34.0..HEAD` exactly.
- The migration states that setup copies no `scripts/` folder, so `credential-scan.mjs` arrives with the `planifest-framework/` refresh.
- `plan/_migrations/migrate-0.35.0-rerun-setup.md` records `outcome: "applied"` for framework version 0.35.0.
- The build log P6 block records the setup run, the drift check, and the hook comparison.

## Open risks against the backlog

Each open item has a backlog entry that cites `Source feature: 0000037-green-ci-before-ship`.

| Source | Item | Backlog |
|--------|------|---------|
| `scope.md` Deferred | Step 11 push leaves the last head unchecked | 0000193 (open) |
| `scope.md` Deferred | CI fetches no release tags | 0000199 (open) |
| `security-report.md` | Git Bash path read as outside the repository | 0000204 (open) |
| `security-report.md` | `design.md` link swap on Windows | 0000209 (open) |
| `security-report.md` | Floating `actions/checkout@v4` tag | 0000218 (open) |
| `security-report.md` | Empty-list guard leaves exit code 1 | 0000223 (open) |
| `risk-register.md` R-013 | Balanced Windows shards | 0000213 (open) |
| Verification report | `gh pr checks` prints no JSON before checks register | 0000215 (closed in P4, fix confirmed in Step 10c and GUTD step 5) |

No open risk lacks an entry. This review filed no backlog entry, because every finding sits in this feature's scope.

## Pass condition

To reach APPROVE, fix M-1. A fix for m-1 and m-2 in the same commit would also close the remaining requirement drift. The minor prose findings do not block on their own.
