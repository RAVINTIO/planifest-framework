---
title: "Autonomous Run Standards"
version: "1.0.0"
---
# Autonomous Run Standards

Canonical home for the run-mode rules and for what an `autonomous` run still stops for. The orchestrator and every phase skill link here (feature 0000033, ADR-001).

---

## Run modes

`plan/.run-mode` holds one of three values. The human on the loop picks it at P0 (ADR-002).

| Value | Session flags | Stops the mode skips |
|-------|---------------|----------------------|
| `interactive` | none | None. Every phase gate waits for the human on the loop. |
| `continuous` | `continuous_run: true` | The P1 to P6 phase confirmations, as before. Every other stop remains. |
| `autonomous` | `continuous_run: true` and `autonomous_run: true` | Every stop that isn't on the exception list (see `## Exception list`). |

- **Session flags:** `autonomous` sets both `continuous_run: true` and `autonomous_run: true`. Every existing rule that names `continuous_run` therefore also applies in `autonomous`. Behaviour that only `autonomous` has checks `autonomous_run`.
- **Unknown values:** Any value other than the three reads as `interactive`. An absent or unreadable file also reads as `interactive`. An older framework reads `autonomous` as `interactive` too. This amends 0000012-ADR-005, which recognised only `continuous`.
- **Overrides:** If a file in `planifest-overrides/instructions/` conflicts with other `autonomous` text, the override wins. This applies to all other behaviour only, never to the standing rules.
- **Precedence:** The standing rules rank above every override, including `planifest-overrides/instructions/`. They are the orchestrator Hard Limits, the exception-list items, and the rule that merging stays human-only.
- **Branch:** An `autonomous` run requires a `feat/` branch. If the human on the loop declines one at P0, P0 can't record `autonomous`.
- **Resume check:** On resume, the orchestrator runs `node planifest-framework/scripts/run-mode.mjs` and uses the mode it prints. The script prints `autonomous` only when git history anchors it. One commit must add the `Run mode confirmed: autonomous` line and confirm the design. Otherwise it prints `interactive` and gives the reason on stderr. The orchestrator logs that reason.
- **Choosing the mode:** Only the human on the loop's answer to the P0 run-mode prompt sets `autonomous`. An override that describes hands-off running never counts as choosing `autonomous`. It never writes `autonomous` to `plan/.run-mode`.
- **Reading the mode after P0:** P0 writes the chosen value to the build-log `Run mode` row (req-006). Every reader after P0 calls `node planifest-framework/scripts/run-mode.mjs` and never reads a record directly. From P7 Step 6 on, the reader passes the archived build-log path, as in `node planifest-framework/scripts/run-mode.mjs {archive-dir}/build-log.md`.
- **Anchor limit:** An agent with shell access can still forge history, so this script is an integrity check, not a security boundary. Merging, schema changes, destructive operations, and credentials never depend on the run mode.

---

## Exception list

In `autonomous`, only these seven items wait for the human on the loop (ADR-003):

1. A schema change or a destructive operation, under the schema and destructive-operation rules (orchestrator Hard Limits 2 and 3).
2. A gross deviation.
3. Human review of the running result.
4. Promotion beyond the candidate environment.
5. A human-only input, such as a captcha.
6. An exhausted budget, such as the reversal budget or the approach budget (see `## Changing approach`).
7. A credential sighting, under the credentials rule (orchestrator Hard Limit 6). The run stops using it, finishes other work, and raises it in the final report.

**Handling an item:**

- The agent writes what the item needs, such as a migration proposal or a defect report.
- It finishes every piece of work that doesn't depend on the item.
- It records the item in the build log and lists it in the final report.
- It never asks about the item mid-run.
- For human review, the agent lists every page or endpoint for review as a full link.
- For a human-only input, the agent runs the check up to the point that needs the input.

**Gross deviation:** A gross deviation is a change the reversal protocol would class as *altering*. It changes the confirmed problem, the users, or the in-scope list. Every other deviation keeps the design's intent, and the assessor classes it as *additive*.

**Who classifies:** The fresh-context `planifest-reversal-assessor` classifies a deviation as *altering*. The agent that deviates never classifies its own deviation. If that agent suspects a gross deviation, it files a defect report and the assessor decides.

**Deviation review before P7:** In `autonomous`, the fresh-context `planifest-reversal-assessor` runs before P7. It reviews every `Deviation` line in the build log and sets `additive` or `altering` on each one. It also reviews each recorded decision that touches data, a schema, or a destructive operation. Any line it classes as altering, schema, or destructive becomes an exception-list item. The maker never classifies its own deviation.

