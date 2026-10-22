---
title: "Requirement: req-002 - product-yml-in-p7"
summary: "The ship agent sets product.yml version and feature in P7, before the archive step, through a fixed framework script under a narrow Hard Limit 8 carve-out."
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
- The new script is an architectural choice beyond the P0 text, so a P2 ADR records it, with the Hard Limit 8 carve-out above.
- The script rewrites the two lines in place. It never appends a line. Running it twice with the same arguments gives a byte-identical file.
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
- `--create` needs `--product-id`, `--product-name`, and at least two `--component` arguments. If one is missing, the script writes nothing and exits 2. If `product.yml` already exists, `--create` has no effect.
- The ship agent never creates `product.yml` through **Write**. Downstream, a **Write** to a root file the design doesn't list would meet `gate-write`. The script's fixed rules and the carve-out limits above govern the create instead.
- A stale `product.yml` stays as it is until the next P7 corrects it. No later step repairs it, and the ship agent does not edit it at Step 9 or Step 10b.
- Step 7 stages `product.yml` with the archive, changelog, and `docs/about.md`, in the same commit.
- Step 9 only reads the version through `product-version.mjs` and validates it. Step 9 no longer contains an instruction to update `product.yml`. If the derived version differs from the tag's expected version, Step 9 stops and reports, and it does not edit the file.
- The installed copy under `.claude/skills/` stays a copy of the source and is not edited by hand.

### Hard Limit 8 carve-out

- Hard Limit 8 bars an agent from changing code and project files through the shell. It targets content the agent composes and writes past the gates.
- A fixed framework script that skill text calls is a sanctioned tool, as `archive-current.mjs` is (0000033 ADR 010). The script has fixed behaviour and its own suite.
- The agent never passes content to the script. It passes only `--feature-id`, `--version`, `--create`, `--product-id`, `--product-name`, `--component`, and `--root`.
- The carve-out has these limits:
  - The script writes only `{root}/product.yml`.
  - It changes only the `version`, `feature`, and `components[]` fields, plus the `--create` fields `id`, `name`, and `versionPolicy`.
  - It refuses any other path.
- The P2 ADR records this carve-out and its limits. It also states that the carve-out covers no other script.
- The script resolves its target as `{root}/product.yml` and checks the resolved real path before it writes. If the target resolves to any other path, for example through a link, the script writes nothing and exits 2 with the reason on stderr.
- `{root}` is never a free choice. The `--root` rule in Input Validation binds it to the folder that `resolveRoot` returns. That folder can be a nested folder that holds its own `planifest-framework/`. The write then lands only where `gate-write` already resolves the root.
- The script runs every Input Validation rule before it reads `product.yml`. A rule break exits 2 before the `versionPolicy` table or the exit 4 check applies.
- The script writes each value only as a double-quoted YAML scalar, after validation. No allowed character can end the scalar or start a new line, so no argument can add a key.

### Hard Limit 8 text in the boot templates

- P3 adds one sentence to Hard Limit 8 in `planifest-framework/templates/standard-boot.md` (line 14) and `planifest-framework/templates/cursor-boot.md` (line 20).
- The sentence starts with `Sanctioned scripts:`. It names each framework script that skill text runs to write files, and it says no other script counts. A named script counts only when a skill step runs it.
- Both templates carry the same sentence, so every tool's boot file names the same list.
- A check of `planifest-framework/skills/` on 2026-10-22 found the scripts that skill text runs to write files. The sanctioned list is exactly these seven:
  - `planifest-framework/scripts/archive-current.mjs`, which the ship skill runs at P7.
  - `planifest-framework/scripts/set-product-release.mjs`, the new script in this requirement.
  - `planifest-framework/scripts/promote-to-regression.sh`, which the ship skill runs at P7 Step 4.
  - `planifest-framework/scripts/refresh-delete-boot-files.sh`, which the refresh-setup skill runs.
  - `planifest-framework/scripts/refresh-delete-boot-files.ps1`, the Windows form of the script above.
  - `planifest-framework/setup.sh`, which the refresh-setup skill reruns.
  - `planifest-framework/setup.ps1`, the Windows form of `setup.sh`.
- Skill text also runs scripts that write no file, such as `run-mode.mjs`, `product-version.mjs`, `consistency-check.mjs`, and `stream-reconcile.mjs`. They need no carve-out and stay off the list.
- If a later feature adds a script that skill text runs to write files, that feature adds it to the sentence in both templates.
- The boot files are build outputs. On every setup run, `write_boot_file` in `planifest-framework/setup.sh` rewrites each tool's boot file from its template (0000029 ADR 001). `Write-PlanifestBootFile` in `setup.ps1` does the same.
- The root `CLAUDE.md` comes from `standard-boot.md` through `planifest-framework/setup/claude-code.sh`. The root `AGENTS.md` comes from the same template through `planifest-framework/setup/codex.sh`.
- The root `.gitignore` lists `CLAUDE.md` and `AGENTS.md`, so P3 edits only the two templates. The next setup run in any project carries the sentence into its boot file.
- This repo's own `CLAUDE.md` keeps the old Hard Limit 8 text until setup runs again. Nothing in this feature reruns setup before P7. At P7, the ship agent runs `set-product-release.mjs` on the same footing as `archive-current.mjs` (0000033 ADR 010), and the P2 ADR records the rule.
- The P2 ADR names the sanctioned list and points to this sentence.

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
  - With `product.yml` a link to a file outside `{root}`, the script exits 2, writes nothing, and leaves the link target unchanged.
