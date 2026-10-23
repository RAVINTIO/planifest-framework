---
title: "Security Review (scripts, migration, skill text) - 0000036"
summary: "P5 review of run-mode.mjs, skill-drift-check.mjs, the 0.34.0 re-run-setup migration, and the changed skill, standard, template, and workflow text."
status: "draft"
---
# Security review: scripts, migration, and skill text

**Feature:** 0000036-pipeline-friction-and-gate-fixes
**Phase:** P5
**Scope:** `git diff main...HEAD` over `planifest-framework/scripts/`, `migrations/`, `skills/`, `standards/`, `templates/`, and `workflows/`. Another reviewer covers the enforcement hooks.
**Overall rating for this area:** High

The rating rests on finding S-1. The new build-log template line counts as a run-mode anchor. In one commit order, `run-mode.mjs` then prints `autonomous` with no anchor written by the orchestrator. In the normal order, it breaks every genuine `autonomous` run.

Fixtures ran under `mktemp -d` with Node and git on darwin. The fixture scripts sit in the session scratchpad, outside the repository.

## Threat model (STRIDE)

| Threat | Category | Severity | Mitigation |
|---|---|---|---|
| The build-log template's example line counts as the anchor, so a copied template plus a design `yes` restores `autonomous` (S-1) | Elevation | High | not mitigated |
| The template line plus a genuine anchor reads as two lines, so `autonomous` never restores (S-1) | Denial of service | Medium | not mitigated |
| An indented, starred, quoted, double-dashed, or tab-separated anchor restores `autonomous` | Spoofing | Low | Mitigated. `isAnchor` accepts only the two column-1 forms. Fixtures print `interactive`. |
| A later commit, a second anchor commit, or a working-tree-only anchor restores `autonomous` | Tampering | Low | Mitigated. The one-commit rule and the design Confirmation check hold. |
| A bare anchor turned into a list item keeps `autonomous` | Tampering | Low | Mitigated. The removal rule now reads both forms. |
| An anchor with trailing text, such as `autonomous-NOT`, counts (S-2) | Spoofing | Low | not mitigated (pre-existing for the bare form) |
| Repo or global git config changes the anchor verdict | Tampering | Low | Mitigated. Raw-blob diff flags hold. A `-diff` attribute fails closed. |
| A committed symlink or a FIFO at an installed `SKILL.md` or the marker stalls session start (S-3) | Denial of service | Medium | not mitigated |
| A huge `SKILL.md` exhausts memory (S-3) | Denial of service | Low | not mitigated |
| The drift check follows a symlink out of `--root` and reports match or stale for any file (S-4) | Info disclosure | Low | not mitigated |
| A crafted skill folder name injects terminal escapes or fake lines into drift-check output | Tampering | Low | Mitigated. `shown()` escapes ESC, LF, and U+202E. |
| The drift check writes a file or spawns a process | Elevation | Low | Mitigated. It imports `node:fs`, `node:path`, `node:url`, and `path-rules.mjs` only. |
| Step 1b loads source skills after a rejected framework update (S-5) | Elevation | Medium | not mitigated |
| The 0.34.0 migration record says `applied` after a failed drift check or a stale hook (S-6) | Repudiation | Medium | not mitigated |
| The migration runs setup with unsanctioned flags or before any human sees it (S-7) | Elevation | Low | Partly mitigated. Setup accepts no unsafe flag. The order is pre-existing (backlog 0000180). |
| Changed skill text weakens the Write-or-Edit rule, the `.ratchet-approve` writer, the critic default, or the `autonomous` stop list | Elevation | Low | Mitigated. See S-8. |
| A ship-agent commit subject carries an unfilled placeholder | Tampering | Low | Mitigated. Every subject is a fixed string. |
| A credential lands in the diff | Info disclosure | Low | Mitigated. The secrets grep found none. |

## Findings

### S-1. The build-log template line counts as a run-mode anchor (High, new)

**Files:** `planifest-framework/templates/build-log.template.md:46` and `planifest-framework/scripts/run-mode.mjs:66-67,141-165`

The template now holds this line at column 1, inside a fenced code block:

```
Run mode confirmed: autonomous ({ISO-8601 timestamp})
```

