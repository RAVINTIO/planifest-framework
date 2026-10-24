# Shorthand: GUTD

**When the human sends "GUTD", treat it as shorthand for "git up to date": check out `main`, pull the latest, and check for any untracked files.**

## Rule

On receiving the literal token `GUTD` (case-insensitive):

1. `git status` first — per standard safety practice, stash or flag anything uncommitted before switching branches.
2. `git checkout main`.
3. Pull the latest from `origin/main`. If local `main` has diverged (local-only commits not on `origin/main`), do not silently force-reconcile — investigate what those commits are first, same as any other unexpected local state, and prefer a reversible step (e.g. a backup branch) over discarding them.
4. Report any untracked files in the working tree (`git status --porcelain` `??` entries) — list them for the human rather than silently ignoring or cleaning them.

5. Report the CI result of the last merged PR, after the untracked-files report. This step is read-only and does not wait.
   - List the merged PRs with `gh pr list --state merged --base main --limit 10 --json number,url,title,mergedAt`. The list sorts by creation date, so pick the entry with the newest `mergedAt`.
   - Read that PR's checks with `gh pr checks {number} --json name,bucket,link`.
   - Step 5 never reads a `main` run. CI runs on `pull_request` only (0000031 ADR 003), so no `main` run exists.
   - Word the report as "the last merged PR's checks", with the PR number and URL. Never write "main is green" or "main is red".
   - Use these result words: `all passed`, `{n} failed: {names with links}`, `pending`, or `unknown: {names}`. A `cancel` bucket and any other value read as unknown. Unknown never reads as a pass.
   - Judge the result from the JSON, not from the exit status. `gh pr checks` exits 1 for a failed check and exits 8 for a pending one. It still prints the data.
   - If the list holds no merged PR, report "no merged PR to check".
   - If `gh` is missing, signed out, or prints output that is not valid JSON, report "CI status could not be read". For a signed-out `gh`, name `gh auth login` as the fix.
   - Step 5 never changes steps 1 to 4. A failed or unreadable check does not undo the checkout or the pull.
   - The generated `CLAUDE.md` copies this text. A setup re-run refreshes that copy.

## Why

Established 2026-08-02 as a shorthand for a routine sync check the human runs often. Folds in the untracked-files check by default, since a prior "checkout main and pull latest" request surfaced local `main` commits that had diverged from `origin/main` (a stray, unfinished P0 pipeline run started directly on `main`) — worth surfacing untracked/stray state every time, not just when asked.

Step 5 added 2026-10-24 (feature 0000037). PR #62 merged red and no agent reported it, so GUTD now reports the last merged PR's checks.