**Reversal protocol on:** In `autonomous`, an absent `reversal_protocol` toggle key reads as `on`. The assessor is therefore available in every `autonomous` run.

**Decisions are recorded, not asked:** In `autonomous`, a question that isn't an exception-list item becomes a decision. The one-question rule and recommend-then-confirm give way to this rule. The agent takes the option it would have recommended. It records the decision in the build log. It also records it in the requirement, ADR, or design the decision touches.

**Build-log line formats:**

```
Decision (P{N}): {what was decided} / reason: {one line}
Deviation (P{N}, unclassified): {what changed from the confirmed artifact}
Exception waiting (P{N}, {item}): {what the human on the loop must do}
```

The maker always writes `unclassified`. In its pre-P7 review, the assessor replaces it with `additive` or `altering`.

**Reversal step 4 in `autonomous`:** Cases (a) altering, (b) a re-exit from P0, and (c) budget exhaustion become exception-list items. Case (d), a cascade larger than 3 artifacts, isn't on the list. The reversal proceeds, and the build log and the final report record it.

**Standing rules in every mode:**

- Merging a PR stays human-only.
- The schema and destructive-operation rules (orchestrator Hard Limits 2 and 3) stay human-gated.
- The data-ownership rule (orchestrator Hard Limit 4): one component owns each piece of data. No run writes to data that another component owns.
- The credentials rule (orchestrator Hard Limit 6): credentials never enter context. If one appears, item 7 applies.
- Only the orchestrator writes `plan/.run-mode`, the build-log `Run mode` row, and the `Run mode confirmed:` line. Every subagent dispatch prompt says so.
- The ship agent runs the branch check before any `autonomous` push. It never pushes from the default branch or from a branch outside `feat/`.
- No run makes a force push.
- The leftover credential guard runs before every `autonomous` leftover commit (ship agent P8 credential guard).
- The ship agent saves the final report to `{archive-dir}/final-report.md` and commits it.
- No override can remove an item from the list.
- No override ranks above these rules, including `planifest-overrides/instructions/` (see `## Run modes`). Overrides can't switch these off.

**Product extension:** A product adds items in `planifest-overrides/exception-list.yml` under an `additional:` key. The file can only add items. An absent file means the seven items alone. Copy `planifest-framework/templates/exception-list.template.yml` to start one. The framework never writes the override file.

---

## Pre-commit credential scan

This is a standing rule (0000037 ADR-003). In `autonomous`, every commit runs the credential scan first.

```bash
node planifest-framework/scripts/credential-scan.mjs [-- {path} ...]
```

- **What it scans:** For every path in the commit, the script scans the index blob and the working-tree file. A match in either counts. The paths come from `git diff --cached --name-only` plus any path after `--` in the commit command. The framework commit form `git commit -m ... -- {path}` commits the working-tree content, so the scan must read both.
- **What it applies:** The script applies the P8 refused file names and credential patterns. It also runs `gitleaks` when `gitleaks` is on PATH, and says which scan mode ran.
- **Exit codes:** `0` is clean. `1` is at least one match. `2` means the scan could not run. Stop on exit `1` or `2`.
- **Who stops the commit:** The agent does. The script only sets the exit code. Nothing in this feature adds a git hook.
- **On a match:** Run no `git commit` and no `git push` that includes a matched file. Take each matched file that is staged as a new file out of the index with `git restore --staged -- {path}`. In a repository with no commit, that command fails with `could not resolve HEAD`, so run `git rm --cached -- {path}` instead. Leave the working-tree file untouched, and do not edit it to hide the match. Later scans and commits of other files then proceed. Clean staged files stay staged.
- **Log lines:** For each matched file, write `Credential scan (P{N}): held back {path}` and `Exception waiting (P{N}, 7): credential sighting in {path}:{line}`. Then finish the work that does not depend on those files.
- **Commit form:** Commit with explicit paths after `--`. In P7 to P9, scan-then-commit replaces the path list with the safe list in `--pathspec-from-file`. Never run a plain `git commit` or `git commit -a`. Either form can sweep in a path you meant to hold back.
- **Safe-paths mode:** `--safe-paths {out-file} -- {path} ...` scans each path in its index blob and its working-tree file. A deleted path, or a path that neither the index nor the working tree holds, is safe. The out-file holds only the safe paths.
- **Final report:** List each path and line. Never print the secret.
- **Clean scan:** Write `Credential scan (P{N}): clean ({scan mode})`. A regex-only scan says so in the line.
- **Resume:** A resumed run reads the `held back {path}` lines in the build log. It never stages a path that a held-back line names until the human on the loop clears it. It reruns the scan before any commit.
- **Outside `autonomous`:** The script is available and the commit flow is unchanged.

