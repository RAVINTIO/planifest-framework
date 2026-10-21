---
title: "Requirement: req-002 - product-yml-in-p7"
summary: "The ship agent sets product.yml version and feature in P7, before the archive step, so the gate never blocks the update."
status: "active"
version: "0.1.0"
---
# Requirement: req-002 - product-yml-in-p7

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000035-write-gate-scope-and-path-hardening
**Source:** US-002 (backlog 0000124)
**Priority:** must-have

## User Story

> One requirement doc = one user story.

As the human on the loop, I see `product.yml` name the released version and feature after every run, so that an `explicit` version policy never blocks a correct release.

## Functional Requirements

- The ship skill source `planifest-framework/skills/planifest-ship-agent/SKILL.md` gains a step that updates `product.yml` in P7. The step sits after Step 5 and before Step 6, which archives `design.md`. While `design.md` exists, `gate-write` admits the update. The gate stays unchanged for root files.
- The update sets the top-level `version` and `feature` lines of `product.yml` and touches nothing else. It does not edit `components[]` unless a component was added or removed in this feature.
- A new script `planifest-framework/scripts/set-product-release.mjs` makes the update. It follows the precedent of `archive-current.mjs` (0000033 ADR-010). The call is `node planifest-framework/scripts/set-product-release.mjs --feature-id "{feature-id}" --version "{version}" [--root <dir>]`. The ship agent takes `{version}` from the version the human on the loop confirmed in `design.md` at P0.
- The script rewrites the two lines in place. It never appends a line. Running it twice with the same arguments gives a byte-identical file.
- The script handles each `versionPolicy` as follows:

  | versionPolicy | Behaviour |
  |---|---|
  | `max-component-version` | Run `product-version.mjs`. If its output differs from `--version`, exit 2 with the reason on stderr and write nothing. If it matches, write `version` and `feature`. |
  | `explicit` | Write `--version` and `feature`. `--version` must be valid `MAJOR.MINOR.PATCH`, otherwise exit 2 and write nothing. |
  | `external` | Write `feature` only and leave `version` as it is. Exit 5, so the ship agent knows Step 9 must consult the external anchor or the human on the loop. |

- If `product-version.mjs` exits 2 because the manifest is invalid, the script writes nothing and exits 2 with that reason. The ship agent shows the reason and applies the existing Step 9 rule, which never tags a fabricated version.
- If `product.yml` doesn't exist, the script writes nothing and exits 4. The ship agent then follows the existing no-file cases before Step 6:
  - With exactly one component, it does nothing. Step 9 reads that `component.yml`.
  - With two or more components, it creates `product.yml` from `planifest-framework/templates/product.template.yml` with `versionPolicy: max-component-version`. It then reruns the script. This moves Step 9 case 3 into P7.
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
- [ ] The suite checks the ship skill source text. The `product.yml` step comes before Step 6. Step 7 stages `product.yml`. Step 9 holds no instruction to edit `product.yml`.
- [ ] `product.yml` reads `0.33.0` and `0000035-write-gate-scope-and-path-hardening` at P9.

## Dependencies

- `planifest-framework/scripts/product-version.mjs` and its exit codes (0, 2, 4, 5), unchanged.
- `planifest-framework/skills/planifest-ship-agent/SKILL.md` Step 6, Step 7, and Step 9 (0000016 ADR-002, 0000033 ADR-010).
- `planifest-framework/component.yml` carries `0.33.0` before P7 runs. It is a design-confirmed precondition and not part of this requirement.
- No dependency on req-001 or req-003 to req-007.
