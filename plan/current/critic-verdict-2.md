# Design-Critic Verdict (iteration 2)
**Mode:** on
**Mechanical check:** clean (exit 0). Output, with the tool's dash written as a hyphen because a hook blocks the dash character:
- `⚠ req-002-runtime-names.md: 4 acceptance criteria (aim for 3 - consider splitting the story)`
- `⚠ req-004-brand-prose.md: 4 acceptance criteria (aim for 3 - consider splitting the story)`
- `⚠ req-006-consumer-migration.md: 5 acceptance criteria (aim for 3 - consider splitting the story)`
- `consistency-check: clean`

The warnings feed rubric item 9.
**Overall:** REJECT

Rubric items 3 and 4 are not applicable (no ADRs exist at P1).

## Iteration 1 findings

| Finding | Status | Evidence |
|---------|--------|----------|
| F1 backup stop breaks rerun | Fixed in text, but see N1 | req-006 stop condition 3 now applies only while the old pack still exists. |
| F2 req-003 inventory | Fixed | The command now excludes `plan/_migrations`, `plan/current`, backlog `_reference`, migrations, and the req-006 helper files. A trial `git grep` run on the current tree finds 31 names, all of them in the inventory. |
| F3 R-008 | Fixed | R-008 now matches req-009: the mapping reads the new paths and never reads `.ravintio-backup/`. |
| F4 R-020 | Fixed | R-020 says setup sets `core.hooksPath` and the helper does not. req-008 AC2 checks it. The old-install fixture is not in the AC (minor, N5). |
| F5 version bump owner | Fixed with a defect | req-004 AC4 owns it. See N3 and N6. |
| F6 error and cross-session paths | Mostly fixed | req-006 AC5 covers interruption after any step. The brief's Scenario Paths now hold all four paths. See N4. |
| F7 rename similarity | Fixed | req-001 FR plus R-021 give a dry run and a logged fallback. |
| F8 NFR-003 | Fixed | The command uses `--diff-filter=MDR`. |
| F9 req-007 allowlist | Fixed | req-007 lists the 0000030 files, `test-0000036`, mojibake lines, fixtures, and live backlog entries. |
| F10 req-006 split record | Not fixed | See N2. |

## Rubric

| Rubric item | Verdict | Evidence / finding |
|-------------|---------|--------------------|
| 1 Testability | fail | Most ACs name an observable outcome with a `Verified by:` tag (req-001, 003, 005, 007, 008, 009). Defects: req-004 AC3 still includes "`docs/about.md` shows 0.37.0 after ship", which no P3 to P6 check can observe. The FR repeats it and does not fix it. req-004 "where the short form reads better" has no check. req-006 AC2 lists "an existing backup" as an unconditional non-zero exit, while the FR exits 0 when the old pack is gone. |
| 2 Traceability | pass with minor defects | All reqs carry `Source:` US-001 to US-003, and the execution plan table matches. `scope.md` keeps the line "version bump maps to req-006" beside a "superseded" clarification. It also still maps the setup refusal to req-006, though req-002 owns it. |
| 5 Scope boundaries | pass | `scope.md` Out of Scope excludes `external-skills/` text, `_reference/` documents, the major bump, and sibling repos. `design.md` Out says "every other backlog entry", while `scope.md` and req-004 rename brand words in live entries (minor). |
| 6 Risks | pass | R-001 to R-021 are specific, and mitigations are actions. R-008, R-020, and R-021 are fixed. R-013 relies on a list in the migration body that no AC checks (minor). |
| 7 NFRs | pass | NFR-001 to NFR-004 each have a number and a deterministic command. NFR-003 now excludes added files. |
| 8 Internal consistency | fail | N1. Also req-004 cites two heredoc ranges (788 to 957 and 811 to 958) and patches this with a reconciling note. |
| 9 Split step | fail | N2. |

## Findings (severity-ordered)
- [major] N1 req-006 step 2 stop condition 4 and step 6: step 6 runs `git rm -r --cached -- planifest-framework`. This stages deletions. After that, `git diff --cached --quiet -- planifest-framework` exits 1, so a rerun stops. That breaks AC2 ("a rerun exits 0") and AC5 (resume after any single step). Fix: test only staged edits that are not deletions, for example `--diff-filter=M`, or skip the check once the old pack is absent. Add a fixture for a run interrupted after step 6.
- [major] N2 Split step records (item 9). req-006 has 5 ACs, but the build log says "req-006 keeps four criteria". req-004 has 4 ACs and no build-log Decision. Its keep note says "prose and links", yet AC4 covers the version in `product.yml` and `component.yml`, which is a second concern. req-002 has 4 ACs and two contradictory notes ("Split step for the fourth criterion: keep" and "Split step: split"). The log records only the req-002 split, not a keep for AC4. Fix: for each file, either move the extra criterion to another requirement or add one `Split step: keep` note with one named concern, plus a matching `Decision` line with the right count. Move the version bump out of req-004.
- [minor] N3 req-004 AC3 and the FR: drop the ship-time check ("shows 0.37.0 after ship") from the P3 to P6 criteria, or add a separate criterion marked as checked at P7. Define the "short form" rule.
- [minor] N4 req-006 AC5 does not assert that the helper names the failed step or lists what already moved (the Scope Lock error path). No AC shows that a fresh consumer's migrator records `not applicable` (req-009 AC3 covers only this repo).
- [minor] N5 req-008 AC2 and R-020 name an old-install fixture, but the AC says only "a fixture".
- [minor] N6 `scope.md`: delete the superseded req-006 version-bump line and fix the setup refusal mapping to req-002. Align `design.md` Out ("every other backlog entry") with the brand-word edits.
