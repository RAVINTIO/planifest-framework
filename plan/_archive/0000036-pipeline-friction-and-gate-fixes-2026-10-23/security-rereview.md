---
title: "Security Re-review - 0000036 P5 fixes"
summary: "Fresh-context check of the eight P5 fixes, with reproductions and variants run against the fixed code."
status: "draft"
---
# Security re-review: 0000036 P5 fixes

**Feature:** 0000036-pipeline-friction-and-gate-fixes
**Phase:** P5
**Commits checked:** `26cc234` (S-1, S-2), `ae3f552` (hooks 1, hooks 2), `1a60cdf` (S-3 to S-6)
**Platform:** macOS (Darwin 25.6.0), Node v26.12.0

## Result

Overall rating after the fixes: **Low**.

Six of the eight fixes hold in full. Two hold for the reported attack but leave a Low gap next to it (S-5 and S-6). Hooks finding 1 holds for every swap the reviewer named, but a socket swapped in at the same point still fails open (N-1, Low).

The full suite passes, and `run-mode.mjs` still prints `autonomous` in this repository.

Every fixture ran under `mktemp -d` with `CLAUDE_PROJECT_DIR` unset. The re-review scripts sit in the session scratchpad under `rr/`, outside the repository.

## Per-finding verdicts

| ID | Original severity | Fixed | Evidence (command, exit code, key output) | Variant tried and result |
|---|---|---|---|---|
| S-1 | High | Yes | `bash rm-template.sh`. Case A: `rc=0 out=autonomous`. Case B: `rc=0 out=interactive`, `found 0`. | A future template with a real-timestamp example at column 1 prints `autonomous` (`rm-variants.sh`, case `template w/ real example`). The suite guards this. `test-0000033-req-001-run-mode-script.sh:448` asserts zero `^(- )?Run mode confirmed:` lines in the template. |
| S-2 | Low | Yes | `bash rm-fixtures.sh run-mode.mjs`. Both suffix-junk cases: `rc=0 out=interactive`. | With a real timestamp, trailing space and trailing text print `interactive`. The same holds for `+01:00`, lower-case `z`, `.000Z`, Feb 30, Feb 29 in 2026, month 13, hour 24, `:60`, full-width digits, and NBSP. A real Feb 29 2028 prints `autonomous`, as it should. Year `0000` and `9999` print `autonomous` (N-5). |
| Hooks 1 | Low | Yes, for the named swaps | `node swap.mjs path-rules.mjs link`: `allowed=false` for `src/other/a.js` and `gate-write.mjs`. `rm`, `fifo`, and `dir` also give `allowed=false`. | `node rr/swap2.mjs`: a link, a dangling link, or a folder link gives `allowed=false` with the not-regular line. A **socket** swap gives `allowed=true` for both targets (N-1). An `EACCES` swap gives `allowed=true`. That is the accepted `chmod 000` class (backlog 0000162). A hard link gives `allowed=true`, which equals writing `design.md` directly. |
| Hooks 2 | Medium | Yes | `bash rr/hooks-static.sh`: 1,048,575 and 1,048,576 bytes read as the design (`src/allowed` rc=0, others rc=2). 1,048,577 and 600 MiB give rc=2 for every target with the "over the 1 MiB size cap" line. | A file that grows from small to 2 MiB after `lstatSync` gives `allowed=false` with the cap line (`swap2.mjs grow`). |
| S-3 | Medium | Yes | `bash drift-fixtures.sh`: installed FIFO rc=1 `stale`, marker FIFO rc=0, `/dev/zero` link rc=1 `stale`. A 300 MB source gives rc=2 with max RSS 44.6 MB (was 989 MB). | `bash rr/drift-variants.sh`, each in about 0.05 s. A FIFO at the installed skill folder, `.claude/skills`, or `.claude` gives rc=1. An installed socket gives rc=1 `stale`. A marker linked to `/dev/zero` gives rc=0. Both copies at exactly 1,048,576 bytes match (rc=0). An installed copy at cap plus 1 is `stale`. A source at cap plus 1 gives rc=2. |
| S-4 | Low | Yes | `drift-fixtures.sh`: installed copy linked outside the root rc=1 `stale`. Linked `.claude/skills` rc=1 `stale` (was rc=0 `match`). Linked source folder rc=2. | A linked `.claude/skills` or `.claude` whose target would match gives rc=1 `stale`. A marker linked to a valid file counts as no marker, so the check falls back to every installed folder. A hard link to an outside file matches (rc=0). Git can't commit a hard link, so only a local actor can set one up. |
| S-5 | Medium | Partly | `planifest-orchestrator/SKILL.md:82` now says that after a rejected or unconfirmed update, step 1b loads no source copy. | Step 1b's "Otherwise" branch loads source copies for every step 1a state it doesn't name (N-3). |
| S-6 | Medium | Partly | `migrate-0.34.0-rerun-setup.md` steps 7 and 8 define a completed run as setup exit 0, drift-check exit 0, and matching hooks. On any other result, the migrator records nothing. | The definition omits step 6. `setup.sh:24-35` leaves a malformed settings file unchanged, skips hook wiring, and still exits 0. A run like that meets all three conditions and records `applied` (N-2). |

