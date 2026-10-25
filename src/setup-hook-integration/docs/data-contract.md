---
title: "Data Contract: Setup Hook Integration"
summary: "Defines the precise schema and relationships of data owned by this component."
status: "active"
version: "0.1.0"
---
# Data Contract - Setup Hook Integration

**Skill:** [codegen-agent](../../../ravintio-framework/skills/ravintio-codegen-agent/SKILL.md) (updated via migration proposals)
**Tool:** claude-code
**Model:** claude-sonnet-4-6
**Component:** setup-hook-integration
**Feature:** 0000020-setup-refresh-skill
**Owner:** setup-hook-integration (data is always owned by exactly one component)
**Schema Version:** 1.0.0
**Version:** 0.1.0

> This is the authoritative schema definition for this component's data. Any schema change requires a migration proposal - never modify the schema directly.

---

## Files

### `.claude/.ravintio-setup-flags`

A single JSON file per repo (not a database table, a local, uncommitted, plain-text marker file). Written by `setup.sh`/`setup.ps1` on successful install (REQ-008), and by the `ravintio-refresh-setup` skill before boot-file deletion begins (REQ-009). Read by `ravintio-refresh-setup` for flag reconstruction (REQ-002) and cross-session recovery (REQ-010).

| Field | Type | Nullable | Default | Constraints |
|-------|------|----------|---------|------------|
| `tool` | string | no | none | One of the tool identifiers `setup.sh`/`setup.ps1` recognise (`claude-code`, `cursor`, `windsurf`, `cline`, `codex`, `opencode`, `antigravity`, `copilot`, `roo-code`) |
| `flags` | array of string | no | `[]` | Each entry is a flag exactly as passed to `setup.sh`/`setup.ps1` (e.g. `--strict-orchestrator`, `--include-full-skill-library`). The three retired integration flags (see 0000030-ADR-003) are never written |
| `writtenAt` | string (ISO 8601 UTC) | no | none | Timestamp of the write. Updated on every write, so setup rewrites it on every run and a byte comparison of two runs differs on this field alone (see quirks Q-011) |
| `attemptStatus` | string enum: `completed` \| `pending` | no | `completed` | `completed` after a successful `setup.sh`/`setup.ps1` install write (REQ-008); `pending` after the refresh skill's pre-deletion write (REQ-009), until a subsequent `completed` write from a successful re-invocation (REQ-005) supersedes it |
| `attemptedCommand` | string | yes | none | Present only when `attemptStatus` is `pending` or when the file was last written by the refresh skill; the exact command REQ-009 recorded and REQ-005/REQ-006 use for re-invocation or reporting |

**Old marker files (0000039).** Before 0.37.0 the marker carried the old brand name in its file name. Setup and `ravintio-refresh-setup` read the old file once when the new one is absent. They write `.ravintio-setup-flags` and remove the old file (0000039-ADR-004). Setup owns two other marker files. They are `.ravintio-manifest` and the session marker `.ravintio-session`. Setup reads the old manifest once to prune the old skill copies, then removes it. The migration helper removes the old session marker and leaves the old flags and manifest files for setup. Consumer repos read these files and never write them (0000039-ADR-010).

The marker and `ravintio-overrides/setup-config/{tool}.md` no longer carry a `backendUrl` field (0000030). Setup omits the field and does not write null. A reader must treat an old marker that still holds `backendUrl` as having an unknown extra field and ignore it.

**Indexes:** not applicable, single-file, single-record store, one per repo.

**Relationships:** none, this file has no foreign keys or relationships to other data stores. It is read and written entirely within this repo's local filesystem.

---

<!-- BEGIN retired-integrations (0000030) -->
### Retiring state owned by this component (0000030-ADR-005)

This component owns the removal of every artifact in the clean-up list. That includes `plan/.telemetry-failures/` and `plan/.telemetry-receipts/`, which the deleted telemetry hooks in `ravintio-framework` used to write. Nothing writes them now, so setup is their only remaining actor and it only deletes them. It deletes by exact folder name. `ravintio-framework` keeps ownership of `build-log.md` and the build-log template.

The removal list is:

- `.claude/telemetry-enabled`, written by earlier setup runs.
- `plan/.telemetry-failures/`, written by the deleted failure hook.
- `plan/.telemetry-receipts/`, written by the deleted receipt hook.
- The installed `hooks/context-mode/` and `hooks/telemetry/` folders, plus the `check-telemetry-*.mjs` and `phase-enum.mjs` copies, written by earlier setup runs.
<!-- END retired-integrations (0000030) -->

---

## Invariants

- The file, when present, always corresponds to the most recent install or refresh attempt for the tool named in `tool`, it is overwritten in place on every write, never appended to
- `attemptStatus: pending` never persists past a successful `setup.sh`/`setup.ps1` completion; REQ-005 on success writes `attemptStatus: completed` (via the same REQ-008 write path), closing the window REQ-010 detects
- `attemptedCommand`, when absent, means exactly that (no refresh attempt was recorded), never inferred or defaulted from other state
- No retired flag and no `backendUrl` is ever written, so a replay of an old marker prints the notice at most once and then rewrites the marker without it
- The file is local, uncommitted repo state (not checked into version control), it describes *this* repo's current install, not a shared or synced record

---

## Migration History

| ID | Version | Description | Status | Destructive |
|----|---------|------------|--------|------------|
| M-001 | 0.1.0 | Initial schema, introduced by feature 0000020-setup-refresh-skill | proposed | no |
| M-002 | 0.1.0 | Dropped the `backendUrl` field. The field was optional, so no reader breaks (0000030). The schema version stays 1.0.0 | applied | no |

---

*Generated by codegen-agent. Updated via migration proposals. Path: `src/setup-hook-integration/docs/data-contract.md`*
