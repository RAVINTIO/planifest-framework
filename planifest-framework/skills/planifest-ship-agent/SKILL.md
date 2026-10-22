---
name: planifest-ship-agent
description: Phases 7, 8, and 9: archives plan/current/ (P7), spawns build-assessment-agent (P8), then creates a git tag and raises or describes the PR (P9).
bundle_templates: [iteration-log.template.md]
bundle_standards: [formatting-standards.md]
hooks:
  phase: ship
---

# Planifest - ship-agent

> You own the complete close-out sequence: P7 Archive, P8 Build Assessment (sub-agent), and P9 Ship. You write the changelog, process skipped phases, archive the plan, invoke the build-assessment-agent, create a git tag, and hand off the PR. You do not add features or fix bugs. Your job is a clean, complete handoff.

---

## Prefix

Emit the correct phase prefix as you move through each step:
- `P7:` for all archive work (Steps 1–7, including Step 5b)
- `P8:` for build assessment (Step 8)
- `P9:` for ship steps (the P9 marker step and Steps 9–12)

No exceptions. Including single-line acknowledgements.

## Hard Limits

1. Do not modify application code or framework files during this phase.
2. Do not skip the archive step: leaving `plan/current/` populated breaks resume detection for the next feature.
3. Credentials are never in your context.
4. Do not raise a PR or create a git tag without the human's awareness; P9 always confirms with the human first. This holds in `interactive` and `continuous`. In `autonomous`, the human on the loop's P0 choice gives that awareness, and the final report confirms the tag and the PR.
5. **One question at a time.** In `autonomous`, follow the exception list and decision rule in `planifest-framework/standards/autonomous-run-standards.md` instead.
6. **Handover notes route through a track.** Any P9 handover note, next-steps list, or runbook pointer routes each next step through Fast Path, Change Pipeline, or Feature Pipeline. A code change always needs a track. The note never says a code change needs no P0, and never points to a runbook that pushes to `main`.

## Run mode

Read the run mode with `node planifest-framework/scripts/run-mode.mjs`. Never read a run-mode record directly. Before Step 6, run it with no argument, so it reads `plan/current/build-log.md`. After Step 6, pass the archived build log: `node planifest-framework/scripts/run-mode.mjs {archive-dir}/build-log.md`. A resume after the P9 marker step runs the same call. The script prints `autonomous` only when git history anchors it (`standards/autonomous-run-standards.md` `## Run modes`). Never write `plan/.run-mode`, the build-log `Run mode` row, or a `Run mode confirmed:` line. Only the orchestrator writes them.

In `autonomous`, P7 to P9 ask the human on the loop nothing (0000033 ADR-006). The final report in Step 11 is the only output that addresses them. See `planifest-framework/standards/autonomous-run-standards.md`.

## Parallelism Directive

**Always parallel:** dispatch these units in one batch (see Always-parallel work units in `planifest-framework/standards/agent-dispatch-standards.md`).
- The P7 cross-reference search for `plan/current/...` links, and the Step 4 scan for `# REGRESSION-CANDIDATE:` tags. Both are read-only searches.

The numbered P7 and P9 steps stay in order, because each step reads the output of the step before it.

## P7: Archive

**Build log first:** Append a P7 phase block to `plan/current/build-log.md` before doing any work in this phase. When P7 finishes, fill `End`, `Wall-clock`, and `Agents spawned`, then write the P7 progress line to the archived build log, in every run mode.

Work through these steps in order. Write each artifact to disk before proceeding to the next step. Input: all artifacts at `plan/current/`, plus `plan/current/.skips` if any phases were skipped.