- [ ] The suite checks the ship skill source text. The `product.yml` step comes before Step 6. Step 7 stages `product.yml`. Step 9 holds no instruction to edit `product.yml`.
- [ ] `product.yml` reads `0.33.0` and `0000035-write-gate-scope-and-path-hardening` at P9.
- [ ] The suite runs one case for each rule in the Input Validation section. Each case expects exit 2, a stderr reason that names the argument, no raw value on stderr, and a byte-identical `product.yml`.
- [ ] A suite case passes a `--feature-id` that holds a newline followed by `versionPolicy: "explicit"`. The script exits 2, and `product.yml` stays byte-identical.
- [ ] A suite source check asserts that `standard-boot.md` and `cursor-boot.md` each hold one `Sanctioned scripts:` sentence inside Hard Limit 8. Both sentences name the same scripts, and that set equals the seven in the sanctioned list.

## Dependencies

- `planifest-framework/scripts/product-version.mjs` and its exit codes (0, 2, 4, 5), unchanged.
- `planifest-framework/skills/planifest-ship-agent/SKILL.md` Step 6, Step 7, and Step 9 (0000016 ADR 002, 0000033 ADR 010).
- `planifest-framework/component.yml` carries `0.33.0` before P7 runs. It is a design-confirmed precondition and not part of this requirement.
- No dependency on req-001 or req-003 to req-007.
- `resolveRoot` in `planifest-framework/hooks/enforcement/path-rules.mjs`, which the `--root` rule calls. Req-004 and req-006 change how it treats a deleted cwd and a planted marker. Neither change alters its result for a script run inside the repo, so the build order stays as it is.

## Input Validation

Every argument to `set-product-release.mjs` is untrusted. The agent composes each value, and no write gate judges the write that follows. Each pattern must match the whole value.

- [ ] Input source: the command-line arguments `--root`, `--feature-id`, `--version`, `--product-id`, `--product-name`, and `--component`.
- [ ] `--root`: the script imports `resolveRoot` from `path-rules.mjs` and calls it with its working directory. The real path of `--root` must equal the folder it returns. That folder must hold a `planifest-framework/` folder. Any other value exits 2.
- [ ] `--root` default: without `--root`, the root is the folder that `resolveRoot` returns, under the same `planifest-framework/` check. If `resolveRoot` returns `null`, the script exits 2.
- [ ] Allowed character pattern for `--feature-id`: `^[0-9]{7}-[a-z0-9-]+$`, at most 80 characters.
- [ ] Allowed character pattern for `--version`: strict semver `MAJOR.MINOR.PATCH`, `^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$`, at most 32 characters. A prerelease or build suffix exits 2.
- [ ] Allowed character pattern for `--product-id`: kebab-case `^[a-z0-9][a-z0-9-]*$`, at most 64 characters.
- [ ] Allowed character pattern for `--product-name`: `^[A-Za-z0-9 .-]+$`, 1 to 80 characters. The pattern admits letters, digits, space, hyphen, and full stop only, so no newline, quote, or backslash passes.
- [ ] `--component "{id}={path}"`: the script splits the value at the first `=`. `{id}` matches `^[a-z0-9][a-z0-9-]*$`, at most 64 characters.
- [ ] `--component` path: `{path}` matches `^[A-Za-z0-9._/-]+$`, 1 to 256 characters. It is `component.yml` or ends in `/component.yml`.
- [ ] `--component` path: `{path}` can't start with `/`, hold a `..` segment, or hold an empty segment. The file must exist, and its real path must lie inside the root.
- [ ] A call takes at most 64 `--component` arguments, and no two share an `{id}`. Every other argument appears at most once. An unknown argument exits 2.
- [ ] maximum length: each cap above applies to the raw value. A longer value exits 2. The script never truncates a value.
- [ ] Failure behaviour: any rule break writes nothing and exits 2. The script never strips characters to repair a value.
- [ ] Logging policy: the stderr reason names the argument and the broken rule. It never echoes the raw value.
- [ ] Suite cases: one case for each rule above. They include a `--root` subfolder and a `--root` outside the repo. They also include a newline in `--feature-id`, a quote in `--product-name`, a prerelease `--version`, and a `--component` path with `..`.
