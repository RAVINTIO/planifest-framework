# Verify-by-Execution Report
**Toggle:** on
**Software exercised:** The 0.36.0 pack from `main` and the 0.37.0 `ravintio-framework/` from ROOT, run with `setup.sh`, the 0.37.0 migration helper, and the req-001 suite. All runs used `git clone` copies and scratch repos under a `mktemp -d` folder. Nothing ran inside ROOT.

| Requirement | Criterion | Method | Outcome | Observation evidence |
|-------------|-----------|--------|---------|---------------------|
| REQ-006 | Consumer upgrade: old pack moves to the backup folder | CLI: old `setup.sh claude-code`, copy in new pack, run helper, then new `setup.sh` | verified | Helper exit 0. `Step 6: moved planifest-framework/ to .ravintio-backup/planifest-framework/`. The backup holds the old pack. `.ravintio-backup/` is in `.git/info/exclude`. |
| REQ-006 | Overrides move | Same run | verified | `Step 3: moved planifest-overrides/ to ravintio-overrides/`. `planifest-overrides` is gone. |
| REQ-006 | Workflow renamed | Same run | verified | `Step 4: renamed .github/workflows/planifest.yml to .github/workflows/ravintio.yml`. Git shows an `R` entry. |
| REQ-006 | `core.hooksPath` | `git config core.hooksPath` | verified | Before: `planifest-framework/hooks`. After: `ravintio-framework/hooks`. |
| REQ-006 | No doubled blocks | Count markers after setup, then after a second setup | verified | `ravintio-overrides:instructions:start` count is 1 in `CLAUDE.md` before and after a second run. The `RAVINTIO - Token` line count is 1 in `.claudeignore`. Old `planifest-overrides:` markers: 0. |
| REQ-006 | Old installed skills pruned | `ls .claude/skills` | verified | 21 `ravintio-*` skills and 0 `planifest*` skills. The old `.planifest-manifest` and `.planifest-setup-flags` files are gone. |
| REQ-006 | Flags carried | Old setup with `--strict-orchestrator`, then helper, then plain `setup.sh claude-code` | verified | New `.claude/.ravintio-setup-flags` holds `"flags": ["--strict-orchestrator"]`. |
| REQ-006 | Helper is idempotent | Run the helper again | verified | `Nothing to do. This project already uses the RAVINTIO names.` |
| REQ-009 | Setup stops when the old pack sits beside the new one | Restore the old pack, run `setup.sh` | verified | `Error: found the old folder planifest-framework/ at the project root.` Exit 1. |
| REQ-001 | Fresh consumer sees only new names | Copy only `ravintio-framework/`, run `setup.sh claude-code` | verified | Exit 0. `core.hooksPath` is `ravintio-framework/hooks`. The only `planifest` strings on disk are deliberate old-name reads (`OLD_SENTINEL` in `em-dash-guard.mjs`, migrator mapping text, refresh-setup fallback text). |
| REQ-001 | AC1: no tracked path with the old brand | `RAVINTIO_PASS_COMMIT=81287992` req-001 suite in a ROOT clone | **failed** | `FAIL: ... (3 found)`. Leftovers are `planifest-framework/external-skills/README.md` and two `SKILL.md` files. These are the three held-back external-skills files. ROOT's working tree has them moved, but the move is uncommitted. |
| REQ-001 | AC3: renames show as `R` | Same suite | verified | 43 passed. Every folder, workflow, hook file, and PowerShell script reports `R`. No `D` entry for an old-brand path. |
| REQ-003 | AC1: inventory | The inventory command from req-003 in the clone | verified | Output: `PLANIFEST_SESSION_ID`, `PLANIFEST_SHARD_COUNT`, `PLANIFEST_SHARD_INDEX`, `PLANIFEST_TELEMETRY`, `PLANIFEST_TELEMETRY_URL`. |
| REQ-003 | AC1: full suite passes | Not run | not-verifiable | The criterion says "the full suite passes". The `run-tests.sh` suite was out of scope for this run. CI covers it. |
| REQ-004 | AC3: heredoc bytes | Extract old lines 811 to 958 and new lines 880 to 1027, normalise brand words, `cmp` | verified | `cmp` reports identical. The non-ASCII byte streams match. Old line 1322 and new line 1407 have the same md5 after normalisation. The line numbers moved by 69 and 85 because of added lines above. |
| REQ-005 | History byte-identity | `git diff --name-status --diff-filter=MDR origin/main...HEAD -- plan/_archive plan/changelog plan/_migrations ':(glob)plan/backlog/*/_reference/**'` | verified | No output. |
| REQ-010 | AC2: no live file names 1.0.0 as current | `git grep '1\.0\.0'` outside history, vendored skills, and the backlog | verified | Hits are "removed at 1.0.0" comments, `templateVersion: "1.0.0"` in `component.yml`, and a phase-0 version example. None name 1.0.0 as the current release. `product-version.mjs` prints `0.37.0`. |
| REQ-009 | Migrator view: no pending migration | Compare `ravintio-framework/migrations/*` to `plan/_migrations/*.md` in the clone | verified | `plan/_migrations/migrate-0.37.0-ravintio-rename.md` exists. The only file without a same-named record is `migrate-archive-dirname.sh` and `.ps1`. On `main` these helpers also lack a record, and `0003-archive-dirname.md` covers them. |

## Counts
- verified: 16
- failed: 1 (req-001 AC1)
- not-verifiable: 1 (req-003 full suite)

## Observations
- User-owned override text still names `planifest-framework/templates/...` in the consumer `CLAUDE.md` (line 94). It comes from the overrides copy, so the helper does not rewrite it.
- A plain `setup.sh` re-run without flags resets the stored flags to `[]`. This matches the old behaviour.
