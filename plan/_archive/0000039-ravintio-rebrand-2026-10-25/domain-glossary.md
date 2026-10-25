---
title: "Domain Glossary - ravintio-rebrand"
summary: "Definitions of the terms used in the RAVINTIO Framework rebrand."
status: "draft"
version: "0.1.0"
---
# Domain Glossary - ravintio-rebrand

**Skill:** [spec-agent](../skills/spec-agent-SKILL.md) (updated by any agent that introduces a new domain term)
**Feature:** 0000039-ravintio-rebrand
**Version:** 0.1.0

> The ubiquitous language for this feature. Prose writes the brand as RAVINTIO in block capitals. Paths and identifiers use lowercase `ravintio`. Variables use `RAVINTIO_`. Never invent new terms without adding them here.

## Terms

| Term | Definition | Aliases | Used In |
|------|-----------|---------|---------|
| RAVINTIO Framework | The product name for this pack. It replaces Planifest Framework in prose. The GitHub repo becomes `RAVINTIO/ravintio-framework`. | Planifest Framework (retired) | ravintio-framework, setup-hook-integration |
| RAVINTIO Zero | The sibling pack that renamed in its feature 0000160. Its rename map and migration design are prior art for this feature. This feature makes no change to it. | Planifest Zero (retired) | ravintio-framework |
| pack | The `ravintio-framework/` folder (renamed from `planifest-framework/`). Consumers copy it into a repo and run setup. | framework folder | ravintio-framework |
| consumer repo | A repo that has installed the pack. Consumer repos on 0.36.0 run the consumer migration to reach 0.37.0. | consumer, adopter | ravintio-framework |
| pack source repo | This repo, which holds the canonical source of the pack. The "Applies when" check skips the consumer migration here. | source repo | ravintio-framework |
| rename map | The single table of old names and new names in `design.md`. It covers prose, paths, identifiers, variables, markers, and other names. | | ravintio-framework |
| scripted pass | The one-off bulk rename in P3. It uses `git mv` for paths and a replace that skips the protected list. The script lives in a scratchpad and never in the repo. It is a recorded exception to Hard Limit 8. | bulk rename | ravintio-framework |
| protected list | The paths and names the scripted pass leaves unchanged. It covers history paths, vendored upstream text, split names, and files that tests read as history. | | ravintio-framework |
| split name (built name) | An old name that appears in pieces, so a plain replace misses or breaks it. Examples are `planifest-$s-agent`, brace expansions, `planifest-*` globs, the `/^\[planifest\]/i` regex, and `planifest_0000037_req008_XXXXXX` mktemp templates. Each one gets a test or a protected-list entry. | split literal, built name | ravintio-framework |
| history folders | `plan/_archive/`, `plan/changelog/`, `plan/_migrations/`, and the bodies of shipped migrations. They keep the old name byte-identical. | history paths | ravintio-framework |
| history reader | A test suite that reads git history, tags, diffs, or the history folders. 18 suites read git history and about 25 read the history folders. The rename must not break them. | history-reading suite | ravintio-framework |
| old-name read (legacy fallback) | A read of an old name that setup keeps through 0.x and removes at 1.0.0. The new name wins, with no warning. Examples are `PLANIFEST_SESSION_ID` and the old boot-file markers. Since the P6 change, `.planifest-setup-flags` is not one. | legacy fallback, legacy read | ravintio-framework |
| consumer migration | The migration `migrate-0.37.0-ravintio-rename.md` with its two helpers. It moves a consumer repo from the old pack to the RAVINTIO pack. | rename migration | ravintio-framework |
| helper | A Bash or PowerShell script that the consumer migration runs. The two are the `.sh` and the `.ps1` helper. They refuse symbolic links and junctions and never delete. | migration helper | ravintio-framework |
| backup folder | `.ravintio-backup/`. The helper moves the old pack to `.ravintio-backup/planifest-framework/` and never deletes it. An existing backup folder stops the helper before it moves anything. | | ravintio-framework |
| brand guard | A Bash suite that fails when a tracked live file brings back the old name, in any case, in a path or a line. It reads `git ls-files` minus the history paths and `plan/current/`. | guard test | ravintio-framework |
| allowlist entry | A brand guard exception made of a path regex, a line regex, and a reason. Sibling `planifest-docs` links and `_reference/` documents have entries. | | ravintio-framework |
| stale entry | An allowlist entry that no longer matches any live line. The brand guard fails on it. | | ravintio-framework |
| Applies when check | A condition in a migration that skips it where it does not apply. It skips this source repo, which then writes a `plan/_migrations/` record with outcome `not applicable` (0000035 ADR-010). | | ravintio-framework |
| marker file | A file the pack writes into a consumer repo so later runs can detect state. They are `.ravintio-session`, `.ravintio-manifest`, and `.ravintio-setup-flags`. The migration helper removes the old `.planifest-session`. It renames the old flags and manifest files to the new names in each tool folder and rewrites the manifest entries. Setup reads neither old file and stops while one exists. | | ravintio-framework |
| boot file | A consumer's tool boot file that setup writes. It holds the `<!-- ravintio-overrides:instructions:start -->` and `:end -->` markers. Setup replaces the old markers so no block appears twice. | | ravintio-framework |

## Gaps

- The design names the group "other names" for the `@ravintio` npm scope, the `[RAVINTIO]` log prefix, and the `RAVINTIO Strict Pipeline` workflow name. No single term covers them, so this glossary adds none.
- The sources do not define "boot file" on its own. The definition above is inferred from "boot-file markers" and "setup replaces" in `design.md` and `discovery.md`.
