---
title: "ADR 011: Hard Limit 8 sanctioned scripts"
summary: "Hard Limit 8 gains a narrow carve-out for fixed framework scripts that skill text runs to write files. Both boot templates carry one Sanctioned scripts sentence that names exactly seven scripts. set-product-release.mjs writes only product.yml fields under strict input validation. The carve-out covers no other script."
status: "accepted"
version: "0.1.0"
---
# ADR-011 - Hard Limit 8 sanctioned scripts

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000035-write-gate-scope-and-path-hardening
**Component:** planifest-framework
**Date:** 2026-10-22

## Context

Hard Limit 8 says every change to code and project files goes through **Write** or **Edit**, never through Bash. It bars "a script, or an interpreter one-liner". The rule exists because the shell guard can't see writes made inside scripts. An agent could compose content and write it past the gates.

Skill text already runs fixed framework scripts that write files. The ship skill runs `archive-current.mjs` at P7 (0000033 ADR 010). The refresh-setup skill reruns `setup.sh`. The boot text doesn't name these as allowed, so the rule and the skills disagree.

ADR-010 adds `set-product-release.mjs`. It writes `product.yml`, and no write gate judges that write. Risk R-020 records the danger. A wrong root or a crafted argument would write past the gate. Requirement req-008 holds the carve-out, its limits, and the argument rules that this ADR records.

The boot files are build outputs. On every setup run, `write_boot_file` in `setup.sh` and `Write-PlanifestBootFile` in `setup.ps1` rewrite each boot file from its template (0000029 ADR 001). The root `CLAUDE.md` and `AGENTS.md` come from `standard-boot.md`, and the root `.gitignore` lists both.

## Decision

- **Carve-out:** A fixed framework script that a skill step runs to write files is a sanctioned tool under Hard Limit 8. The agent passes it arguments and never content. A named script counts only when a skill step runs it.
- **Boot text:** P3 adds one sentence that starts with `Sanctioned scripts:` to Hard Limit 8 in two templates:
  - `planifest-framework/templates/standard-boot.md`
  - `planifest-framework/templates/cursor-boot.md`

  Both templates carry the same sentence. It names each sanctioned script and says no other script counts.
- **Sanctioned list:** The list holds exactly these seven scripts:
  1. `planifest-framework/scripts/archive-current.mjs`
  2. `planifest-framework/scripts/set-product-release.mjs`
  3. `planifest-framework/scripts/promote-to-regression.sh`
  4. `planifest-framework/scripts/refresh-delete-boot-files.sh`
  5. `planifest-framework/scripts/refresh-delete-boot-files.ps1`
  6. `planifest-framework/setup.sh`
  7. `planifest-framework/setup.ps1`
- **No other script:** The carve-out covers no other script. Scripts that skill text runs but that write no file, such as `run-mode.mjs`, `product-version.mjs`, `consistency-check.mjs`, and `stream-reconcile.mjs`, stay off the list. A later feature that adds a file-writing script to skill text must add it to the sentence in both templates.
- **Limits on `set-product-release.mjs`:**
  - It accepts only `--feature-id`, `--version`, `--create`, `--product-id`, `--product-name`, `--component`, and `--root`.
  - It writes only `{root}/product.yml` and refuses any other path.
  - It changes only `version`, `feature`, and `components[]`, plus `id`, `name`, and `versionPolicy` under `--create`.
  - It resolves the real path of the target before it writes. If a link points elsewhere, it writes nothing and exits 2.
  - It writes each value only as a double-quoted YAML scalar, after validation. No allowed character can end the scalar or start a line.
  - It takes the root from the working directory only and clears `CLAUDE_PROJECT_DIR` for its `resolveRoot` call.
  - It opens `product.yml` once with `O_NOFOLLOW` and reads through that descriptor. The file must be regular with exactly one link, so a hard link exits 2.
  - It writes to a temp file in the root and renames it over `product.yml`. A failure removes the temp file and leaves `product.yml` unchanged.
  - It applies the `--component` path rules to each `components[].path` it reads from `product.yml`.
  - An unexpected file-system error exits 2. The reason names the operation and error code only, with no path or stack trace.