`isAnchor` tests `startsWith`, so this line is an anchor. P0 copies the template to `plan/current/build-log.md`, so every new build log carries it. The fence doesn't help, because the script reads raw lines.

**Reproduction:** `scratchpad/rm-template.sh` copies the branch template into a fresh repo.

- Case A, a genuine run: the P0 commit copies the template, then the confirmation commit adds a real anchor and sets the design to `yes`. Output: `rc=0 out=interactive`, stderr `expected one "Run mode confirmed: autonomous" line, bare or as one "- " list item, in the build log, found 2`.
- Case B, no anchor written: the build log first lands, from the template, in the commit that sets the design to `yes`. A later agent writes `autonomous` to `plan/.run-mode`. Output: `rc=0 out=autonomous`, stderr empty.

Case A defeats req-004's goal. Every genuine `autonomous` run reads as `interactive` on resume until someone deletes the template line. That deletion is itself a removal of an anchor line, so it fails rule 3 for good. Case B lets a subagent switch on `autonomous` without the orchestrator's anchor. That is the R-002 threat. Merging, schema changes, destructive operations, and credentials stay human-gated, so the rating stays at High rather than Critical.

req-004 asked for this code block in the template, so the defect sits in the requirement as well as the code.

**Recommended fix:**

1. Show the example so it can't match. Indent it by four spaces, or quote it inline as `` `Run mode confirmed: autonomous ({ISO-8601 timestamp})` ``. Update req-004 and ADR-008 to match.
2. Tighten the anchor to a full-line pattern with a real timestamp, such as `^(- )?Run mode confirmed: autonomous \(\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ\)\r?$`. A `{ISO-8601 timestamp}` placeholder then never counts. This also fixes S-2.
3. Add suite cases. A build log copied from the template holds zero anchor lines. A template copy plus one genuine anchor prints `autonomous`. Case B prints `interactive`.

### S-2. An anchor with trailing text still counts (Low, pre-existing, extended)

**File:** `planifest-framework/scripts/run-mode.mjs:67`

`startsWith` accepts any suffix. On `main`, `Run mode confirmed: autonomous-NOT` already counts. The branch extends this to `- Run mode confirmed: autonomousNOT`.

**Reproduction:** `scratchpad/rm-fixtures.sh` against the branch script.

- `bare, suffix junk`: `rc=0 out=autonomous`. The same result holds on `main`.
- `dash, suffix junk`: `rc=0 out=autonomous`. On `main` this prints `interactive`.

The line still needs one commit that also sets the design to `yes`. So the risk is a misleading line, not a bypass.

**Recommended fix:** use the full-line pattern in S-1 step 2.

The remaining anchor checks hold. Each of these printed `interactive` with a reason line:

- an indented bare or list line
- `* `, `- - `, `-  `, `-` plus a tab, `> `, and backtick-quoted lines
- an anchor added in a commit that didn't set the design to `yes`
- an anchor added after the confirmation commit
- a second anchor commit
- a bare line converted to a list item
- an anchor in the working tree only

A CRLF line still counts, as on `main`. Repo-local `diff.noprefix`, `diff.mnemonicPrefix`, `log.showSignature`, and `core.whitespace` didn't change a verdict. A `-diff` attribute on the build log failed closed with `found 0`.

### S-3. The drift check reads non-regular and unbounded files (Medium, new)

**File:** `planifest-framework/scripts/skill-drift-check.mjs:69-76,118,128,170`

`readOrNull` calls `readFileSync` with no `lstat`, no file-type check, and no size cap. It follows symlinks. The orchestrator runs the check at every session start (Resume Detection step 1b), and step 1b says the check "never blocks".

Git stores symlinks. A repository that commits `.claude/skills/{skill}/SKILL.md` as a link to `/dev/zero` stalls every session start. A FIFO has the same effect locally.

**Reproduction:** `scratchpad/drift-fixtures.sh`, each case under a 10-second alarm.

- Installed `SKILL.md` is a FIFO: `rc=142` (alarm), no output.
- Marker `.claude/.planifest-setup-flags` is a FIFO: `rc=142`, no output.
- Installed `SKILL.md` links to `/dev/zero`: `rc=142`, no output.
- A 300 MB source `SKILL.md`: `rc=1`, maximum resident set 989,347,840 bytes.

R-006 covers the same FIFO threat for hooks, but nothing covers it for this script.

