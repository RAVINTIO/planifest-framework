---
title: "ADR 010: Archive script replaces glob delete"
summary: "P7 Step 6 runs a new archive-current.mjs script. It moves each item in plan/current/ with one git mv, deletes only four sentinels by explicit path, and never deletes by glob. A plan/current/.archive-target file lets a stopped archive resume into the same directory."
status: "accepted"
version: "0.1.0"
---
# ADR-010 - Archive script replaces glob delete

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000033-human-on-the-loop-run-mode
**Component:** planifest-framework
**Date:** 2026-10-19

## Context

0000003-ADR-006 chose copy-then-delete for the P7 archive. The ship agent copies `plan/current/` into the archive, then deletes the source contents, dotfiles included. That ADR rejected `git mv` because it would add a commit mid-phase.

The delete is the problem. The natural command is a glob such as `rm -rf plan/current/* plan/current/.[!.]*`. Backlog 0000075 reports that Claude Code's safety check refused it in a downstream run. The check can't resolve a relative glob, so it treats the removal as unbounded. Only a person can approve it. In an unattended run nobody does, and the whole compound command failed, the copy included.

The agent recovered with `git mv` per item and `git rm` for the sentinels. The skill gave no such path.

An `autonomous` run (ADR-002) can't depend on a person approving a delete. It also needs a stopped archive to resume without a duplicate directory. Today a rerun adds a `-{n}` suffix and copies again.

## Decision

- **Script:** A new `planifest-framework/scripts/archive-current.mjs` does the archive. It follows `product-version.mjs` house style: a usage header, exit codes, and Node built-ins only. P7 Step 6 calls it as one command and records the `archive-dir:` line it prints as `{archive-dir}`.
- **Target and resume file:**
  - If `plan/current/.archive-target` exists, the script reads the target from it.
  - Otherwise it picks `plan/_archive/{feature-id}-{YYYY-MM-DD}/`, or the first free `-N` suffix. It writes that path to `.archive-target` before it moves anything.
- **Moves:** The script lists `plan/current/` with a directory read, never a glob. It runs `git mv` for each tracked entry. For an untracked entry, it renames the entry on disk, then runs `git add`.
- **Explicit-path deletes:** The script deletes only these paths, each by explicit path:
  - `plan/current/.skips`
  - `plan/current/.planifest-session`
  - `plan/current/.feature-id`
  - `plan/current/capability-skills/`
  - `plan/current/.archive-target`, at the end
- The script never touches a session marker. 0000032-ADR-002 clears those in P9.
- **One command per step:** Each git call runs as its own child process with an argument array and no shell. A refused step leaves every earlier step done.
- **Resume and conflict:** An entry whose source is gone and whose target exists prints as `skipped`. An entry with both a source and a target stops the script with exit 3. It never overwrites.
- **Finish:** `plan/current/` stays as an empty directory, so the Step 7 `git add plan/current/` line still matches. Exit 0 means complete, 2 means invalid input, and 3 means a conflict or a leftover entry.
- **No fallback:** If the script exits non-zero, the agent fixes the named cause and reruns it. It never falls back to a glob delete.
- **Resume Detection:** Step 2a first checks for `plan/current/.archive-target`. If it exists, the orchestrator resumes at P7 Step 6.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Keep copy-then-delete (0000003-ADR-006) | No change | The glob delete needs a person's approval, so an unattended run stops | Backlog 0000075 shows it failing |
| Keep copy-then-delete, deleting each item by explicit path in skill text | No script | The agent still builds many commands by hand, and a resume still duplicates the archive | A script runs the same steps the same way each time |
| Rename `plan/current/` as one directory | One operation | Git sees deletes and adds, not renames. It also removes `plan/current/`, which Step 7 stages. | Per-item `git mv` keeps history and the Step 7 line |
| Resume by adding a new `-{n}` suffix (status quo) | No resume file | Each stop leaves a partial duplicate archive | `.archive-target` finishes into the same directory |

0000003-ADR-006 also rejected `git mv` for adding a commit mid-phase. `git mv` only stages, and Step 7 already commits the archive, so no extra commit appears.

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | A new `scripts/archive-current.mjs` and its suite. The ship skill replaces P7 Step 6 items 1 to 4 and names `{archive-dir}` in P8 and P9. The orchestrator adds an `.archive-target` check to Resume Detection step 2a. One existing suite, `test-0000025-req-002-ship-agent-p7-git-add.sh`, changes its `Copy-then-delete` assertion. |

## Consequences

**Positive:**
- The archive needs no glob delete, so no safety check stops an unattended run.
- Git records the archive as renames, so file history carries into `plan/_archive/`.
- A stopped archive resumes into the same directory and repeats only unfinished moves.
- The script prints each action, so the build log can show exactly what moved.

**Negative:**
- P7 now depends on Node and on a script that needs its own tests and upkeep.
- A conflict stops the archive with exit 3, and someone must resolve it by hand.

**Risks:**
- If a later skill adds a new sentinel to `plan/current/`, the script archives it instead of deleting it. The explicit-path list must change with it.
- A tampered `.archive-target` could point outside `plan/_archive/`. The script checks the value against the feature-ID pattern and the archive root, and exits 2 on a mismatch.
- An untracked entry renamed but not yet staged, when a run stops, leaves an unstaged file in the archive. The rerun's `git add` step covers it.

## Related ADRs

- 0000032-ADR-002 (session markers cleared in P9) - depends-on. It defines `{archive-dir}`, Resume Detection step 2a, and the marker step that clears the markers.
- ADR-011 - related-to. The close-out commit uses the `archive-dir:` line.
- ADR-015 - related-to. It assigns `.archive-target` to `planifest-framework`.
- ADR-002 - related-to. `autonomous` runs need an archive with no human approval.

## Supersedes

- 0000003-ADR-006 (copy-then-delete archive). P7 now moves each item with `git mv` and deletes only explicit paths.

## Superseded By

- None
