---
title: "Backlog Entry: 0000302 - governed bring-your-own skills"
summary: "Make ravintio-overrides/capability-skills/ the only skill route, and install a skill only when a human-approved provenance record and licence check pass."
status: "open"
---
# Backlog Entry: 0000302 - governed bring-your-own skills

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Feature Pipeline
**Related:** 0000301, 0000288, 0000286, 0000272

---

## Context

A review of the sibling repo RAVINTIO Zero on 2026-10-31 compared how each pack installs skills that a team brings. Framework targets regulated industries, such as those that follow GAMP 5. There, installed agent guidance is a configuration item. It needs a pinned source, a licence, and a named approver. Once 0000301 removes the bundled library, a team still needs a governed way to add its own skills.

## Problem

Framework has two routes for a team's own skills, and neither records where a skill came from:

- **Permanent route.** `ravintio-overrides/capability-skills/{name}/`. `setup.sh` lines 229 to 262 copy only `SKILL.md`, so a skill's `references/`, `scripts/`, and `assets/` folders never install. Zero backlog 0000289 records the same fault.
- **Plan-scoped route.** `plan/current/capability-skills/`. Setup never registers it with the tool. `scripts/archive-current.mjs` line 63 deletes it at archive.

Neither route checks the licence, pins the source, or asks for approval.

## Suggested Action

Make `ravintio-overrides/capability-skills/{name}/` the only skill route. Each folder carries the whole skill, a verbatim `LICENSE`, and a `provenance.yml` with these fields:

- `source_url` and a pinned `commit_sha`
- `licence` as an SPDX identifier, and `copyright_holder`
- `content_sha256`, the hash of the folder without `provenance.yml`
- `approved_by`, `approved_on`, and `review_notes`

Setup installs a skill only when every check passes:

1. `provenance.yml` parses.
2. The licence is on the allowlist. The default allowlist is MIT, Apache-2.0, BSD-2-Clause, BSD-3-Clause, and ISC. A human can change it in `ravintio-overrides/setup-config/`.
3. `LICENSE` exists.
4. The folder hash matches `content_sha256`.
5. `approved_by` is set.

A failed check skips that skill with a warning that names the check. Setup copies whole folders, including `references/`, `scripts/`, and `assets/`.

Agents never fill `approved_by`, as with `.ratchet-approve`. Skill-inbox intake at P0 drafts `provenance.yml` and leaves the approval fields blank.

Retire the plan-scoped route.

## Wanted outcome

Every installed skill traces to a pinned source, an allowed licence, and a named human approver. Setup refuses the rest and says why.

## Open questions

- Should the approval check also read `git log` to confirm a human commit set `approved_by`, as the run-mode anchor does?
- Should a changed hash after approval block the skill, or warn and keep the last approved copy?

## Why Deferred

The human asked for it on 2026-10-31. It needs its own design and an ADR, and it depends on 0000301.