## New findings

### N-1. A socket swapped in after `lstatSync` fails the gate open (Low)

**File:** `planifest-framework/hooks/enforcement/path-rules.mjs`, `readDesign` and `SWAPPED_OPEN_ERRORS`

`openSync` on a Unix socket fails with an error that isn't in `SWAPPED_OPEN_ERRORS`. On macOS, Node reports the code as `Unknown system error -102` (`EOPNOTSUPP`). Linux reports `ENXIO`. Either error maps to `unreadable`, so every write passes, enforcement paths included.

**Reproduction:** `node rr/swap2.mjs planifest-framework/hooks/enforcement/path-rules.mjs sock`, exit 0:

```
mode=sock target=src/other/a.js allowed=true reason=""
mode=sock target=planifest-framework/hooks/enforcement/gate-write.mjs allowed=true reason=""
```

A static socket at `design.md` blocks on this branch (rc=2, not-regular line). On `main`, the same static socket gives rc=0 for both targets, with no race. So the branch narrows the gap from a static file to a race window. The attack needs a socket bound under `plan/` and a swap timed into the window. The review's live race of 400 runs per mode never hit that window.

**Fix:** invert the rule. Fail open only on `EACCES` and `EPERM`, the codes ADR-002 accepts. Treat every other open error as `non-regular`. Add a socket case to the req-008 swap suite.

### N-2. A run that skips hook wiring still counts as complete (Low)

**File:** `planifest-framework/migrations/migrate-0.34.0-rerun-setup.md`, Migrator Instructions step 7

If a settings file is malformed, setup leaves it unchanged, skips hook wiring for it, and exits 0. The installed `enforcement/*.mjs` files still match their source, and the drift check exits 0. Step 7 then calls the run complete, so the migrator records `applied` while the hooks stay unwired. Step 6 does report the malformed file to the human on the loop, so the gap is in the record, not in what the human sees.

**Fix:** add a fourth condition to step 7. Setup reported no malformed settings file and no missing Node. Also, think about adding the boot-file check from step 5.

### N-3. Step 1b loads source skills in step 1a states it doesn't name (Low)

**File:** `planifest-framework/skills/planifest-orchestrator/SKILL.md:82`

Step 1b names two step 1a states, "rejected" and "hasn't confirmed". Everything else falls to "Otherwise", which loads source copies. Step 1a has other outcomes:

- no previous version recorded, as in a first session
- a detection that couldn't run, such as an unreadable `component.yml`
- a rejection recorded in an earlier session's build log, when this session's check doesn't flag the files again

Text alone can't be reproduced. This finding comes from reading the step against `standards/framework-update-policy.md`.

**Fix:** reverse the default. Load source copies only when step 1a ran and found no update, or found one that the human on the loop confirmed with provenance. In any other state, report the drift and keep the installed copies.

### N-4. The drift check prints `undefined` as a reason (Informational)

**File:** `planifest-framework/scripts/skill-drift-check.mjs`, `sourceSkills` and `SOURCE_REASONS`

`SOURCE_REASONS` has no `folder` key. A folder at a source `SKILL.md` gives rc=2 with `the source ROOT/planifest-framework/skills/alpha/SKILL.md undefined`. A FIFO at `planifest-framework/skills` gives `isn't a regular file` where the text should say "isn't a folder". The exit code is right in both cases. Only the message is wrong.

**Fix:** add `folder: "is a folder"`, and use a folder-specific reason for the skills folder.

### N-5. The anchor accepts timestamps from year 0000 to 9999 (Informational)

`isAnchor` checks that a timestamp is a real calendar time, but not that it is plausible. `Run mode confirmed: autonomous (0000-01-01T00:00:00Z)` prints `autonomous` when the rest of the anchor rules hold. The line still needs the one commit that also sets the design Confirmation line to `yes`, so this gives no bypass. No change is needed.

## Regression checks

| Check | Result |
|---|---|
| `env -u CLAUDE_PROJECT_DIR bash planifest-framework/tests/run-tests.sh` | Exit 0. `Feature suites: 97 passed, 0 failed.` `Regression suite: 33 passed, 0 failed.` `All tests passed.` |
| `node planifest-framework/scripts/run-mode.mjs` in this repository | Exit 0, prints `autonomous`. |
| Genuine anchors (`rm-variants.sh`) | Bare, `- ` list item, and CRLF forms with a real UTC timestamp each print `autonomous`. |
| Anchor history rules with a real timestamp | Design set to `yes` in another commit, a second anchor commit, a bare line turned into a list item, a later timestamp edit, and a working-tree-only anchor each print `interactive` with a reason. |
| Static `design.md` types | A socket blocks with the not-regular line. A design at or under the cap still scopes writes. |
| Drift-check baseline, binary content, escaped names, `__proto__` marker, cursor marker | Each gives the same result as the first review. |

## Backlog

No out-of-scope pre-existing bug came up, so this re-review filed no backlog entry. N-1 to N-5 concern code and text that this feature changed. N-1's static form is pre-existing on `main`, but this feature already narrows it.
