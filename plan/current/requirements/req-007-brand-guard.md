---
title: "Requirement: req-007 - brand-guard"
summary: "A guard suite fails when the old brand name appears in a live tracked path or line outside a short allowlist."
status: "draft"
version: "0.1.0"
---
# Requirement: req-007 - brand-guard

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000039-ravintio-rebrand
**Source:** US-003
**Priority:** must-have

## User Story

As a human on the loop, I get a failing test when a live file brings back the old name, so that the rename stays complete.

## Functional Requirements
- Add the suite `ravintio-framework/tests/test-0000039-req-007-brand-guard.sh`. It follows the model of RAVINTIO Zero 0000160 req-006 and ADR 004.
- Read the tracked files from `git ls-files`. Drop these paths before any check:
  - `plan/_archive/`
  - `plan/changelog/`
  - `plan/_migrations/`
  - `plan/current/`, because ship archives it and its files quote the old name to describe the rename
  - the bodies of the migrations shipped before 0.37.0 in `ravintio-framework/migrations/`
- Fail on any remaining tracked path or line that matches `planifest`, in any case, unless an allowlist entry covers it. Print the file and line number.
- Write each allowlist entry as a path regex and a line regex. Both must match. Each entry carries a comment that names its reason.
- Allow only these cases:
  - The `PLANIFEST_SESSION_ID` fallback and any other old-name read that stays through 0.x.
  - The new 0.37.0 migration, its two helpers, and their tests.
  - Setup lines that detect the old `planifest-framework/` folder and clear old markers.
  - Backlog `_reference/` documents, which stay as written.
  - Vendored text under `ravintio-framework/external-skills/`.
  - The `planifest-docs` sibling links.
  - The `C:\d\planifest\framework\` path in the refresh script.
  - This suite and its regression copy, which must name the word to match it.
- The closed list also holds these entries, which other requirements rely on. Each carries a path regex, a line regex, and the reason shown:
  - req-003: `ravintio-framework/tests/test-0000030-req-003-telemetry-pipeline-text-removal.sh` and `ravintio-framework/tests/test-0000030-req-004-install-clean-up-and-retired-flags.sh`, lines matching `PLANIFEST_TELEMETRY`. Reason: they simulate a consumer who holds the retired name.
  - req-003: the OpenCode adapter `index.ts` and its test, lines matching `PLANIFEST_SESSION_ID`. Reason: the legacy fallback.
  - req-004: the mojibake lines in the `setup.sh` heredoc that cannot change without touching their bytes. Reason: byte-identical rule.
  - req-004: `planifest-docs` link lines in `README.md` and `docs/`. Reason: sibling repo.
  - req-005: the protected needles in `ravintio-framework/tests/test-0000036-req-001*`. Reason: they test split names.
  - req-005: the history-reading suites that name `plan/_archive/` or `plan/changelog/` paths. Reason: they read history.
  - req-006: `ravintio-framework/migrations/migrate-0.37.0-ravintio-rename.*` and `ravintio-framework/tests/test-0000039-req-006*`. Reason: the helpers name the old pack.
  - req-002 and req-008: setup lines and test fixtures that plant `.planifest-*` markers, old boot-file markers, and old ignore-file headers. Reason: old-name detection through 0.x.
  - req-009: migrator lines that map `planifest-framework/` to `ravintio-framework/`. Reason: the old-path mapping.
  - Live backlog entries that quote the old name, namely 0000237 and entries filed during this feature. Reason: they describe the rename.
- Fail the suite when an allowlist entry matches no line or path. A stale entry must not stay.
- Add a second case. Plant the old name in a scratch copy of `README.md` and expect the check to flag it with the file and line number.
- Read lines with `done <<< "$(...)"` and skip empty lines. Never use `done < <(...)`, because macOS Bash 3.2 drops lines from that form.
- Regression copy: tag the suite `# REGRESSION-CANDIDATE:` so the ship phase offers it for promotion to `ravintio-framework/tests/regression/`. The guard guards a standing rule, so it belongs in the long-term pack. The allowlist covers both paths.
- Split step: keep. The path check, the line check, and the stale-entry check share one allowlist and one scan, so they form one concern.

## Acceptance Criteria
- [ ] The suite passes on the renamed tree, and every remaining match has an allowlist entry with a reason. Verified by: integration
- [ ] The planted-name case fails the check and reports the scratch `README.md` file and line number. A tracked path with the old name outside the allowlist also fails. Verified by: integration
- [ ] A stale allowlist entry fails the suite, and the suite passes on the macOS Bash 3.2 CI leg with the `done <<< "$(...)"` loop form. Verified by: integration

## Dependencies
- req-001 to req-004 remove the old name from live paths and prose before the suite can pass.
- req-005 lists the protected names and history readers that the allowlist and exclusions cover.
- req-006 supplies the migration and helper files that the allowlist covers.
- Existing pattern: `test-0000038-req-002-model-values.sh` and the other allowlist-style suites in `ravintio-framework/tests/`.
