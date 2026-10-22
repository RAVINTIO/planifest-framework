---
title: "Requirement: req-002 - product-yml-in-p7"
summary: "The ship agent sets product.yml version and feature in P7, before the archive step, through a fixed framework script under the narrow Hard Limit 8 carve-out in req-008."
status: "draft"
version: "0.1.0"
---
# Requirement: req-002 - product-yml-in-p7

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000035-write-gate-scope-and-path-hardening
**Source:** US-002 (backlog 0000124)
**Priority:** must-have

## User Story

> One requirement doc = one user story.

As the human on the loop, I see `product.yml` name the released version and feature after every run, so that an `explicit` version policy never blocks a correct release.

## Functional Requirements

- The ship skill source `planifest-framework/skills/planifest-ship-agent/SKILL.md` gains a step that updates `product.yml` in P7. The step sits after Step 5 and before Step 6, which archives `design.md`. The gate stays unchanged for root files.
- `set-product-release.mjs` writes `product.yml` through Node, and the ship agent never changes `product.yml` through **Write** or **Edit**.
- No write-gate hook judges the script's write. That is acceptable because the script's own rules replace the gate's judgement. The script has fixed behaviour, writes one file, and changes only the named fields. Its suite tests each rule.
- The script exists because a **Write** to `product.yml` downstream meets `gate-write` unless a design lists the root file. The script avoids that without relaxing the gate for root files.
- The update sets the top-level `version` and `feature` lines of `product.yml`. It changes `components[]` only when the ship agent passes `--component` arguments.
- The ship agent owns every `components[]` edit. If a component was added or removed in this feature, it passes one `--component "{id}={path}"` argument for each component in the design. The script then replaces the whole `components[]` list with those entries. Without `--component`, the script leaves `components[]` byte-identical.
- A new script `planifest-framework/scripts/set-product-release.mjs` makes the update. It follows the precedent of `archive-current.mjs` (0000033 ADR 010). The call is `node planifest-framework/scripts/set-product-release.mjs --feature-id "{feature-id}" --version "{version}" [--create --product-id "{id}" --product-name "{name}"] [--component "{id}={path}" ...] [--root <dir>]`. The ship agent takes `{version}` from the version the human on the loop confirmed in `design.md` at P0.
- The new script is an architectural choice beyond the P0 text, so a P2 ADR records it. [Req-008](req-008-sanctioned-scripts.md) holds the Hard Limit 8 carve-out it runs under, with its limits and argument rules.
- The script rewrites the two lines and leaves every other line as it is. It never appends a line. Running it twice with the same arguments gives a byte-identical file.
- The script writes the result to a temp file in the root, then renames it over `product.yml`. A failed write never leaves a truncated file. [Req-008](req-008-sanctioned-scripts.md) holds the rules for this write.
- An unexpected file-system error, such as `EACCES`, exits 2 with nothing written. The stderr reason names the operation and the error code only.
- Malformed `product.yml` content, such as a lone CR or U+2028 in a top-level key line, exits 2 with nothing written. Any error that no rule catches also exits 2 with a fixed message. Every exit is 0, 2, 4, or 5 (P5 re-review finding P-N2).
- The script handles each `versionPolicy` as follows:

  | versionPolicy | Behaviour |
  |---|---|
  | `max-component-version` | Derive the version with the `product-version.mjs` rule, applied to the content the script is about to write. With `--create` or `--component`, that content holds the new `components[]` list, so the script never reads a missing or old file. If the result differs from `--version`, exit 2 with the reason on stderr and write nothing. If it matches, write `version` and `feature`. |
  | `explicit` | Write `--version` and `feature`. `--version` must be valid `MAJOR.MINOR.PATCH`, otherwise exit 2 and write nothing. |
  | `external` | Write `feature` only and leave `version` as it is. Exit 5, so the ship agent knows Step 9 must consult the external anchor or the human on the loop. |

