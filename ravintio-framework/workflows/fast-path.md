---
name: fast-path
description: Apply a trivial fix directly without a Feature Brief, Execution Plan, or ADR. Use ONLY when the change meets all Fast Path criteria defined in the orchestrator skill.
---

# Fast Path

Executes a direct, lightweight change for trivial fixes. Bypasses the full pipeline.

## Prerequisites

- One of these two targets:
  - an existing feature with code at `src/{component-id}/`
  - a change with no `src/` target, such as a change to documentation, governance, tooling, or framework text
- The request meets **ALL** Fast Path criteria (verified by the orchestrator)
- The change touches none of these enforcement paths. `FAST_PATH_ENFORCEMENT_PATHS` in `ravintio-framework/hooks/enforcement/path-rules.mjs` lists the same entries. The gate checks them, ignoring case, before any scope record, so a record never admits one. An always-permitted file name, such as `claude.md`, still passes without a record, even inside an enforcement folder (backlog 0000159). An entry ending in `/` covers everything below it, and a `**/` entry matches at any depth:
  - `ravintio-framework/hooks/`
  - `ravintio-framework/scripts/`
  - `ravintio-framework/setup/`, whose per-tool scripts write the hook wiring files
  - `ravintio-framework/standards/autonomous-run-standards.md`, because it holds the exception list and standing rules
  - `**/setup.sh`, any `setup.sh` file
  - `**/setup.ps1`, any `setup.ps1` file
  - `**/hooks/enforcement/`, any installed enforcement hook folder, such as `.claude/hooks/enforcement/`
  - `**/hooks/adapters/`, any installed hook adapter folder, such as `.cursor/hooks/adapters/`
  - `.git/`, which holds git hooks and config
  - The hook wiring files that `setup.sh` and `setup.ps1` write:
    - `.claude/settings.json` (Claude Code)
    - `.cursor/settings.json` (Cursor)
    - `.clinerules/hooks.json` (Cline)
    - `.windsurf/hooks.json` (Windsurf)
    - `.github/hooks/` (Copilot), the whole folder, because Copilot may load every file in it
    - `.codex/config.toml` (Codex CLI)
    - `opencode.json` (OpenCode)
    - `.opencode/plugins/@ravintio/opencode-hooks/` (OpenCode)
  - The tool-local settings files that a tool also loads hooks from. They are usually git-ignored, so a PR shows no change to them:
    - `.claude/settings.local.json` (Claude Code), whose `disableAllHooks` key turns every hook off
    - `opencode.jsonc` (OpenCode), which OpenCode reads in place of `opencode.json`
  - `.github/workflows/ravintio.yml`, the CI workflow that setup installs. It enforces the `fix(fast-path)` commit rule.

  A change to any of them takes the Change or Feature Pipeline, even with no `src/` target. If a target matches one, stop and route the change there.
- Every target path is plain ASCII. Some file systems fold a lookalike character onto a plain letter. On APFS, `hookſ` names the `hooks` folder. So the scope record never admits a target that holds a non-ASCII character. If a target needs one, take the Change Pipeline.

## Fast Path Criteria

The orchestrator must confirm all four before this workflow is used:

1. Does **not** introduce new external dependencies
2. Does **not** alter, add, or remove database schemas or data models
3. Does **not** change security parameters, authentication, or routing logic
4. Is confined to: UI styling, copy changes, or isolated pure-function logic bugs

**If any criterion fails → use `/change-pipeline` instead.**

## Steps

1. **Orchestrator evaluates the request** against the Fast Path criteria above.
   - If all criteria pass: write the scope record, then proceed.
   - If any criterion fails: stop. Use `/change-pipeline`.

   **Write the scope record.** Before the first change, write `plan/.fast-path-scope` with **Write**. The `plan/` prefix is always permitted, so the gate admits this write. With no design, `gate-write` and the shell-write guard then admit writes to the listed paths and block every other gated path.
   - Fill `branch` from `git rev-parse --abbrev-ref HEAD`. If that prints `HEAD`, write `(detached)`.
   - Fill `head` from `git rev-parse HEAD`.
   - List every path the change writes, one per `- ` line. Include the `component.yml` that step 4 bumps, when one covers the change. `plan/changelog/` needs no entry, because `plan/` is always permitted.
   - Write each entry as a root-relative file or folder path. A trailing `/` names a folder. The record has no glob syntax.
   - Write a new record over any record already there, so a stale record never carries into this change.
   - If you commit or switch branch mid-change, rewrite the record before the next write. The gate ignores a record whose branch or `HEAD` no longer matches.

   The record is self-authorisation. Each write the gate admits through it prints a one-line notice on stderr, and step 5 lists every record path in the changelog. Example:

   ```
   branch: feat/0000040-fix-typo
   head: 3f2a9c1d8e7b6a5f4e3d2c1b0a9f8e7d6c5b4a39
   paths:
   - ravintio-overrides/instructions/review.md
   - docs-site/
   - ravintio-framework/component.yml
   ```

2. **Implement the fix directly.** No Feature Brief, Execution Plan, or ADR required.
   - Apply the minimum change to address the request.
   - Do not refactor beyond the scope of the fix.

3. **Validate.** Run CI checks (lint, typecheck, test, build). Self-correct up to 3 times. If CI still fails after 3 attempts, escalate to the Change Pipeline.

4. **Update `component.yml`.** Update the `component.yml` that covers the changed paths, such as `ravintio-framework/component.yml`. If no manifest covers them, skip step 4.
   - Increment the patch version (e.g. `1.2.3` → `1.2.4`)
   - Update `metadata.updatedAt` to today's ISO-8601 date

5. **Log the change.** Append an entry to `plan/changelog/{feature-id}-{YYYY-MM-DD}.md`:
   ```markdown
   ## {YYYY-MM-DD} - Fast Path: {description}
   - Change: {what was changed}
   - Component: {component-id}
   - Reason: {why}
   - Paths: {every path in plan/.fast-path-scope}
   ```
   For a no-`src/` change, the `Component:` line names the covering manifest's component, or the changed paths if no manifest covers them. The `Paths:` line lists every path from the scope record, so the human on the loop sees each path the gate admitted.

6. **Commit** using the fast-path convention. First remove the scope record, so that no commit holds it:
   ```bash
   rm -f plan/.fast-path-scope
   ```
   The root `.gitignore` also lists the record, as a second guard. The record is a session marker that no commit holds. The Write-or-Edit rule (boot Hard Limit 8) covers code and project files and gives no rule for this marker. This step follows the ship agent, which removes its session markers with `rm -f` in the same way. The shell-write guard passes this `rm`, because the gates always permit `plan/`. Then commit:
   ```
   fix(fast-path): {description}
   ```
   The pre-push hook and CI workflow recognise this prefix and require only `component.yml` or `plan/changelog/` to be updated - not full `plan/` or `docs/` changes.

## What is NOT touched

- `plan/current/design.md` - no modification
- `plan/current/design-requirements.md` - no modification
- `plan/current/adr/` - no new ADRs
- `docs/` - no modification (unless the fix directly corrects a documentation error)

