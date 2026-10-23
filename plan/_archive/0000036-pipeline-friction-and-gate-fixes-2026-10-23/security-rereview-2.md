---
title: "Security Re-review 2 - 0000036 P5 second fix round"
summary: "Fresh-context check of the N-1 to N-4 fixes, with reproductions and variants run against the fixed code, and a rerun of the earlier fixtures."
status: "draft"
---
# Security re-review 2: 0000036 P5 second fix round

**Feature:** 0000036-pipeline-friction-and-gate-fixes
**Phase:** P5
**Commit checked:** `3029a22` (N-1 to N-4)
**Platform:** macOS (Darwin 25.6.0), Node v26.12.0

## Result

Overall rating after the fixes: **Low**.

N-1 and N-4 hold in full. N-2 and N-3 hold for the reported case, but each leaves a Low gap next to it (M-1 and M-2). The earlier fixes S-1 to S-6 and hooks findings 1 and 2 still hold.

The full suite passes, and `run-mode.mjs` still prints `autonomous` in this repository.

Every fixture ran under `mktemp -d` with `CLAUDE_PROJECT_DIR` unset. The re-review scripts sit in the session scratchpad under `rr/`, outside the repository. This round adds `rr/swap3.mjs`.

## Per-finding verdicts

| ID | Original severity | Fixed | Evidence (command, exit code, key output) | Variant tried and result |
|---|---|---|---|---|
| N-1 | Low | Yes | `node rr/swap3.mjs path-rules.mjs "$(mktemp -d)" swap:sock`, exit 0. All three targets give `allowed=false` with the line `design.md is not a regular file, so the gate treats it as no design.` The same run against `path-rules.mjs` from `HEAD~1` gives `allowed=true` for all three targets. `node rr/swap2.mjs path-rules.mjs sock` now gives `allowed=false` for both targets. | Swaps after `lstatSync` to a link, a dangling link, a folder link, a FIFO, a folder, and a removal each give `allowed=false` with the not-regular line. A growth to 2 MiB gives `allowed=false` with the cap line. An injected `openSync` error gives `allowed=false` for every code tried: `EOPNOTSUPP`, `ENXIO`, `Unknown system error -102`, `EIO`, `EMFILE`, `EINTR`, `EAGAIN`, `EBUSY`, `ENODEV`, `EISDIR`, `ETIMEDOUT`, and no code. An injected `fstatSync` error of `EIO` or no code also blocks. Only `EACCES` and `EPERM` give `allowed=true`, at open or at fstat. That is the accepted mode 000 class (ADR-002, backlog 0000162). A `readSync` error still fails open, as the doc comment states. A hard link still gives `allowed=true`, which equals writing `design.md` directly. Legitimate regular designs still scope writes: plain, read-only `0444`, no final newline, CRLF, BOM, exactly 1,048,576 bytes, and `chflags uchg` each allow `src/allowed/a.js` and block the other two targets. An empty design warns and allows, as before. |
| N-2 | Low | Partly | `migrate-0.34.0-rerun-setup.md` step 7 now holds a fourth condition: "Setup reported no malformed settings file and no missing Node." The suite asserts it (`test-0000036-req-001`). | A settings file that setup can't write still passes all four conditions (M-1). A fixture run gave setup exit 0, drift check exit 0 (`21 skills match source`), every enforcement hook equal to its source, and a `settings.json` of `{}` with no hook wiring. |
| N-3 | Low | Partly | `planifest-orchestrator/SKILL.md` step 1b now loads source copies only in two named step 1a states. It lists the first session, a failed detection, a step 1a that didn't run, and a rejected or unconfirmed update as states that load nothing. Text can't be run, so this verdict comes from reading step 1b against step 1a and `standards/framework-update-policy.md`. | Two readings stay open (M-2). The first allowed state, "found no framework update", overlaps "no recorded previous version", because a first session also finds no mismatch. The second is wider. Step 1a's summary checks version strings only, so an unversioned change to a source `SKILL.md` reads as "no update" and step 1b then loads it. Backlog 0000181 covers the step 1a text. |
| N-4 | Informational | Yes | `bash rr/drift-variants.sh`. A folder at a source `SKILL.md` gives rc=2 `the source ROOT/planifest-framework/skills/alpha/SKILL.md is a folder`. A FIFO at `planifest-framework/skills` gives rc=2 `can't read the source skills folder ROOT/planifest-framework/skills: isn't a folder`. | At `planifest-framework/skills`, a regular file and a 2 MiB file each give rc=2 `isn't a folder`, and a link gives rc=2 `is a link`. A source `SKILL.md` that is a link gives rc=2 `is a link`. A socket gives rc=2 `isn't a regular file`. `SOURCE_REASONS` now has a key for every kind that `readSafe` returns (`link`, `folder`, `other`, `oversize`), so no message prints `undefined`. |

## Earlier fixes rerun