- **Input Validation:** The script treats every argument as untrusted and runs every rule before it reads `product.yml`. Each pattern must match the whole value:

  | Argument | Rule |
  |---|---|
  | `--root` | Its real path must equal the folder that `resolveRoot` in `path-rules.mjs` returns for the working directory. That folder must hold `planifest-framework/`. Without `--root`, the script uses that folder, and a `null` result exits 2. |
  | `--feature-id` | `^[0-9]{7}-[a-z0-9-]+$`, at most 80 characters. |
  | `--version` | `^(0\|[1-9][0-9]*)\.(0\|[1-9][0-9]*)\.(0\|[1-9][0-9]*)$`, at most 32 characters. A prerelease or build suffix fails. |
  | `--product-id` | `^[a-z0-9][a-z0-9-]*$`, at most 64 characters. |
  | `--product-name` | `^[A-Za-z0-9 .-]+$`, 1 to 80 characters. |
  | `--component` id | Split at the first `=`. The id matches `^[a-z0-9][a-z0-9-]*$`, at most 64 characters. |
  | `--component` path | `^[A-Za-z0-9._/-]+$`, 1 to 256 characters. It is `component.yml` or ends in `/component.yml`. It can't start with `/` or hold a `..` or empty segment. The file must exist, and its real path must lie inside the root. |
  | Counts | At most 64 `--component` arguments, with no shared id. Every other argument appears at most once. An unknown argument fails. |

  Any rule break writes nothing and exits 2. The script never truncates or strips a value to repair it. The stderr reason names the argument and the rule, and it never echoes the raw value.
- **This repo's boot file:** This repo's own `CLAUDE.md` keeps the old Hard Limit 8 text until setup runs again. Nothing in this feature reruns setup before P7. At P7, the ship agent runs `set-product-release.mjs` on the same footing as `archive-current.mjs`, under this ADR.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| No carve-out, leave the boot text as it is | No rule change | Skills keep running scripts that the boot text forbids, and `set-product-release.mjs` has no stated footing | Rule and practice would keep disagreeing |
| A general rule that any framework script counts | Short boot text | Any script under `planifest-framework/` would qualify, including one an agent writes there | Too wide, and it invites a self-made exemption |
| Name only `set-product-release.mjs` | Smallest change | `archive-current.mjs` and setup stay outside the rule while skills run them | Leaves the existing disagreement in place |
| Edit the root `CLAUDE.md` directly | The rule takes effect in this repo at once | `CLAUDE.md` is a build output that setup overwrites, and `.gitignore` lists it | The template is the source, and setup carries the change |
| Hook check on script arguments | A second control on the script | No hook sees writes inside a script, and the shell guard is a heuristic | The script's own validation sits where the write happens |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | Both boot templates gain the `Sanctioned scripts:` sentence. `set-product-release.mjs` implements the limits and validation, and its suite tests each rule. |
| setup-hook-integration | None. Setup already rewrites each boot file from its template. |

## Consequences

**Positive:**
- Hard Limit 8 and the skills now agree on which scripts may write files.
- The list is closed, so an agent can't claim a new script is sanctioned.
- A suite source check can compare the two templates against the seven-script list.

**Negative:**
- Every new file-writing script in skill text needs a boot template change in the same feature.
- This repo runs on the old boot text until setup reruns, so the rule here lives in this ADR until then.
- The validation rules in `set-product-release.mjs` add test cases and upkeep.

**Risks:**
- R-020: a gap in the validation could let a crafted argument write past the gate. The suite runs one case for each rule, including a newline injection in `--feature-id`.
- A future skill could run a file-writing script and forget the boot sentence. The suite source check catches drift between the two templates only, not a missing script.

## Related ADRs

- ADR-010 - depends-on: adds `set-product-release.mjs`, which this carve-out covers.
- 0000033 ADR 010 - related-to: `archive-current.mjs` is the first sanctioned script.
- 0000029 ADR 001 - depends-on: boot files are build outputs from their templates.

## Supersedes

- None

## Superseded By

- None