**Cross-reference check (run first, before Step 1):** Before writing the changelog, search the repo for links pointing at `plan/current/...`: `docs/*.md` (especially `docs/decisions-index.md`'s ADR links), `src/*/docs/*.md`, and any other living doc. Update every found reference to the post-archive path (`plan/_archive/{feature-id}-{YYYY-MM-DD}/...`) in the same commit as the archive move. A moved folder with stale incoming links silently breaks navigation for the next reader.

### Step 1: Write changelog

> **Audience:** PR reviewers and team members: the human-readable *what and why*, not the execution trace (that's the iteration log written by docs-agent at P6).

Write `plan/changelog/{feature-id}-{YYYY-MM-DD}.md` as the permanent audit trail (filename uses `YYYY-MM-DD`; body uses `DD MMM YYYY`):

```markdown
# Changelog ({feature-id}, {DD MMM YYYY})

**Feature:** {feature name from brief}
**Pipeline run:** {phases completed, phases skipped}
**PR:** {pending, updated after PR is raised in Step 10}

## What Was Built
{Summary from feature brief}

## Artifacts Produced
{List of plan/current/ artifacts written}

## Decisions
{One-liner per ADR}

## Skipped Phases
{Contents of .skips, or "None"}
```

### Step 2: Process .skips

If `plan/current/.skips` exists:
1. Read its contents
2. Delete `plan/current/.skips` after the changelog is confirmed written

### Step 3: Write .feature-id marker

Write `plan/current/.feature-id` containing the feature ID (e.g. `0000012-docs-restructure-commit-directives`).

### Step 4: Regression confirmation

Before archiving, present agent-tagged regression candidates to the human for curation.

1. Scan all test files produced during P3/P4 for the `# REGRESSION-CANDIDATE:` tag.
2. Present the tagged candidates to the human for confirmation (y/n per candidate, or 'all'/'none').
3. For each confirmed candidate, run:
   ```bash
   bash planifest-framework/scripts/promote-to-regression.sh \
     "{test-file-path}" "{feature-id}" "human"
   ```
   `{test-file-path}` must be a `test-*.sh` file directly inside `planifest-framework/tests/`. The script refuses any other source and exits 1.
4. If no candidates are tagged: note "No regression candidates" and continue.
5. In `autonomous`, skip the prompt. Decide each candidate yourself and write a `Decision` build-log line for it. For each promoted candidate, pass `"agent"` as the promoted-by argument in place of `"human"`. The final report lists each candidate and its decision.

### Step 5: Test report

Generate the test report artifact before archiving.

1. Read `planifest-framework/templates/test-report.template.md`.
2. Populate all sections: tests run (P4), regression pack state, newly promoted tests.
3. Write to: `plan/changelog/{feature-id}-test-report-{YYYY-MM-DD}.md`

### Step 5b: Set product.yml release fields

Run this step before Step 6 archives `design.md` (0000035 ADR-010). You own `product.yml`. Write it only through `set-product-release.mjs`, never through **Write** or **Edit**. The Write-or-Edit rule (boot Hard Limit 8) names the script as a sanctioned script (0000035 ADR-011).

1. Take `{version}` from the version the human on the loop confirmed in `plan/current/design.md` at P0. Run:
   ```bash
   node planifest-framework/scripts/set-product-release.mjs --feature-id "{feature-id}" --version "{version}"
   ```
2. If this feature added or removed a component, add one `--component "{id}={path}"` for each component in the design. `{path}` is the path to that component's `component.yml`. The script then replaces the whole `components[]` list. Without `--component`, it leaves `components[]` byte-identical.
3. Act on the exit code:
   - Exit 0: `product.yml` names this release's `version` and `feature`. Continue.
   - Exit 5: the policy is `external`, and only `feature` changed. Step 9 consults the external anchor or the human on the loop.
   - Exit 4: no `product.yml` exists. With exactly one component, do nothing, because Step 9 reads that `component.yml`. With two or more components, rerun the call with `--create --product-id "{id}" --product-name "{name}"` and one `--component` for each component. Take `{id}` and `{name}` from the design.
   - Exit 2: the script wrote nothing, and stderr names the reason. If an argument broke a rule, correct it and rerun. If the reason names a file-system error code, such as `EACCES`, fix the file or folder permission and rerun. If the manifest is invalid or the derived version differs from `{version}`, stop and report the reason. Never tag a fabricated version.
4. Log the line the script printed in the P7 build-log block.

### Step 6: Archive plan/current/

1. Run the archive script as a single command (0000033 ADR-010):
   ```bash
   node planifest-framework/scripts/archive-current.mjs --feature-id "{feature-id}"
   ```
   The script moves each item into `plan/_archive/{feature-id}-{YYYY-MM-DD}/`, or the first free `-2`, `-3` suffix, with one `git mv` or rename per item. It removes `.skips`, `.planifest-session`, `.feature-id`, and `capability-skills/` by explicit path. It leaves `plan/current/` empty.
2. Record the `archive-dir:` line it prints as `{archive-dir}`. P8 and P9 use that name.
3. If the script exits non-zero, fix the cause it names and rerun it. A rerun finishes into the same directory. Never fall back to a glob delete such as `rm -rf plan/current/*`.
4. Log each line the script printed in the P7 build-log block.
5. Cross-reference check: confirm the check above (which updates `docs/decisions-index.md` ADR links and other living-doc references pointing at `plan/current/...`) has already run before this point.

### Step 6b: Write docs/about.md

**This is a blocking step.** Do not proceed to Step 7 until `docs/about.md` is written.

1. Create `docs/` if it does not exist
2. Read `planifest-framework/templates/about.template.md` for the exact format
3. Write `docs/about.md` with `version` (the human-confirmed version from `plan/current/design.md`, confirmed at P0), `feature` (the current feature ID), and `updated` (today's date, `DD MMM YYYY`, e.g. `19 May 2026`). Do not copy the template's comment block (`> This file is the canonical version record...`) into the output; write only the frontmatter and table.

### Step 7: Commit archive

Commit the archive, changelog, `docs/about.md`, and `product.yml` to the branch in one commit. Step 5b wrote `product.yml`, so stage it whenever it exists:

```
git add plan/current/ plan/_archive/ plan/changelog/ docs/about.md
if [ -f product.yml ]; then git add product.yml; fi
git commit -m "plan(p7): archive plan/current" -m "{feature-id}"
```

## P8: Build Assessment

**Build log:** Append a P8 phase block to `{archive-dir}/build-log.md` before invoking the build-assessment-agent: `plan/current/` has already been archived by Step 6, so this is the only copy of the log. When P8 finishes, fill `End`, `Wall-clock`, and `Agents spawned`, then write the P8 progress line, in every run mode.

**Before acting:** Load the `planifest-build-assessment-agent` skill now.

1. Confirm the archive path from Step 6 exists
2. Invoke the build-assessment-agent as a sub-agent, passing the archive path: `{archive-dir}/`
   ```
   Agent({
     subagent_type: "general-purpose",
     model: "claude-haiku-4-5",
     description: "Build assessment for {feature-id}",
     prompt: "Load the planifest-build-assessment-agent skill. Archive path: {archive-dir}/. Read build-log.md from the archive and write build-report.md to the same directory. Confirm with P8: Complete when done."
   })
   ```
3. Wait for `P8: Complete` before proceeding to the P8 clean-tree check

### P8: Clean-tree check

Run this after `P8: Complete` (0000033 ADR-011):

```bash
git status --porcelain --untracked-files=all -- plan/ docs/ ':(glob)src/**/docs/**'
```

The `--untracked-files=all` flag lists each untracked file, not just its directory. Leave out lines under `{archive-dir}`, because the P9 marker step commits them. Treat every other line as a leftover. Read the run mode with `node planifest-framework/scripts/run-mode.mjs {archive-dir}/build-log.md`. The script reads the `Run mode` row of that log.

**P8 credential guard (0000033 P5):** In `autonomous`, check every leftover before you stage it. Refuse these files:

- any file named `.env*`, `*.pem`, `*.key`, `id_rsa*`, `*.p12`, `.npmrc`, `credentials.json`, `*.keystore`, or `.netrc`
- any file whose content matches a credential pattern:
  ```bash
  grep -lE -e 'AKIA[0-9A-Z]{16}|-----BEGIN .*PRIVATE KEY-----|ghp_[A-Za-z0-9]{36}|xox[baprs]-|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9_-]{20,}|AIza[0-9A-Za-z_-]{35}' -- {path} ...
  ```
- any file that `gitleaks` flags, if `gitleaks` is on PATH. Run it over each candidate file:
  ```bash
  if command -v gitleaks >/dev/null; then gitleaks detect --no-git --source {path} --no-banner --redact; fi
  ```
  A non-zero exit refuses that file.

Refused files stay uncommitted. Record each one as an exception item in the final report, by path only. Never copy the matched content. This follows the credentials rule (orchestrator Hard Limit 6). The guard keeps the scope to `plan/`, `docs/`, and `src/**/docs/`.

- **No leftovers:** Log `Clean-tree check: clean` in the P8 build-log block and continue to P9.
- **`autonomous`:** Apply the credential guard above. Then stage each remaining leftover by its explicit path. Commit with the paths after `--` and the feature ID in the body:
  ```bash
  git add -- {path} ...
  git commit -m "plan(p8): commit close-out leftovers" -m "{feature-id}" -- {path} ...
  ```
- **Other modes:** Carry each leftover into the Step 11 gate summary. Don't stop here.

## P9: Ship

**Build log:** Append a P9 phase block to `{archive-dir}/build-log.md` before beginning ship steps. When P9 finishes, fill `End`, `Wall-clock`, and `Agents spawned`, then write the P9 progress line, in every run mode.

### P9 marker step: Clear session markers

The session markers stay in place through P7 and P8, so hooks treat the whole close-out as part of the run. Clear them here, before the tag, so the tag never carries a marker.

In this step, `{archive-dir}` is the directory P7 Step 6 created, with any `-2` or `-3` suffix it added. On a resume, it is the directory that Resume Detection step 2a resolved. Never rebuild it from the date.

1. Run `git status --porcelain plan/_archive/`. If it lists a change outside this feature's archive directory, report those paths to the human on the loop. Do not stage them.
2. Stage only `{archive-dir}`. The commit then also carries the P8 `build-report.md` and the P8 and P9 build-log blocks.

```bash
git status --porcelain plan/_archive/
git add -- "{archive-dir}"
```

Then check that `{archive-dir}/build-report.md` is staged or already tracked by `HEAD`. If the command fails, the report is neither. Stop and resume at P8. Don't commit the marker deletions without the report.

```bash
git cat-file -e ":{archive-dir}/build-report.md"
```

3. Delete the markers, stage the deletions, and commit as one uninterrupted sequence. Do no other work between the first delete and the commit.
   - Delete `plan/.orchestrator-active`.
   - Delete `plan/.orchestrator-ack` if it exists.
   - Delete `plan/.run-mode` if it exists.
4. Run the sequence, then check that no marker stays tracked:

```bash
rm -f plan/.orchestrator-active plan/.orchestrator-ack plan/.run-mode
git rm --cached --ignore-unmatch -q plan/.orchestrator-active plan/.orchestrator-ack plan/.run-mode
git diff --cached --quiet -- "{archive-dir}" plan/.orchestrator-active plan/.orchestrator-ack plan/.run-mode || git commit -m "plan(p9): clear session markers" -m "{feature-id}" -- "{archive-dir}" $(git ls-tree --name-only HEAD -- plan/.orchestrator-active plan/.orchestrator-ack plan/.run-mode)
git ls-files plan/.orchestrator-active plan/.orchestrator-ack plan/.run-mode
```

The commit names its paths after `--`, so it commits only `{archive-dir}` and the markers. Other staged changes stay staged and stay out of this commit. The `git ls-tree` call lists only the markers that `HEAD` tracks. A marker path that git doesn't know would make `git commit` fail, so the list leaves it out. The `--ignore-unmatch` flag lets the stage step pass when an optional marker never existed.

If nothing is staged under these paths, skip the commit and continue to Step 9. The `git diff --cached --quiet -- ...` guard does this. If the `git ls-files` output is empty, proceed to Step 9. If it isn't empty, stop and name each tracked path to the human on the loop. Do not tag.

### Step 9: Create git tag

Run this step only after the P9 marker step commits, or skips an empty commit.


Determine the release version (ADR-002, product-level versioning):

1. **`product.yml` exists at the project root**: derive the version from it:
   ```bash
   node planifest-framework/scripts/product-version.mjs
   ```
   Exit 0 → use the printed version. Exit 5 (`versionPolicy: external`) → present the external-anchor constraint and ask the human for the version. Exit 2 (invalid version, unknown policy, or a `components[]` entry pointing at a missing/unversioned `component.yml`) → show the script's reason and prompt the human for a manual value; never tag a fabricated version. `components[]` entries hold `{id, path}`, not a cached version: the script reads each referenced `component.yml`'s own `version:` field live, so there is nothing to sync here before tagging.

   Step 9 only reads `product.yml`. Step 5b set its release fields at P7 (0000035 ADR-010). If the derived version differs from the version the human on the loop confirmed at P0, stop and report the difference. Leave the file as it is. A stale file waits for the next P7.
2. **No `product.yml` and the project has exactly one component** (exit 4): read the `version` field from the single `component.yml` (for this repo: `planifest-framework/component.yml`). This is the unchanged pre-0000016 behaviour.
3. **No `product.yml` and the project has 2+ components**: Step 5b runs the script with `--create` at P7, so the file exists by now. If it is still missing, stop and report it. Don't tag.

Validate the final value: must match `[0-9]+\.[0-9]+(\.[0-9]+)?` and be ≤20 characters, and must not be lower than the last release tag. If validation fails, prompt the human to supply the version manually: do not create the tag with an unvalidated value.

```bash
git tag v{version} -m "{feature-id}"
```

### Step 10: Push/PR decision

Check `planifest-overrides/instructions/` for any file containing "local-git-only" or "no remote" or "no push". If found, skip the prompt and proceed directly to option [2].

Also check `planifest-overrides/instructions/` for any file whose contents contain "restore-pr-attribution" (case-insensitive substring match, same scan style as the check above). This controls the attribution footer in the PR description template below (Option [1] and Option [2] share the same body): if matched, the footer line `🤖 Generated with [Planifest](https://github.com/planifest/framework) + Claude` is appended as the final line of the PR description; if not matched (the default), the footer is omitted entirely.

In `autonomous`, with no `local-git-only` override, skip the prompt and take Option [1]. With the override, take Option [2] and put the PR title and description in the final report.

**Branch check (0000033 P5):** In `autonomous`, run `git branch --show-current` before any push. If it prints the default branch, or a name that doesn't start with `feat/`, don't push. Take Option [2] and record the refusal as an exception item in the final report.

**Draft PR while an exception waits (0000033 D-003):** In `autonomous`, if the build log holds any `Exception waiting` line, Option [1] raises the PR with `gh pr create --draft`. The PR description lists every waiting exception. With no waiting exception, raise the PR ready for review.

**After the PR:** In `autonomous`, push each commit the run makes after the PR is raised straight away, unless the `local-git-only` override applies. No step in any mode merges the PR.

Otherwise, ask the human:

```
P9: Ready to ship.

Git tag v{version} created locally.

Who pushes the branch and raises the PR?
  [1] Agent pushes and creates the PR (git push + gh pr create)
  [2] Human pushes and creates the PR: the agent gives the PR title and description
```

**Option [1] (Agent pushes):**
```bash
git push -u origin HEAD
git push origin v{version}
gh pr create \
  --title "{feature-id}: {one-line feature summary}" \
  --body "$(cat <<'EOF'
{PR description, see template below}
EOF
)"
```
Capture the PR URL. Update the changelog (`## PR` field) with the URL.

Push only the branch and the `v{version}` tag. No step in any mode uses `--force` or `--force-with-lease`.

**Option [2] (Human pushes):**

Output the following as a fenced markdown code block for copy-paste:

```markdown
## Summary
{2–4 bullet points: what was built, what changed, why}

## Key Decisions
{1–3 ADR references with one-liner rationale}

## Security
{Critical/high findings if any, or "No critical/high findings."}

## Skipped Phases
{Contents of .skips if present, or omit section entirely}

## Test Plan
{Bulleted checklist of manual verification steps}
{Attribution footer, append "🤖 Generated with [Planifest](https://github.com/planifest/framework) + Claude" as the final line only if the restore-pr-attribution override matched above. Default: omit this line entirely.}
```

Also output the suggested PR title: `{feature-id}: {one-line feature summary}`

### Step 10b: Clean-tree check

Run the P8 command again after Step 10 (0000033 ADR-011):

```bash
git status --porcelain --untracked-files=all -- plan/ docs/ ':(glob)src/**/docs/**'
```

Leave out nothing. Treat every line as a leftover. This catches the Step 10 changelog PR-URL edit and any other late change. Read the run mode with `node planifest-framework/scripts/run-mode.mjs {archive-dir}/build-log.md`. The script reads the `Run mode` row of that log.

- **No leftovers:** Log `Clean-tree check: clean` in the P9 build-log block.
- **`autonomous`:** Apply the P8 credential guard first. Then stage each remaining leftover by its explicit path. Commit with the paths after `--` and the feature ID in the body. If Step 10 pushed the branch, push this commit too.
  ```bash
  git add -- {path} ...
  git commit -m "plan(p9): commit close-out leftovers" -m "{feature-id}" -- {path} ...
  ```
- **Other modes:** Carry each leftover into the Step 11 gate summary.

### Step 11: Confirm to human

In `autonomous`, write the final report in place of the message below. `planifest-framework/standards/autonomous-run-standards.md` `## Final report` gives its six parts. Write the report to `{archive-dir}/final-report.md`, then commit it by explicit path:

```bash
git add -- "{archive-dir}/final-report.md"
git commit -m "plan(p9): add final report" -m "{feature-id}" -- "{archive-dir}/final-report.md"
```

Push that commit under the after-PR push rule. The report then survives the Step 12 context clear. The chat message points to the file. Step 12 still runs after the report. In `interactive` and `continuous`, send this message:

```
P9: Ship complete.

Git tag: v{version} ({if Option [1] was chosen: "already pushed" | "push with: git push origin v{version}"})
PR: {URL if agent raised it | "See PR description above"}
Archive: {archive-dir}/
Changelog: plan/changelog/{feature-id}-{YYYY-MM-DD}.md
Build report: {archive-dir}/build-report.md
{If skips: "Skipped phases recorded in changelog."}
Clean-tree check: {clean | committed {n} files | {n} files listed below}

plan/current/ is empty and ready for the next feature.
```

Outside `autonomous`, list each P8 and P9 leftover below the clean-tree line, with the step or sub-agent that wrote it, where known. Then ask whether to commit and push them. The P9 gate already stops here, so this adds no new stop. The human on the loop may decline. Never leave a leftover unreported.

If the confirmation lists next steps, each one names its track: Fast Path, Change Pipeline, or Feature Pipeline. This follows the handover-track rule (ship agent Hard Limit 6).

### Step 12: Blocking context clear

This step blocks new work (0000032 ADR-003). After the confirmation above:

1. Ask the human on the loop to run `/clear`, or the host tool's equivalent, or to start a new session.
2. If a new request arrives in the same session, refuse that work and repeat the request to clear context.
3. Don't start triage, P0, or any edit for the new request in this session.

Use this message:

```
P9: This run is complete. Run /clear (or your tool's equivalent) or start a new session before the next request. I won't start new work in this session.
```
