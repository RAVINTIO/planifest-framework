---
stream-id: "stream-02-release-manifest"
kind: stream
start-commit: "2baa848"
status: at-join
phase: P2
requirements: [req-002, req-008]
stories: [US-002, US-008]
id-blocks: "req-002, req-008, ADR-010 to ADR-014, backlog 0000133 to 0000135"
updated: "2026-10-22T06:05:41Z"
---
# Stream State: stream-02-release-manifest

## Phase history

| Phase | Start | End | Subagents | Result |
|-------|-------|-----|-----------|--------|
| P1 | 2026-10-21T23:39:00Z | 2026-10-21T23:45:00Z | 1 | at-join |
| P2 | 2026-10-22T05:50:00Z | 2026-10-22T05:51:00Z | 1 | at-join |

## Files changed

- `plan/current/requirements/req-002-product-yml-in-p7.md`
- `plan/current/requirements/req-008-sanctioned-scripts.md`
- `plan/current/adr/ADR-010-product-yml-set-in-p7-by-script.md`
- `plan/current/adr/ADR-011-hard-limit-8-sanctioned-scripts.md`
- `plan/current/adr/ADR-012-acceptance-criteria-limit-and-warning.md` (P2 critic fix M1. The ID comes from this stream's block.)

## Declares

| Artifact ID | Defined in | Consumer |
|-------------|------------|----------|

None. `SET-PRODUCT-RELEASE-SCRIPT` serves req-002 and req-008 inside this stream. `SHIP-P7-PRODUCT-YML-STEP` and `TEST-0000035-REQ-002-SUITE` serve req-002 only. `TEST-0000035-REQ-008-SUITE` and the boot template sentence serve req-008 only.

## Consumes

- `resolveRoot` from `planifest-framework/hooks/enforcement/path-rules.mjs` (existing export, signature unchanged). Stream 01 changes that file. Req-008 imports it for the `--root` rule (req-008 Dependencies).

## Next step

P3: build req-002 and req-008.
