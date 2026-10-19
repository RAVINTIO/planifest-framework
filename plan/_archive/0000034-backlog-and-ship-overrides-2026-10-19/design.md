# Design: 0000034-backlog-and-ship-overrides

**Track:** Change Pipeline
**Version:** no framework version change. The change touches only product overrides, not `planifest-framework/`.
**Confirmation:** yes. On 2026-10-19 the human on the loop asked for this design to land two instruction overrides.

## Problem

Two standing instructions exist only in `CLAUDE.md`, which is gitignored. `setup.sh` rebuilds `CLAUDE.md` from `planifest-overrides/instructions/`, so a rerun of setup would drop them.

## Change

Add two instruction overrides:

- `custom-004-file-backlog-entries-immediately.md`: file an out-of-scope problem as a backlog entry straight away, then commit it and push it to the open feature branch.
- `custom-005-p9-push-and-raise-pr.md`: in the ship phase, push and raise the PR without asking, and never merge. This copies `custom-004-p9-push-and-raise-pr.md` from the Zero repo.

`CLAUDE.md` already holds both texts in its overrides block.

## Component Paths

- `planifest-overrides/instructions/`

## Out of scope

- The write-gate gaps in backlog 0000124 and 0000125.
- Any file under `planifest-framework/` or `src/`.
