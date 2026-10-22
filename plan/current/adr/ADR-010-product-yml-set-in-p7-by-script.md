---
title: "ADR 010: product.yml set in P7 by a script"
summary: "The ship agent sets product.yml version and feature in P7, after Step 5 and before Step 6 archives design.md. A new fixed script, set-product-release.mjs, makes every product.yml write. It applies each versionPolicy, creates the file with --create, replaces components[] only through --component, and reports through fixed exit codes. The ship agent owns product.yml."
status: "accepted"
version: "0.1.0"
---
# ADR-010 - product.yml set in P7 by a script

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000035-write-gate-scope-and-path-hardening
**Component:** planifest-framework
**Date:** 2026-10-22

## Context

Backlog 0000124 reports that `product.yml` falls behind the release. The ship skill updates it at P9 Step 9. By then Step 6 has archived `design.md`, so `gate-write` has no design that lists the root file. A **Write** to `product.yml` downstream is blocked, and an `explicit` version policy then blocks a correct release. In this repo `product.yml` still reads `0.30.0` and `0000031-ci-test-and-powershell-coverage`.

The P0 design moved the update into P7, before Step 6, and kept the gate unchanged for root files. A P7 **Write** still meets `gate-write` downstream unless the design lists `./product.yml`. Most designs don't.

0000033 ADR 010 set a precedent for this kind of step. A fixed framework script, `archive-current.mjs`, does the P7 archive. The script can run twice safely and has its own fixture suite.

0000016 ADR 002 defines `product.yml`, its three version policies, and `product-version.mjs` with exit codes 0, 2, 4, and 5. This ADR keeps that script and those codes unchanged.

## Decision

- **Step placement:** The ship skill gains a `product.yml` step after Step 5 and before Step 6. Step 7 stages `product.yml` with the archive, the changelog, and `docs/about.md` in one commit.
- **Script:** A new `planifest-framework/scripts/set-product-release.mjs` makes the update. It uses Node built-ins only and follows the house style of `product-version.mjs` and `archive-current.mjs`. The call is:

  `node planifest-framework/scripts/set-product-release.mjs --feature-id "{feature-id}" --version "{version}" [--create --product-id "{id}" --product-name "{name}"] [--component "{id}={path}" ...] [--root <dir>]`

  The ship agent takes `{version}` from the version that the human on the loop confirmed in `design.md` at P0.
- **Edit in place:** The script rewrites the top-level `version` and `feature` lines in place and never appends a line. Two runs with the same arguments give a byte-identical file.
- **versionPolicy behaviour:**

  | versionPolicy | Behaviour | Exit |
  |---|---|---|
  | `max-component-version` | Derive the version with the `product-version.mjs` rule, applied to the content the script is about to write. If it differs from `--version`, write nothing. If it matches, write `version` and `feature`. | 2 on a mismatch, 0 on success |
  | `explicit` | Write `--version` and `feature`. `--version` must be strict `MAJOR.MINOR.PATCH`. | 2 on a bad version, 0 on success |
  | `external` | Write `feature` only and leave `version` as it is. Step 9 must consult the external anchor or the human on the loop. | 5 |

- **Exit codes:**

  | Code | Meaning |
  |---|---|
  | 0 | The file was written, or it already held the same values. |
  | 2 | An argument broke a rule, the manifest is invalid, the derived version differs, or the target resolves elsewhere. The script wrote nothing, and the reason is on stderr. |
  | 4 | `product.yml` doesn't exist and `--create` is absent. The script wrote nothing. |
  | 5 | The policy is `external`. Only `feature` changed. |

- **Create:** With `--create` and no `product.yml`, the script builds the file from `planifest-framework/templates/product.template.yml`. It sets `id`, `name`, `version`, and `feature` from its arguments. It sets `versionPolicy: max-component-version` and writes `components[]` from the `--component` arguments. Then it applies the `max-component-version` row. `--create` needs `--product-id`, `--product-name`, and at least two `--component` arguments, or the script exits 2. If `product.yml` exists, `--create` has no effect.
- **No-file cases:** On exit 4, the ship agent follows the existing cases before Step 6:
  - With one component, it does nothing, and Step 9 reads that `component.yml`.
  - With two or more components, it reruns the script with `--create`. This moves Step 9 case 3 into P7.
- **components[] ownership:** The script leaves `components[]` byte-identical unless the ship agent passes `--component`. If a component was added or removed in the feature, the ship agent passes one `--component` for each component in the design. The script then replaces the whole list with those entries.
- **Step 9:** Step 9 only reads and validates the version through `product-version.mjs`. It holds no instruction to edit `product.yml`. If the derived version differs from the expected tag, Step 9 stops and reports.
- **Stale file:** A stale `product.yml` stays as it is until the next P7 corrects it. No later step repairs it.
- **Data ownership:** The ship agent owns `product.yml`. It writes the file only through `set-product-release.mjs`, never through **Write** or **Edit**. `product-version.mjs` and P9 Step 9 read it. No other skill, script, or hook writes it.
- **Shell rule:** The script runs under the sanctioned-script carve-out in ADR-011.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Keep the P9 update and relax `gate-write` for `product.yml` | No new script | Widens the gate for a root file in every project | The P0 design keeps the gate unchanged for root files |
| P7 **Write** or **Edit** by the ship agent | No new script | Downstream, `gate-write` blocks it unless the design lists `./product.yml` | The block is the defect that 0000124 reports |
| Every design lists `./product.yml` | Uses the existing gate | Each design must remember it, and a missed line blocks the release | Fragile, and it widens every design's scope |
| Ship agent edits `components[]` by hand, script sets two lines | Smaller script | Two write paths for one file, one of them through **Edit** | One Node path for every write is easier to test and to bound |
| Script appends lines when a key is missing | Tolerates odd files | A second run can add duplicate keys | In-place rewrite keeps the update idempotent |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | Gains `scripts/set-product-release.mjs` and its suite. The ship skill gains the P7 step, Step 7 stages `product.yml`, and Step 9 loses its edit instruction. |
| setup-hook-integration | None. Setup copies the new script with the rest of `scripts/`. |

## Consequences

**Positive:**
- `product.yml` names the released version and feature after every run, under every policy.
- Downstream projects release without a design line for `./product.yml`, and the gate stays as strict as before.
- A fixture suite can test every policy, the create path, and each exit code.

**Negative:**
- One more framework script to maintain, with its own validation rules.
- No write gate judges the script's write, so the script's own rules must carry that control (ADR-011).
- A `max-component-version` mismatch now stops P7, where before it surfaced at P9.

**Risks:**
- A wrong `--version` from the ship agent under `explicit` would record a wrong release. Step 9 still validates the version before it tags.
- A downstream `product.yml` whose shape differs from the template may fail the in-place rewrite. The script then exits 2 and writes nothing, and the human on the loop sees the reason.

## Related ADRs

- ADR-011 - related-to: records the Hard Limit 8 carve-out this script runs under.
- 0000033 ADR 010 - extends: follows the `archive-current.mjs` precedent for a fixed P7 script.
- 0000016 ADR 002 - depends-on: keeps `product.yml`, its policies, and `product-version.mjs` unchanged.

## Supersedes

- None

## Superseded By

- None