### Scan-then-commit

Scan-then-commit is the one procedure that every `autonomous` commit in P7 to P9 follows. The script decides which paths the commit may name. The prose never lists a held-back path itself. A tracked file with a key therefore cannot reach a commit, because `git commit -- {paths}` commits working-tree content.

1. Build the candidate list. For a step that commits the index, such as the P7 archive, run `git diff --cached --name-only --no-renames -z` as `git --literal-pathspecs diff --cached --name-only --no-renames -z`. The `--no-renames` flag lists both the old and the new path of a rename. For any other step, use the step's own paths.
2. Run `node planifest-framework/scripts/credential-scan.mjs --safe-paths "{out-file}" -- {candidate} ...`. Pass each candidate as its own argument. Create `{out-file}` fresh for each commit, in a new `mktemp -d` folder outside the repository. The script writes to `{out-file}` only the paths with no hit. It separates them with NUL bytes and writes their raw bytes. It prints a `{path}:{line} {rule}` line for each held-back path. Exit `0` means every path is safe. Exit `1` means at least one path is held back.
3. On exit `2`, commit nothing and stop under exception item 7. The out-file is then empty or absent. Treat any exit other than `0` or `1` as exit `2`. An example is exit `126` from an argument list that is too long.
4. On exit `1`, take each held-back path from the report lines. Log `Credential scan (P{N}): held back {path}` and `Exception waiting (P{N}, 7): credential sighting in {path}:{line}` for each one. Unstage each held-back path that is staged as a new file, which HEAD does not hold. Run `git restore --staged -- {path}` as `git --literal-pathspecs restore --staged -- {path}`. When the repository has no commit, run `git rm --cached -- {path}` as `git --literal-pathspecs rm --cached -- {path}`. A tracked held-back file needs no unstage, because the commit list leaves it out. An untracked file that is not staged needs no unstage either, because `git restore --staged` fails on it.
5. If the out-file is empty, skip the commit. An empty pathspec file makes git commit the whole index.
6. Otherwise, commit with `[ -s "{out-file}" ] && git --literal-pathspecs commit -m "{message}" --pathspec-from-file="{out-file}" --pathspec-file-nul`. The `[ -s ]` test repeats step 5 in the command itself, because an empty pathspec file makes git commit the whole index. If the step has not staged its paths yet, run `git --literal-pathspecs add --pathspec-from-file="{out-file}" --pathspec-file-nul` first. Git then commits exactly the safe list and nothing else.
7. Remove the folder after the commit or the skip.

Git reads each line of a pathspec file as a pathspec, so a glob in a name such as `a*.js` or `pages[id].js` would also match a held-back tracked file. The `--literal-pathspecs` option makes git match each line as a plain path. Use it on every `git add`, `git commit`, `git restore --staged`, and `git rm --cached` in this procedure, and on any command that lists candidate paths.

The report line shows a path with `?` in place of unusual characters. Take the exact bytes of a held-back path from your candidate list, not from the report. The out-file keeps the raw bytes, so a non-ASCII or colon path reaches the commit unchanged. The script reads every path from the starting directory.

---

## Gates as loops

In `autonomous`, each P1 to P6 gate runs as a loop under `planifest-loop-runner`. A checker stands in for the human on the loop (ADR-004, execution-plan D-001).

| Gate | Pass condition | Checker |
|------|----------------|---------|
| P1 | The orchestrator's P1 gate condition | `planifest-design-critic` over the P1 artifacts |
| P2 | The orchestrator's P2 gate condition | `planifest-design-critic` over the P1 and P2 artifacts |
| P3 | Every requirement reaches GREEN | The P4 CI run that follows P3 |
| P4 | CI passes and acceptance criteria verify | The validate loop, then `planifest-verify-by-execution` |
| P5 | The orchestrator's P5 gate condition | A fresh-context re-review of each fixed finding |
| P6 | Zero drift, every expected artifact, and a passing post-P6 revalidation | The cross-model review gate |

