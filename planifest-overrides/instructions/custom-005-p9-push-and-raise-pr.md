### Ship: push and raise the PR, never merge

In the ship phase, push every change and raise the pull request yourself, without asking. Push the feature branch and the release tag, then run `gh pr create`. In the ship skill's push/PR decision, always take option [1].

Never merge the pull request, and never push or commit to `main`. The human always merges to `main`.

If a push or `gh pr create` fails, report the exact error and stop. Don't retry with force or merge as a workaround.