- If `product-version.mjs` exits 2 because the manifest is invalid, the script writes nothing and exits 2 with that reason. The ship agent shows the reason and applies the existing Step 9 rule, which never tags a fabricated version.
- If `product.yml` doesn't exist and `--create` is absent, the script writes nothing and exits 4. The ship agent then follows the existing no-file cases before Step 6:
  - With exactly one component, it does nothing. Step 9 reads that `component.yml`.
  - With two or more components, it reruns the script with `--create`, `--product-id`, `--product-name`, and one `--component` for each component. This moves Step 9 case 3 into P7.
- With `--create` and no `product.yml`, the script builds the file from `planifest-framework/templates/product.template.yml`. It sets `id`, `name`, `version`, and `feature` from its arguments. It sets `versionPolicy: max-component-version` and writes `components[]` from the `--component` arguments. It then applies the `max-component-version` row above.
- `--create` needs `--product-id`, `--product-name`, and at least two `--component` arguments. If one is missing, the script writes nothing and exits 2.
- The script validates `--product-id` and `--product-name` whenever they appear. It also checks the `--create` arguments when `product.yml` already exists. If they pass, it leaves `id`, `name`, and `versionPolicy` as they are and makes the normal update (P3 deviation, build log).
- `--create` copies the header comment of `product.template.yml` into each new `product.yml`. That comment names P7 and `set-product-release.mjs --create`, not the first multi-component P9 (P3 deviation, build log).
- The ship agent never creates `product.yml` through **Write**. Downstream, a **Write** to a root file the design doesn't list would meet `gate-write`. The script's fixed rules and the carve-out limits in req-008 govern the create instead.
- A stale `product.yml` stays as it is until the next P7 corrects it. No later step repairs it, and the ship agent does not edit it at Step 9 or Step 10b.
- Step 7 stages `product.yml` with the archive, changelog, and `docs/about.md`, in the same commit.
- Step 9 only reads the version through `product-version.mjs` and validates it. Step 9 no longer contains an instruction to update `product.yml`. If the derived version differs from the tag's expected version, Step 9 stops and reports, and it does not edit the file.
- The installed copy under `.claude/skills/` stays a copy of the source and is not edited by hand.

## Acceptance Criteria

- [ ] A suite, `planifest-framework/tests/test-0000035-req-002-product-yml-in-p7.sh`, builds a fixture repo and runs the close-out order for each case. The order is the P7 `product.yml` update, then the archive, then the commit, then the Step 9 derivation of the tag. For each case it checks the result:
  - Under `max-component-version` and `explicit`, `product.yml` `version` and `feature` match the tag and the feature ID.
  - A second run of the update leaves the file byte-identical.
  - A stale `product.yml` is corrected by the next run, and an unrelated line is left alone.
  - Under `external`, only `feature` changes and the script exits 5.
  - Under `max-component-version`, a `--version` that differs from the derived one exits 2 and leaves the file unchanged.
  - With no `product.yml`, the script exits 4 and writes nothing.
  - With no `product.yml` and `--create` with two components, the script creates the file under `max-component-version` with both `components[]` entries.
  - With `--component` arguments, `components[]` holds exactly those entries. Without them, `components[]` stays byte-identical.
- [ ] The suite checks the ship skill source text. The `product.yml` step comes before Step 6. Step 7 stages `product.yml`. Step 9 holds no instruction to edit `product.yml`.
- [ ] `product.yml` reads `0.33.0` and `0000035-write-gate-scope-and-path-hardening` at P9.

## Dependencies

- `planifest-framework/scripts/product-version.mjs` and its exit codes (0, 2, 4, 5), unchanged.
- `planifest-framework/skills/planifest-ship-agent/SKILL.md` Step 6, Step 7, and Step 9 (0000016 ADR 002, 0000033 ADR 010).
- `planifest-framework/component.yml` carries `0.33.0` before P7 runs. It is a design-confirmed precondition and not part of this requirement.
- [Req-008](req-008-sanctioned-scripts.md) constrains the script this requirement adds. It sets the carve-out limits, the real-path check on `{root}/product.yml`, and every argument rule. The req-008 suite owns the link case for that real-path check.
- No dependency on req-001, req-003 to req-007, req-009, or req-010.
