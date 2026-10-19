# Changelog (0000034-backlog-and-ship-overrides, 19 Oct 2026)

**Feature:** Backlog-now and ship-PR instruction overrides
**Pipeline run:** Change Pipeline. Design, targeted change, validate, and archive.

## What Was Built

- `planifest-overrides/instructions/custom-004-file-backlog-entries-immediately.md`: file an out-of-scope problem as a backlog entry straight away, then commit it and push it to the open feature branch.
- `planifest-overrides/instructions/custom-005-p9-push-and-raise-pr.md`: in the ship phase, push and raise the PR without asking, and never merge. It copies the Zero repo's `custom-004-p9-push-and-raise-pr.md`.
- Backlog 0000124 and 0000125, both about write-gate blocks on paths outside `src/`.

## Validation

Full run: 78 feature and 31 regression suites pass.
