# Tech Debt — setup-hook-integration

## TD-001 — Skill name not validated before path operations (Security F-002)

**File:** `planifest-framework/scripts/skill-sync.sh`
**Severity:** Medium
**Status:** ✅ Fixed 2026-04-25
**Fix applied:** `validate_skill_name()` added; called in `cmd_add`, `cmd_remove`, `cmd_install`, `cmd_preserve`, `cmd_unpreserve`. Rejects names not matching `^[a-zA-Z0-9_-]+$`.
**Tests:** `test-skill-sync-security.sh` — F-002 section (5 tests).

## TD-002 — `get_skill_scope()` interpolates `$name` into `node -e` string (Security F-001)

**File:** `planifest-framework/scripts/skill-sync.sh:78`
**Severity:** Medium
**Status:** ✅ Fixed 2026-04-25
**Fix applied:** `skill_in_manifest()` and `get_skill_scope()` now use `SKILL_NAME`/`SKILL_MANIFEST` env-var pattern. Injection vector removed.
**Tests:** `test-skill-sync-security.sh` — F-001 section (2 tests). Also covered transitively by TD-001 fix (invalid chars blocked before JS is reached).

## TD-003 — `--from` URL scheme not validated (Security F-003)

**File:** `planifest-framework/scripts/skill-sync.sh:218–220`
**Severity:** Low-Medium
**Status:** ✅ Fixed 2026-04-25
**Fix applied:** `cmd_add` rejects any `--from` URL not starting with `https://` before passing to curl.
**Tests:** `test-skill-sync-security.sh` — F-003 section (5 tests).

## TD-004 and TD-005: retired

These items covered tests of a hook integration that setup no longer installs.

## TD-006 — `setup.ps1` not updated with skill subcommand routing

**File:** `planifest-framework/setup.ps1`
**Severity:** Low
**Status:** ✅ Fixed 2026-04-25
**Fix applied:** Subcommand routing block added before the arg-parsing loop. `setup.ps1 add-skill <name> <tool>` now delegates to `skill-sync.ps1 -Operation add`; same for `remove-skill`, `preserve-skill`, `unpreserve-skill`.
