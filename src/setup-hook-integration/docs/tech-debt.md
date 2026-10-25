# Tech Debt — setup-hook-integration

## TD-001 — Skill name not validated before path operations (Security F-002)

**File:** `ravintio-framework/scripts/skill-sync.sh`
**Severity:** Medium
**Status:** ✅ Fixed 2026-04-25
**Fix applied:** `validate_skill_name()` added; called in `cmd_add`, `cmd_remove`, `cmd_install`, `cmd_preserve`, `cmd_unpreserve`. Rejects names not matching `^[a-zA-Z0-9_-]+$`.
**Tests:** `test-skill-sync-security.sh` — F-002 section (5 tests).

## TD-002 — `get_skill_scope()` interpolates `$name` into `node -e` string (Security F-001)

**File:** `ravintio-framework/scripts/skill-sync.sh:78`
**Severity:** Medium
**Status:** ✅ Fixed 2026-04-25
**Fix applied:** `skill_in_manifest()` and `get_skill_scope()` now use `SKILL_NAME`/`SKILL_MANIFEST` env-var pattern. Injection vector removed.
**Tests:** `test-skill-sync-security.sh` — F-001 section (2 tests). Also covered transitively by TD-001 fix (invalid chars blocked before JS is reached).

## TD-003 — `--from` URL scheme not validated (Security F-003)

**File:** `ravintio-framework/scripts/skill-sync.sh:218–220`
**Severity:** Low-Medium
**Status:** ✅ Fixed 2026-04-25
**Fix applied:** `cmd_add` rejects any `--from` URL not starting with `https://` before passing to curl.
**Tests:** `test-skill-sync-security.sh` — F-003 section (5 tests).

## TD-004 and TD-005: retired

These items covered tests of a hook integration that setup no longer installs.

## TD-006 — `setup.ps1` not updated with skill subcommand routing

**File:** `ravintio-framework/setup.ps1`
**Severity:** Low
**Status:** ✅ Fixed 2026-04-25
**Fix applied:** Subcommand routing block added before the arg-parsing loop. `setup.ps1 add-skill <name> <tool>` now delegates to `skill-sync.ps1 -Operation add`; same for `remove-skill`, `preserve-skill`, `unpreserve-skill`.

## TD-007: `setup.sh all` stops at roo-code, `TOOL_*` values carry over (backlog 0000087)

**File:** `ravintio-framework/setup.sh`
**Status:** Open. Filed during 0000030 P3. See backlog 0000087.

## TD-008: opencode PowerShell setup passes a null skills folder (backlog 0000088)

**File:** `ravintio-framework/setup/opencode.ps1`
**Status:** Open. Filed during 0000030 P3. See backlog 0000088. Related to Q-007.

<!-- BEGIN retired-integrations (0000030) -->
## TD-009: clean-up deletes whole folders and matches the `emit_event` group by matcher alone (backlog 0000090)

**File:** `ravintio-framework/setup.sh`, `ravintio-framework/setup.ps1`
**Status:** Open, accepted in 0000030 P5 as security finding F6. See backlog 0000090 and Q-012.
<!-- END retired-integrations (0000030) -->

## TD-010: no live PowerShell run in CI or locally (backlog 0000091)

**File:** `.github/workflows/ravintio.yml`
**Status:** Partly resolved in 0000031. CI now runs the suite on Linux and macOS and `test_setup.ps1` under PowerShell 7 on Windows. Stale-entry clean-up and retired flags still have no live PowerShell test, see Q-013.
**Resolved in 0000037.** The req-011 section of `test_setup.ps1` runs the stale clean-up and a retired flag live under PowerShell 7 and Windows PowerShell 5.1. Backlog 0000203 tracks a remaining byte order mark under 5.1.

## TD-011: old-name reads removed at 1.0.0 (0000039-ADR-003, ADR-004)

**File:** `ravintio-framework/setup.sh`, `ravintio-framework/setup.ps1`, `ravintio-framework/hooks/adapters/opencode/index.ts`, `ravintio-framework/hooks/enforcement/em-dash-guard.mjs`, `ravintio-framework/hooks/enforcement/path-rules.mjs`
**Status:** Open. Every old-name read and its brand guard allowlist entry is removed at 1.0.0 (backlog 0000261). Also add the em dash sentinel and the old paths in `FAST_PATH_ENFORCEMENT_PATHS` to the ADR-004 list, or remove them.