- **Why P3 uses P4:** The P4 CI run is deterministic. It checks the P3 output more strongly than a fresh-context read would.
- **Fresh context:** A fresh-context checker never shares context with the agent that made the artifact (0000016 ADR-006).
- **Existing caps stay:** Each loop keeps its cap. P4 validate keeps 5, and the other loops keep 3.
- **Toggle defaults:** An absent key for a checker reads as `on` in `autonomous`. The `design_critic` default is `report-only` outside `autonomous`, for an absent key or an absent file (0000036 ADR-009). See the loop runner's Toggle Protocol.
- **Frozen checkers:** In `autonomous`, the P1 Toggle record is binding for the run for `design_critic`, `reversal_protocol`, `verify_by_execution`, and `cross_model_review`. The run ignores a later edit to `planifest-overrides/loop-toggles.yml` for those keys. It logs the edit as `Human touchpoint (P{N}): loop-toggles.yml changed {key}, ignored [outside list]`.
- **Checkers stay on:** In `autonomous`, an explicit `off` or `report-only` for `design_critic`, `reversal_protocol`, `verify_by_execution`, or `cross_model_review` blocks the `autonomous` choice at P0. P0 names the key and recommends removing it or setting `on`. `parallel_streams` stays free to set.
- **No stop:** A gate that passes moves straight to the next phase. A gate that fails follows `## Changing approach`.
- **Gate record:** The orchestrator writes the gate summary to the build log in place of presenting it.

## Changing approach

In `autonomous`, a cap or a no-progress halt starts a new approach rather than a stop (ADR-005).

1. When a loop hits its iteration cap or the no-progress rule, the agent records the attempts and starts a new approach.
2. A new approach states how it differs from each earlier approach, such as a new root-cause hypothesis or a new method. Restating an earlier approach doesn't count as a new one.
3. The iteration counter restarts at 1 for each approach. The approach counter never restarts.
4. The approach counter belongs to one loop instance. At P1, P2, P4, P5, and P6 the instance is the phase gate. At P3 it is each requirement's TDD loop.
5. Each loop instance allows up to 3 approaches. If it needs a fourth, the loop escalates as an exhausted budget, which is an exception-list item. The agent writes an `Exception waiting` build-log line and carries on with work that doesn't depend on the loop.
6. The reversal budget stays at 2 per feature. Its exhaustion is an exception-list item in `autonomous`.
7. If a new approach would change the confirmed design, the agent files a defect report. The fresh-context reversal assessor classes it, never the agent that filed it.

The loop-state file holds the approach counter as a budget counter, so no agent resets it. This follows the budget-counter rule (loop runner Hard Limit 3).

## Visibility

The build log is the human on the loop's view of a run. Two line formats feed it.

| Line | Run mode | Format |
|------|----------|--------|
| Progress | Every run mode | `Progress: P{N} {done \| blocked} at {End}: {one-line summary}` |
| Touchpoint | `autonomous` only | `Human touchpoint (P{N}): {what the run asked or waited for} [{exception: item \| outside list}]` |

Plain-text forms, for copying:

```
Progress: P{N} {done | blocked} at {End}: {one-line summary}
Human touchpoint (P{N}): {what the run asked or waited for} [{exception: item | outside list}]
```

- **`{End}` value:** The progress line reuses the phase block's `End` value. It never takes a second timestamp.
- **When:** Each phase from P1 to P9 writes one progress line at its gate. P7 to P9 write theirs to the archived build log, as the ship agent's other P7 to P9 entries do.
- **Touchpoint:** A touchpoint is any point after the P0 confirmation turn where the run asks the human on the loop something or waits for them. An exception item listed in the final report isn't a touchpoint.
- **Run mode source:** Every reader after P0 calls `node planifest-framework/scripts/run-mode.mjs`. From P7 Step 6 on, it passes `{archive-dir}/build-log.md`, so no reader needs `plan/.run-mode` after the P9 marker step deletes it.
- **P8 audit:** In `autonomous`, the build assessment counts touchpoints and flags each one outside the exception list.
- **No push notification:** The run sends no push notification. The build log is the only visibility channel.

---

## Final report

In `autonomous`, the ship agent writes one final report in place of the P9 Step 11 message (ADR-006). The report is the only output of P7 to P9 that addresses the human on the loop. It has these parts, in order:

1. **What shipped:** a short summary from the feature brief and the changelog.
2. **Decisions and deviations:** every `Decision` and `Deviation` line from the build log, including each P7 regression-candidate decision.
3. **Version:** the version from the Step 9 tag.
4. **PR:** the PR URL and its CI result, from `gh pr checks`. If CI hasn't finished, the result reads `pending`. The part lists each non-passing check by name and link, with its result word: red, pending, skipped, or unknown. An unreadable status reads "CI status could not be read". The result covers the head that P9 read, so the report words it as "the head that P9 read". Names and links come from `gh` fields only. If a `local-git-only` override applies, this part holds the PR title and description instead.
5. **Clean tree:** the clean-tree result of the scoped `git status --porcelain` check at the end of P9 (req-013). It names each file left over or committed, or reads `clean`.
6. **Exceptions waiting:** every `Exception waiting` line from the build log. If there are none, the part reads `none`.

The report ends with this line: "Next: the human on the loop reviews and merges the PR." No mode merges the PR. Step 12 runs after the report.
