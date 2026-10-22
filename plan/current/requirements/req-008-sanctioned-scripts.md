---
title: "Requirement: req-008 - sanctioned-scripts"
summary: "Hard Limit 8 gains a narrow carve-out for fixed framework scripts that skill text runs to write files. Both boot templates name the seven sanctioned scripts, and set-product-release.mjs validates every argument before it writes."
status: "draft"
version: "0.1.0"
---
# Requirement: req-008 - sanctioned-scripts

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000035-write-gate-scope-and-path-hardening
**Source:** US-008 (backlog 0000124)
**Priority:** must-have

## User Story

> One requirement doc = one user story.

As the human on the loop, I rely on Hard Limit 8 to name every framework script that may write files, so that an agent never writes past the gates through any other script, and each named script writes only its own file.

## Functional Requirements

- This requirement constrains `planifest-framework/scripts/set-product-release.mjs`, which [req-002](req-002-product-yml-in-p7.md) adds. Req-002 owns the script's purpose, `versionPolicy` table, exit codes, `--create`, and `--component` behaviour. This requirement owns the carve-out, its limits, and the argument rules.
- The cases for this requirement live in their own suite, `planifest-framework/tests/test-0000035-req-008-sanctioned-scripts.sh`, because each requirement owns its suite. The req-002 suite keeps the close-out cases.

### Hard Limit 8 carve-out

- Hard Limit 8 bars an agent from changing code and project files through the shell. It targets content the agent composes and writes past the gates.
- A fixed framework script that skill text calls is a sanctioned tool, as `archive-current.mjs` is (0000033 ADR 010). `set-product-release.mjs` has fixed behaviour and its own suite.
- The agent never passes content to the script. It passes only `--feature-id`, `--version`, `--create`, `--product-id`, `--product-name`, `--component`, and `--root`.
- The carve-out has these limits:
  - The script writes only `{root}/product.yml`.
  - It changes only the `version`, `feature`, and `components[]` fields, plus the `--create` fields `id`, `name`, and `versionPolicy`.
  - It refuses any other path.
- The P2 ADR records this carve-out and its limits. It also states that the carve-out covers no other script.
- The script resolves its target as `{root}/product.yml` and checks the resolved real path before it writes. If the target resolves to any other path, for example through a link, the script writes nothing and exits 2 with the reason on stderr. This requirement's suite owns the link case for this check.
- `{root}` is never a free choice. The `--root` rule in Input Validation binds it to the folder that `resolveRoot` returns. That folder can be a nested folder that holds its own `planifest-framework/`. The write then lands only where `gate-write` already resolves the root.
- The root comes from the working directory only. The script clears `CLAUDE_PROJECT_DIR` for its `resolveRoot` call, so a caller can't set the variable to move the write (P5 finding P-S03).
- The script opens `product.yml` once with `O_NOFOLLOW` and reads it through that descriptor. `fstat` on the descriptor must show a regular file with exactly one link. A hard link at `product.yml` exits 2 and writes nothing (P-S04, P-S05).
- The script writes the new content to a temp file in the root, flushes it, then renames it over `product.yml`. The temp file has a random name, an exclusive create, and the mode of the old file. A failure removes the temp file and leaves `product.yml` unchanged (P-S06).
- An unexpected file-system error, such as `EACCES` or `EISDIR`, exits 2. The stderr reason names the operation and the error code. It never prints a path or a stack trace (P-S07).
- A top-level key line that the script can't rewrite, such as one that holds a lone CR or U+2028, exits 2 with a fixed message. An error that no rule catches exits 2 the same way, with no path or stack trace (P-N2).
- Each `components[].path` that the script reads from an existing `product.yml` meets the same path rules as `--component` (P-S08).
- The script opens each `component.yml` once with `O_NOFOLLOW` and reads it through that descriptor. `fstat` must show a regular file with exactly one link. A hard link exits 2, names the component, and never prints the path (P5 re-review finding P-N1).
- The script runs every Input Validation rule before it reads `product.yml`. A rule break exits 2 before the req-002 `versionPolicy` table or the exit 4 check applies.
- The script writes each value only as a double-quoted YAML scalar, after validation. No allowed character can end the scalar or start a new line, so no argument can add a key.

### Hard Limit 8 text in the boot templates

- P3 adds one sentence to Hard Limit 8 in `planifest-framework/templates/standard-boot.md` (line 14) and `planifest-framework/templates/cursor-boot.md` (line 20).
- The sentence starts with `Sanctioned scripts:`. It names each framework script that skill text runs to write files, and it says no other script counts. A named script counts only when a skill step runs it.
- Both templates carry the same sentence, so every tool's boot file names the same list.
- The sentence limits each script to the arguments its skill step shows (P5 finding P-S10). `setup.sh` and `setup.ps1` count only as a tool name plus `--include-full-skill-library` or `--strict-orchestrator`. Those are the invocations that the refresh-setup and orchestrator skills run. `add-skill` fetches remote content, so the sentence says that `add-skill` and every other subcommand or flag are not sanctioned.
- A check of `planifest-framework/skills/` on 2026-10-22 found the scripts that skill text runs to write files. The sanctioned list is exactly these seven:
  - `planifest-framework/scripts/archive-current.mjs`, which the ship skill runs at P7.
  - `planifest-framework/scripts/set-product-release.mjs`, the new script in req-002.
  - `planifest-framework/scripts/promote-to-regression.sh`, which the ship skill runs at P7 Step 4.
  - `planifest-framework/scripts/refresh-delete-boot-files.sh`, which the refresh-setup skill runs.
  - `planifest-framework/scripts/refresh-delete-boot-files.ps1`, the Windows form of the script above.
  - `planifest-framework/setup.sh`, which the refresh-setup skill reruns.
  - `planifest-framework/setup.ps1`, the Windows form of `setup.sh`.