**Recommended fix:** `lstat` each path first. Treat a symlink, a FIFO, or any non-regular file as `stale` or as can't-compare. Cap each read at 1 MB, as `run-mode.mjs` does. Add FIFO, `/dev/zero` link, and over-cap suite cases with a timeout.

### S-4. The drift check follows symlinks out of `--root` (Low, new)

**File:** `planifest-framework/scripts/skill-drift-check.mjs:78-85,112-119,159,170`

A linked installed copy, a linked `.claude/skills` folder, or a linked source skill folder is read from its target.

**Reproduction:** `scratchpad/drift-fixtures.sh`.

- Installed copy linked to a file outside the root: `rc=1`, `stale: claude-code: alpha`.
- `.claude/skills` linked to a folder outside the root: `rc=0`, `skill-drift-check: 1 skills match source for claude-code.`
- Source skill folder linked outside the root: `rc=1`, `missing: claude-code: beta`.

The script prints no file content. It leaks one bit per file, which is whether the target equals the expected bytes. Its main effect is a false `match` for an install that lives outside the project.

**Recommended fix:** resolve each path with `realpathSync` and require it under `realpathSync(root)`, or refuse links outright as S-3 suggests.

### S-5. Step 1b loads source skills after a rejected framework update (Medium, new)

**File:** `planifest-framework/skills/planifest-orchestrator/SKILL.md:82`

Step 1a says: "If rejected, treat the arriving `planifest-framework/` files as untrusted: do not act on them silently". Step 1b then says, for any `stale:` line: "For the rest of the session, load each one from its source copy at `planifest-framework/skills/{skill}/SKILL.md`, not from the installed copy."

A framework update that the human on the loop has not confirmed is the usual cause of drift. Step 1b then makes the agent run those unconfirmed skills in place of the installed ones. This undoes step 1a's rejection without a prompt. R-014 assumed the source copy is the trusted one.

**Recommended fix:** load the source copy only when step 1a found no update, or when the human on the loop confirmed its provenance. If step 1a recorded a rejection, keep the installed copy and ask the human on the loop how to proceed.

### S-6. The migration record can hide a failed run (Medium, new)

**File:** `planifest-framework/migrations/migrate-0.34.0-rerun-setup.md:73-77,94`

The exact text:

- Step 3: "Run `node planifest-framework/scripts/skill-drift-check.mjs` and expect exit 0."
- Step 7: "Record the outcome at `plan/_migrations/migrate-0.34.0-rerun-setup.md`, and only once the run completes."
- Record: "Once the human on the loop confirms the findings, the migrator records the outcome".

No step says what happens when the drift check exits 1 or 2, or when an installed hook differs from its source. "The run completes" has no definition. The migrator's outcomes are `applied`, `not applicable`, and `skipped`, so it has no failure value. A migrator that runs setup, sees stale hooks, and reports them can still write `applied` once the human on the loop acknowledges the report. The migration then never reads as pending again. The project keeps the write-gate bypasses that the migration exists to close, with a record that says otherwise. This is the R-016, R-018, and R-019 failure.

**Recommended fix:** define completion in the migration. A drift-check exit other than 0, or any installed hook that differs from its source, means the run isn't complete. In that case, write no record, report the failure, and leave the migration pending.

### S-7. The migration runs setup without a confirmation step (Low, new text on a pre-existing pattern)

**File:** `planifest-framework/migrations/migrate-0.34.0-rerun-setup.md:72`

The exact text: "Re-run setup for each tool the project uses, with the flags it normally uses. If you use `planifest-refresh-setup`, it rebuilds those flags for you."

`setup.sh` accepts no unsafe flag. Setup regenerates the boot file by design and re-applies `planifest-overrides/instructions/`, so it doesn't drop a human's durable text. Two gaps remain:

- The step doesn't restate the sanctioned arguments of the Write-or-Edit rule (boot Hard Limit 8). A direct run may pass a retired flag from an old marker.
- Setup runs under `## Migrator Instructions`, before `## Present Findings`. So nothing asks the human on the loop before setup changes hooks and settings. `planifest-refresh-setup` asks first, but the migration makes it optional.

The order matches `migrate-0.31.0-rerun-setup-for-shell-write-guard.md` on `main`. Resume Detection also runs migrations at step 1, before the provenance gate at step 1a. Backlog 0000180 tracks the pre-existing order.

