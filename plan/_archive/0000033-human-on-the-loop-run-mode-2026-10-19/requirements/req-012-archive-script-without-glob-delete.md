---
title: "Requirement: req-012 - archive-script-without-glob-delete"
summary: "A new archive-current.mjs script archives plan/current/ with one git mv per item, removes sentinels by explicit path, never deletes by glob, and resumes cleanly after a stop."
status: "draft"
version: "0.1.0"
---
# Requirement: req-012 - archive-script-without-glob-delete

**Skill:** [spec-agent](../../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Source:** US-007
**Priority:** must-have

## User Story

As the human on the loop, I get a P7 to P9 close-out that needs no glob delete and ends with a clean working tree, so that an autonomous run can finish without me.

This requirement covers the P7 archive half of US-007. req-013 covers the clean working tree.

## Functional Requirements

### New script (`planifest-framework/scripts/archive-current.mjs`)

The script follows the house style of `product-version.mjs`: a header comment with usage and exit codes, no dependencies, and Node built-ins only.

- **Usage:** `node planifest-framework/scripts/archive-current.mjs --feature-id <id> [--date YYYY-MM-DD] [--root <projectRoot>]`. `--date` defaults to today. `--root` defaults to the working directory.
- **Target directory:**
  1. If `plan/current/.archive-target` exists, the script reads the target from it. This is the resume case.
  2. Otherwise the script picks `plan/_archive/{feature-id}-{YYYY-MM-DD}/`. If that path exists, it picks the first free `-2`, `-3`, and so on. It writes the chosen path to `plan/current/.archive-target` before it moves anything.
- **Moves:** The script reads the entries of `plan/current/` with a directory listing, never a glob. For each entry other than `.archive-target` and the explicit-path list below, it does one of these:
  - If git tracks the entry, run `git mv -- plan/current/<item> <target>/<item>`.
  - If git doesn't track it, rename it into the target on disk, then `git add` the new path.
- **Explicit-path list:** The script removes these four paths by explicit path, as Step 6 deletes them today:
  - `plan/current/.skips`
  - `plan/current/.planifest-session`
  - `plan/current/.feature-id`
  - `plan/current/capability-skills/`

  For each one it runs `git rm -r --cached --ignore-unmatch -q -- <path>` and then deletes it from disk. These four paths, and `.archive-target`, are the only ones it ever deletes. It never names a session marker (`.orchestrator-active`, `.orchestrator-ack`, `.run-mode`). 0000032 req-001 clears those in P9.
- **One command per step:** Each `git mv`, `git add`, and `git rm` runs as its own child process with an argument array and no shell. A refused step therefore leaves every earlier step done.
- **Idempotent resume:** If an entry's source is absent and its target exists, the script prints it as skipped and moves on. A rerun after a stop repeats only the unfinished steps.
- **Conflict:** If both the source and the target of an entry exist, the script stops. It names the entry and exits 3. It never overwrites.
- **Finish:** After the moves, the script removes `plan/current/.archive-target` by explicit path. It leaves `plan/current/` in place as an empty directory, so the Step 7 `git add plan/current/` line still matches. If any other entry remains, it names the entry and exits 3.
- **Output:** One line per action on stdout: `moved: <from> -> <to>`, `removed: <path>`, or `skipped: <path> (already archived)`. The last line is `archive-dir: <target>`.
- **Exit codes:** 0 when the archive is complete. 2 for invalid input (see Input Validation). 3 for a conflict or a leftover entry. A failed git command exits non-zero with git's message on stderr.

### Ship skill (`planifest-framework/skills/planifest-ship-agent/SKILL.md`)

- **P7 Step 6 (Archive plan/current/):** Replace the copy-then-delete text and its "never use atomic move" note. Items 1 to 4 become one instruction: run `archive-current.mjs` with the feature ID, as a single command. Record the `archive-dir:` line it prints as `{archive-dir}`. The 0000032 P9 marker step already uses that name.
- **P7 Step 6, on failure:** If the script exits non-zero, rerun it after fixing the cause it names. Never fall back to a glob delete such as `rm -rf plan/current/*`.
- **P7 Step 6, item 5 (Cross-reference check):** Keep it unchanged.
- **P7 Step 7 (Commit archive):** Keep the `git add` line unchanged. `git mv` stages the moves already.
- **P8 and P9 path references:** Where P8 and P9 rebuild `plan/_archive/{feature-id}-{YYYY-MM-DD}/` from the date, name `{archive-dir}` instead. This covers the P8 and P9 build-log lines, the P8 sub-agent prompt, and Step 11.

### Orchestrator skill (`planifest-framework/skills/planifest-orchestrator/SKILL.md`)

- **`## Resume Detection`, step 2a:** Add a first check. If `plan/current/.archive-target` exists, P7 Step 6 stopped mid-archive. Load the `planifest-ship-agent` skill and resume at P7 Step 6. The script reads the target and finishes only the unfinished moves.

### Tests

- A new Bash suite, `planifest-framework/tests/test-0000033-req-012-archive-script-without-glob-delete.sh`, covers the script by running it in a temporary git repository. It also asserts the ship skill text. `run-tests.sh` picks it up.
- Listed exception: `planifest-framework/tests/test-0000025-req-002-ship-agent-p7-git-add.sh` asserts `Copy-then-delete` in Step 6. This requirement edits that assertion to check for `archive-current.mjs`. It is the only existing suite this requirement edits.
- `planifest-framework/tests/test-0000032-req-001-marker-clear-before-tag.sh` checks that Step 6 names no session marker. req-007 edits that suite as a listed exception. It must pass in its req-007 form.
- These suites must pass unchanged:
  - `planifest-framework/tests/test-0000017-req-007-change-agent-archive.sh` (Step 6 keeps its cross-reference check)
  - `planifest-framework/tests/test-0000032-req-002-resume-from-archive-evidence.sh`

### Verified by

- In a fixture repo with tracked and untracked items, the script moves every item into `plan/_archive/{feature-id}-{date}/` and exits 0. `git status --porcelain` shows renames, not deletions.
- After the run, `plan/current/` exists and is empty, and `git add plan/current/` exits 0.
- The script removes `.skips`, `.planifest-session`, `.feature-id`, and `capability-skills/`, and no other path. None of them appears in the archive. The `plan/.orchestrator-active` fixture file is untouched.
- With an existing `{feature-id}-{date}/`, the script picks `-2`.
- A second run after a forced stop half-way prints `skipped:` for the moved items, moves the rest into the same directory, and creates no `-2`.
- With a source and target both present, the script exits 3 and changes nothing.
- An invalid feature ID or an `.archive-target` outside `plan/_archive/` exits 2.
- The script source contains no `rm -rf`, no `*` in a path it deletes, and no `shell: true`.
- The ship skill's Step 6 section names `archive-current.mjs` and `{archive-dir}`. It no longer contains `Copy-then-delete` or `Recursively copy`.
- The orchestrator's step 2a names `.archive-target` and a resume at P7 Step 6.

### Security additions (P5)

These changes are in `planifest-framework/scripts/archive-current.mjs`.

- S1: The script refuses a symlinked `plan/_archive` or a symlinked target directory and exits 2.
- S2: The script refuses a symlinked or out-of-root `plan/` or `plan/current/` and exits 2.
- S3: The script refuses a symlinked `.archive-target` and exits 2. It writes `.archive-target` with an exclusive create.
- S4: The script never prints the raw `.archive-target` value.
- S7: The script sets `GIT_LITERAL_PATHSPECS=1` for its git calls.
- S8: Names the script prints pass through a control-character filter.

## Acceptance Criteria

- [ ] (feature AC 5) `archive-current.mjs` archives `plan/current/` with one `git mv` or rename per item. It deletes only the four explicit-path sentinels and never uses a glob.
- [ ] (feature AC 5) After a stop part-way through, a rerun finishes into the same archive directory and repeats only the unfinished moves.
- [ ] (feature AC 7) The ship skill's P7 Step 6 calls the script. The new suite, the edited 0000025 suite, the req-007 form of the 0000032 req-001 suite, and the unchanged 0000032 req-002 and 0000017 suites pass under `run-tests.sh`.

## Dependencies

- 0000032 req-001: the P9 marker step clears the session markers and defines `{archive-dir}`. This requirement doesn't move marker handling.
- 0000032 req-002: Resume Detection step 2a picks the archive directory from evidence. The new `.archive-target` check comes before it.
- req-013 relies on the `archive-dir:` line this script prints.
- req-007 edits `test-0000032-req-001-marker-clear-before-tag.sh`.

## Input Validation

- [ ] Input source: the `--feature-id`, `--date`, and `--root` arguments, and the contents of `plan/current/.archive-target`
- [ ] Allowed character pattern: feature ID `^[0-9]{7}-[a-z0-9-]+$`, date `^[0-9]{4}-[0-9]{2}-[0-9]{2}$`. The `.archive-target` value must resolve inside `plan/_archive/` and match `{feature-id}-{date}` with an optional `-N` suffix.
- [ ] maximum length: 120 characters for the feature ID and for the `.archive-target` value
- [ ] Failure behaviour: exit with code 2 and a reason on stderr. Move nothing.
- [ ] Logging policy: sanitised value only in output
