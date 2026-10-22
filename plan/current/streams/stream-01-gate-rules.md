---
stream-id: "stream-01-gate-rules"
kind: stream
start-commit: "2baa848"
status: at-join
phase: P3
requirements: [req-001, req-003, req-004, req-005, req-006, req-009]
stories: [US-001, US-003, US-004, US-005, US-006, US-009]
id-blocks: "req-001, req-003 to req-006, req-009, ADR-001 to ADR-009, backlog 0000128 to 0000132"
updated: "2026-10-22T06:41:34Z"
---
# Stream State: stream-01-gate-rules

## Phase history

| Phase | Start | End | Subagents | Result |
|-------|-------|-----|-----------|--------|
| P1 | 2026-10-21T23:39:00Z | 2026-10-21T23:55:00Z | 1 | at-join |
| P2 | 2026-10-22T05:50:16Z | 2026-10-22T05:53:11Z | 1 | at-join |
| P3 | 2026-10-22T06:17:11Z | 2026-10-22T06:41:34Z | 1 | at-join |

## Files changed

- `plan/current/requirements/req-001-fast-path-scope-record.md`
- `plan/current/requirements/req-003-links-judged-by-real-target.md`
- `plan/current/requirements/req-004-root-when-cwd-deleted.md`
- `plan/current/requirements/req-005-ratchet-check-shared-root.md`
- `plan/current/requirements/req-006-no-planted-root-marker.md`
- `plan/current/requirements/req-009-fast-path-enforcement-paths.md`
- `plan/backlog/0000128-ratchet-check-spawns-git/entry.md`
- `plan/current/adr/ADR-001-stack-unchanged-node-built-ins-no-spawn.md`
- `plan/current/adr/ADR-002-fast-path-scope-record-self-authorisation.md`
- `plan/current/adr/ADR-003-scope-record-staleness-from-git-files.md`
- `plan/current/adr/ADR-004-fast-path-enforcement-path-list.md`
- `plan/current/adr/ADR-005-links-resolved-segment-by-segment-fail-closed.md`
- `plan/current/adr/ADR-006-root-lookup-when-cwd-is-deleted.md`
- `plan/current/adr/ADR-007-ratchet-check-uses-shared-path-rules.md`
- `plan/current/adr/ADR-008-distrust-markers-under-always-permitted-names.md`
- `plan/backlog/0000130-no-check-ties-setup-wiring-files-to-enforcement-list/entry.md`
- `planifest-framework/hooks/enforcement/path-rules.mjs` (P3)
- `planifest-framework/hooks/enforcement/gate-write.mjs` (P3)
- `planifest-framework/hooks/enforcement/shell-write-guard.mjs` (P3)
- `planifest-framework/hooks/enforcement/ratchet-check.mjs` (P3)
- `planifest-framework/workflows/fast-path.md` (P3)
- `.gitignore` (P3)
- `planifest-framework/tests/test-0000035-req-001-fast-path-scope-record.sh` (P3)
- `planifest-framework/tests/test-0000035-req-003-links-judged-by-real-target.sh` (P3)
- `planifest-framework/tests/test-0000035-req-004-root-when-cwd-deleted.sh` (P3)
- `planifest-framework/tests/test-0000035-req-005-ratchet-check-shared-root.sh` (P3)
- `planifest-framework/tests/test-0000035-req-006-no-planted-root-marker.sh` (P3)
- `planifest-framework/tests/test-0000035-req-009-fast-path-enforcement-paths.sh` (P3)
- `planifest-framework/tests/test-0000032-req-006-outside-repository-pass.sh` and its `tests/regression/` copy (P3, deleted-cwd assertion now expects exit 2)
- `planifest-framework/tests/test-0000017-req-002-ratchet-approve.sh` and its `tests/regression/` copy (P3, clears `CLAUDE_PROJECT_DIR`)
- `planifest-framework/tests/test-0000016-pipeline-governance.sh` and its `tests/regression/` copy (P3, clears `CLAUDE_PROJECT_DIR`)

## Declares

| Artifact ID | Defined in | Consumer |
|-------------|------------|----------|

None. Every artifact this stream makes has its consumer inside this stream: `path-rules-resolveTarget-links` and `path-rules-resolveRoot-deleted-cwd` feed req-005, and `path-rules-markedRoot-basename-distrust` feeds req-005 through `resolveRoot`.

## Consumes

- none from other streams

## Next step

Wait for the P3 join.