| ID | Still holds | Evidence |
|---|---|---|
| S-1 | Yes | `bash rm-template.sh`. Case A: `rc=0 out=autonomous`. Case B: `rc=0 out=interactive`, `found 0`. |
| S-2 | Yes | `bash rm-fixtures.sh run-mode.mjs`: all 20 cases give `rc=0 out=interactive`. `bash rr/rm-variants.sh`: the results match the first re-review case for case. Bare, list item, CRLF, and Feb 29 2028 print `autonomous`. Every malformed timestamp and every history-rule case prints `interactive` with a reason. |
| Hooks 1 | Yes | `node swap.mjs path-rules.mjs {link,rm,fifo,dir}`: `allowed=false` for both targets. `none` blocks by scope. |
| Hooks 2 | Yes | `bash rr/hooks-static.sh`: 1,048,575 and 1,048,576 bytes scope writes (`src/allowed` rc=0, others rc=2). 1,048,577 bytes and 600 MiB give rc=2 for every target with the cap line. A static socket gives rc=2 with the not-regular line. |
| S-3 | Yes | `bash drift-fixtures.sh`: installed FIFO rc=1 `stale`, marker FIFO rc=0, `/dev/zero` link rc=1. A 300 MB source gives rc=2 with max RSS 44.5 MB. `rr/drift-variants.sh` cases each finish in about 0.05 s. |
| S-4 | Yes | `drift-fixtures.sh`: an installed copy or a skills folder linked outside the root gives rc=1 `stale`. A linked source folder gives rc=2. `drift-variants.sh`: a linked `.claude/skills` or `.claude` that would match gives rc=1. |
| S-5 | Partly | Covered by N-3 and M-2 above. |
| S-6 | Partly | Covered by N-2 and M-1 above. |

## New findings

### M-1. A settings file that setup can't write still counts as a completed run (Low)

**File:** `planifest-framework/migrations/migrate-0.34.0-rerun-setup.md`, Migrator Instructions steps 6 and 7

`writeSettings` in `setup.sh` prints `could not write ... - left unchanged` when its write fails. It returns false, and setup still exits 0. Step 7's four conditions don't cover this case. Step 6 doesn't tell the migrator to report it either. So the migrator records `applied` while the hooks stay unwired, and the human on the loop isn't told.

**Reproduction:** in a `mktemp -d` fixture, `git init`, copy `planifest-framework/` in, and run `bash planifest-framework/setup.sh claude-code`. Set `.claude/settings.json` to `{}`, run `chmod 555 .claude`, and run setup again.

- Setup: exit 0. The log shows two `! could not write .../.claude/settings.json (EACCES: permission denied, ...) - left unchanged` lines, and no malformed-JSON or missing-Node line.
- `node planifest-framework/scripts/skill-drift-check.mjs`: exit 0, `21 skills match source for claude-code.`
- Every `hooks/enforcement/*.mjs` file equals its installed copy (`cmp`).
- `.claude/settings.json` is still `{}`.

The case needs a local permission fault, so its severity matches N-2.

**Fix:** widen step 6 and step 7 to any `!` warning line from setup, rather than two named ones. A stricter option checks that each settings file names the `gate-write` hook after the run.

### M-2. Step 1b's first allowed state stays open to two readings (Low)

**File:** `planifest-framework/skills/planifest-orchestrator/SKILL.md`, step 1b

The first allowed state is "Step 1a ran in this session and found no framework update, and the build log records no rejected one". Two gaps remain:

- A first session has no recorded version, so step 1a finds no mismatch. That fits the allowed state and the excluded "no recorded previous version" state at once. The text doesn't say which one wins.
- Step 1a's inline summary checks version strings only. A push that changes a source `SKILL.md` and leaves the version alone reads as "no update". The drift check then flags the skill as stale, and step 1b loads the changed source copy. The policy's later paragraph keys detection on changed files, but step 1a's summary and the policy's own signal list don't.

"The build log" also names no file. Step 1a records outcomes in `plan/current/build-log.md`, which a session with no active feature doesn't have.

The case lives in skill text, so no fixture can run it.

**Fix:** state that the excluded states win over the allowed ones. Name `plan/current/build-log.md`, and say what a session without one does. The file-level detection gap predates this feature, so backlog 0000181 holds it.

### M-3. A regular design.md that fails to open for a non-permission reason blocks with a wrong message (Informational)

**File:** `planifest-framework/hooks/enforcement/path-rules.mjs`, `readDesign`

The fix now treats every open error other than `EACCES` and `EPERM` as a non-regular file. That includes errors a regular file can raise, such as `EMFILE`, `EIO`, or `ETIMEDOUT` on a network or file-provider volume. `rr/swap3.mjs openerr:EIO` blocks all three targets with `design.md is not a regular file`. The gate fails closed here, which is the safe side. The message misleads, though, because the file is regular. No change is needed for security. A clearer line could name the open error.

## Regression checks

| Check | Result |
|---|---|
| `env -u CLAUDE_PROJECT_DIR bash planifest-framework/tests/run-tests.sh` | Exit 0. `Feature suites: 97 passed, 0 failed.` `Regression suite: 33 passed, 0 failed.` `All tests passed.` |
| `node planifest-framework/scripts/run-mode.mjs` in this repository | Exit 0, prints `autonomous`. |
| `git status --porcelain` before this report | Clean. The re-review changed no tracked file other than this report and backlog 0000181. |

## Backlog

This re-review filed backlog 0000181 (`plan/backlog/0000181-orchestrator-step-1a-omits-file-level-detection/entry.md`). Step 1a's detection summary and the policy's signal list check version strings only, while the policy's own text keys detection on changed files. That text predates 0000036. M-1 to M-3 concern text and code that this feature changed, so they stay in this report.