- `promote-to-regression.sh` binds its source and destination (P5 finding P-S09):
  - The source must be a `test-*.sh` regular file with one link, directly inside `planifest-framework/tests/`.
  - The destination is always `planifest-framework/tests/regression/`. Neither that folder nor the destination file may be a link.
  - It refuses `PLANIFEST_REGRESSION_DIR` unless the variable names that same folder.
  - It refuses a `tests/` folder that is a link. The destination file and `regression-manifest.json` must each be a regular file with one link (P5 re-review finding P-N3).
  - It writes the test and the manifest to fresh temp files in `tests/regression/`, then renames each into place. It never writes through a link at a fixed temp path (backlog 0000147).
  - A break exits 1 and copies nothing.
- Skill text also runs scripts that write no file, such as `run-mode.mjs`, `product-version.mjs`, `consistency-check.mjs`, and `stream-reconcile.mjs`. They need no carve-out and stay off the list.
- If a later feature adds a script that skill text runs to write files, that feature adds it to the sentence in both templates.
- The boot files are build outputs. On every setup run, `write_boot_file` in `planifest-framework/setup.sh` rewrites each tool's boot file from its template (0000029 ADR 001). `Write-PlanifestBootFile` in `setup.ps1` does the same.
- The root `CLAUDE.md` comes from `standard-boot.md` through `planifest-framework/setup/claude-code.sh`. The root `AGENTS.md` comes from the same template through `planifest-framework/setup/codex.sh`.
- The root `.gitignore` lists `CLAUDE.md` and `AGENTS.md`, so P3 edits only the two templates. The next setup run in any project carries the sentence into its boot file.
- This repo's own `CLAUDE.md` keeps the old Hard Limit 8 text until setup runs again. Nothing in this feature reruns setup before P7. At P7, the ship agent runs `set-product-release.mjs` on the same footing as `archive-current.mjs` (0000033 ADR 010), and the P2 ADR records the rule.
- The P2 ADR names the sanctioned list and points to this sentence.

## Acceptance Criteria

- [ ] The suite `planifest-framework/tests/test-0000035-req-008-sanctioned-scripts.sh` runs one case for each rule in the Input Validation section. Each case expects exit 2, a stderr reason that names the argument, no raw value on stderr, and a byte-identical `product.yml`.
  - The suite also runs a link case. With `product.yml` a link to a file outside `{root}`, the script exits 2, writes nothing, and leaves the link target unchanged.
- [ ] A suite case passes a `--feature-id` that holds a newline followed by `versionPolicy: "explicit"`. The script exits 2, and `product.yml` stays byte-identical.
- [ ] A suite source check asserts that `standard-boot.md` and `cursor-boot.md` each hold one `Sanctioned scripts:` sentence inside Hard Limit 8. Both sentences name the same scripts, and that set equals the seven in the sanctioned list.

## Dependencies

- [req-002](req-002-product-yml-in-p7.md) adds `set-product-release.mjs`. Stream 02 builds req-002 and this requirement together, because both change the same script.
- `resolveRoot` in `planifest-framework/hooks/enforcement/path-rules.mjs`, which the `--root` rule calls. Req-004 and req-006 change how it treats a deleted cwd and a planted marker. Neither change alters its result for a script run inside the repo, so the build order stays as it is.
- No dependency on req-001, req-003, req-005 to req-007, req-009, or req-010.

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
- [ ] `components[].path` read from an existing `product.yml`: each value meets the two `--component` path rules above. A break exits 2, names the component, and writes nothing.
- [ ] `CLAUDE_PROJECT_DIR`: the script ignores it when it resolves the root, so the variable can't move the write.
- [ ] `product.yml` itself: a regular file with exactly one link, checked by `fstat` on the descriptor the script reads through. Anything else exits 2 and writes nothing.
- [ ] `promote-to-regression.sh` source and destination: the suite runs one case for each binding rule in the Functional Requirements. Each case expects exit 1 and no new file in `tests/regression/`.
- [ ] A call takes at most 64 `--component` arguments, and no two share an `{id}`. Every other argument appears at most once. An unknown argument exits 2.
- [ ] maximum length: each cap above applies to the raw value. A longer value exits 2. The script never truncates a value.
- [ ] Failure behaviour: any rule break writes nothing and exits 2. The script never strips characters to repair a value.
- [ ] Logging policy: the stderr reason names the argument and the broken rule. It never echoes the raw value.
- [ ] Suite cases: one case for each rule above. They include a `--root` subfolder and a `--root` outside the repo. They also include a newline in `--feature-id`, a quote in `--product-name`, a prerelease `--version`, and a `--component` path with `..`.