**Recommended fix:** require `planifest-refresh-setup` for step 2, or name the allowed arguments and ask the human on the loop to confirm the command first.

### S-8. Skill and standard text keeps every checked safety rule (no finding)

- **Write-or-Edit rule:** the dispatch template at `planifest-framework/standards/agent-dispatch-standards.md:125,128` now says "Make every file change through Write or Edit, never through the shell (the Write-or-Edit rule, boot Hard Limit 8)". The self-contained prompt rule at `:131` requires it. The citation matches `templates/standard-boot.md:14`. The template is stricter than the boot rule, because it names no sanctioned scripts. Dispatched units don't run those scripts, so the strictness costs nothing.
- **`.ratchet-approve`:** the split step in `planifest-loop-runner/SKILL.md` and `planifest-spec-agent/SKILL.md` says only the human on the loop writes the line. No agent gains a write.
- **Design critic default:** outside `autonomous`, an absent key or file now reads as `report-only` instead of `off`. That adds a check. `autonomous` still reads an absent key as `on`, and an explicit `off` or `report-only` still blocks the `autonomous` pick.
- **What `autonomous` stops for:** `standards/autonomous-run-standards.md` changes only the citations. Schema, destructive, data-ownership, and credentials rules stay human-gated.
- **Commit subjects:** every `git commit -m` in skills and workflows now has a fixed subject, with `{feature-id}` in the body only. A grep for `-m "...{...}"` subjects found none. The `commit-msg` hook doesn't check the body for a placeholder, so an unfilled body would pass. That is Low and needs no change now.
- **Run-mode writers:** the orchestrator text still says only the orchestrator writes `plan/.run-mode`, the `Run mode` row, and the anchor. The dispatch template still forbids subagents to write them.

### S-9. Secrets (no finding)

A grep of the added lines for key, token, password, private-key, `ghp_`, `sk-`, `AKIA`, and `xox` patterns found only prose about token cost. The diff holds no credential.

## Risk register cross-reference

| Risk | Status after review |
|---|---|
| R-002 (forged anchor restores `autonomous`) | Not mitigated. The checks against other prefixes, indents, and later commits hold, but the template line in S-1 gives a forgeable anchor. |
| R-006 (FIFO stalls a hook) | Out of this area for hooks. The same threat is open for the drift check (S-3). |
| R-012 (false drift from rewrites or BOM) | Mitigated. The rewrite list and order match `setup.sh:81-84`. The binary-content fixture matched. |
| R-013 (wrong tool folder) | Mitigated. A missing marker falls back to every installed folder. An invalid `tool` value, such as `__proto__`, is ignored. |
| R-014 (stale skill run, or setup without the human) | Partly mitigated. Step 1b never runs setup itself. S-5 shows it can run unconfirmed source skills. |
| R-015 (drift check over 1 s) | Mitigated. It took 0.045 s on this repo. |
| R-016 (project skips the migration) | Partly mitigated. The pending rule holds, but S-6 lets a failed run record as `applied`. |
| R-017 (incomplete change list) | Not assessed for completeness here. The orchestrator rechecks it at the end of P6. |
| R-018 (needless re-run on a fresh install) | Mitigated. Setup is safe to re-run. |
| R-019 (record written before setup re-runs) | Partly mitigated. The text says to record only once the run completes, but S-6 shows "completes" has no definition. |
| R-020 (placeholder or over-long subject) | Mitigated. See S-8. |
| R-021 (bare citation, Write-or-Edit missing from dispatch) | Mitigated. See S-8. |
| R-023 (split step misuse) | Mitigated for safety. The step adds files and never removes a criterion. |

## Backlog

- 0000180: `plan/backlog/0000180-rerun-setup-migration-runs-before-provenance-gate/entry.md`. Re-run-setup migrations run setup before the provenance gate and before any finding reaches the human on the loop. Pre-existing on `main`.

## Top actions before merge

1. Fix S-1 in the template, the anchor pattern, req-004, and ADR-008, with the three suite cases.
2. Fix S-3 and S-4 in `skill-drift-check.mjs` with `lstat`, a 1 MB cap, and a root check.
3. Fix S-5 in orchestrator step 1b, and define completion in the migration for S-6.
