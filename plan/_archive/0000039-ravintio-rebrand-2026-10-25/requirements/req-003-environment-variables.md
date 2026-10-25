---
title: "Requirement: req-003 - environment-variables"
summary: "Every PLANIFEST_* variable becomes RAVINTIO_*, with one legacy fallback for PLANIFEST_SESSION_ID."
status: "draft"
version: "0.1.0"
---
# Requirement: req-003 - environment-variables

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000039-ravintio-rebrand
**Source:** US-001
**Priority:** must-have

## User Story

As the human on the loop, I rename every `PLANIFEST_*` variable to `RAVINTIO_*`, so that no environment variable carries the old brand.

## Functional Requirements
- Rename each variable in the inventory below to its `RAVINTIO_` twin in code, scripts, tests, CI, and live docs. History paths are excluded (see req-005).
- Inventory from `git grep -ohE 'PLANIFEST_[A-Z_]+' -- . ':!plan/_archive' ':!plan/changelog' | sort -u`, 31 matches at P1:
  - Shell and hook scripts: `PLANIFEST_ADAPTER_CMD`, `PLANIFEST_BASENAME`, `PLANIFEST_BOOT`, `PLANIFEST_DESIGN`, `PLANIFEST_EM_DASH`, `PLANIFEST_FILE_PATH`, `PLANIFEST_GATE`, `PLANIFEST_GITLEAKS`, `PLANIFEST_HOOKS_BASE`, `PLANIFEST_NAME`, `PLANIFEST_OPENCODE_JSON`, `PLANIFEST_PLUGIN_REF`, `PLANIFEST_PRESENCE`, `PLANIFEST_RATCHET`, `PLANIFEST_SETTINGS`, `PLANIFEST_SETTINGS_JS_HELPERS`, `PLANIFEST_SETTINGS_REL`, `PLANIFEST_SHELL_GUARD`, `PLANIFEST_TIER`, `PLANIFEST_TMP`, `PLANIFEST_TRIGGER`.
  - Promotion script: `PLANIFEST_PROMOTED_BY`, `PLANIFEST_PROMOTION_DATE`, `PLANIFEST_REGRESSION_DIR`, `PLANIFEST_SOURCE_FEATURE`.
  - CI matrix and test runner: `PLANIFEST_SHARD_INDEX`, `PLANIFEST_SHARD_COUNT`.
  - OpenCode adapter: `PLANIFEST_SESSION_ID`.
  - Retired telemetry names, in tests only: `PLANIFEST_TELEMETRY`, `PLANIFEST_TELEMETRY_URL`.
  - `PLANIFEST_SHARD` is a prefix match inside prose or a glob. Rename it with the shard pair.
- The exact inventory command is `git grep -ohE 'PLANIFEST_[A-Z_]+' -- . ':!plan/_archive' ':!plan/changelog' ':!plan/_migrations' ':!plan/current' ':!plan/backlog/*/_reference' ':!ravintio-framework/migrations' ':!ravintio-framework/tests/test-0000039-req-006*' | sort -u`. The exclusions cover history paths, shipped migration bodies, `plan/_migrations/`, `plan/current/`, backlog `_reference/` documents, and the req-006 helper files and their tests. The helpers name the pack-owned variables they rewrite in a consumer workflow.
  - P6 correction (verification defect D-2): the command also excludes `':!ravintio-framework/tests/test-0000039-req-003*'`. That suite's own probe names the old shard variables, and the suite already excludes every `test-0000039-*` file.
- Re-run the inventory command at P3 and rename any name that appears since P1.
- `PLANIFEST_SESSION_ID` is the only name with a legacy fallback. The OpenCode adapter in `planifest-framework/hooks/adapters/opencode/index.ts` (renamed by req-001) reads `RAVINTIO_SESSION_ID` first. It reads `PLANIFEST_SESSION_ID` only when `RAVINTIO_SESSION_ID` is unset. It prints no warning. 1.0.0 removes the fallback.
- No other variable gets a fallback, because only the pack sets them.
- `PLANIFEST_SHARD_INDEX` and `PLANIFEST_SHARD_COUNT` change in the CI workflow (renamed `ravintio.yml` by req-001) and in `tests/run-tests.sh` in the same commit. A split would leave CI running one unsharded suite or failing.
- Retired telemetry names stay as they are in tests. The absence checks in `test-0000030-req-003-telemetry-pipeline-text-removal.sh` and the stale-settings fixture in `test-0000030-req-004-install-clean-up-and-retired-flags.sh` simulate a consumer who still holds the old name. Renaming them would stop the checks testing that case. Req-007 allowlists these two files for `PLANIFEST_TELEMETRY*`, and req-005 lists them as protected from the replace.
- Split step: keep. The rename, the one fallback, and the CI pairing all concern variable names, so one requirement covers them.

## Acceptance Criteria
- [ ] After the rename, the inventory command returns only `PLANIFEST_SESSION_ID` (in the adapter fallback and its test) and `PLANIFEST_TELEMETRY*` (in the two 0000030 test files), and the full suite passes. Verified by: execution
- [ ] With only `PLANIFEST_SESSION_ID` set, the OpenCode adapter uses its value and prints no warning. With both set, it uses `RAVINTIO_SESSION_ID`. Verified by: unit
- [ ] A sharded run with `RAVINTIO_SHARD_INDEX` and `RAVINTIO_SHARD_COUNT` set runs the expected slice of tests, and the CI workflow sets the same two names. Verified by: integration

## Dependencies
- req-001 supplies the renamed adapter, workflow, and test paths this requirement edits.
- req-005 supplies the protected list that keeps the two 0000030 telemetry tests unchanged.
- req-007 supplies the brand-guard allowlist entries for the retained names.
