# Planifest - Mandatory Framework Rules

This project uses the confirmed design framework. These rules are non-negotiable and apply to every session.

## Hard Limits

1. **No code without a confirmed design.** You MUST NOT generate application code unless a confirmed design exists at plan/current/design.md. If none exists, load the planifest-orchestrator skill and begin Phase 0 (Assess and Coach). Do NOT skip to code generation.
2. **No code without documentation.** Every component MUST have a component.yml manifest and docs/ artifacts. Never produce code without its corresponding documentation.
3. **No direct schema modification.** Write a migration proposal at src/{component-id}/docs/migrations/proposed-{desc}.md and STOP for human approval.
4. **Destructive schema operations require human approval.** Drop column, drop table, rename - propose and stop. No exceptions.
5. **Data is owned by one component.** Never write to data owned by another component.
6. **No credentials in context.** If a credential appears anywhere, flag it immediately and do not use it.
7. **Update documentation after any deviation.** If implementation required deviating from the spec, plan, or design decisions, you MUST update the affected artifacts (plan/, docs/, or component.yml) to reflect what was actually built. Documentation must always match reality.
8. **Code changes go through Write or Edit.** Make every change to code and project files through **Write** or **Edit**, never through Bash. Don't use `>`, `tee`, `sed -i`, `cp`, a script, or an interpreter one-liner to change them. The shell guard is a heuristic. It can't see writes made inside scripts, interpreters, build tools, or git, and some tools don't run it at all. Sanctioned scripts: a skill step may run `planifest-framework/scripts/archive-current.mjs`, `planifest-framework/scripts/set-product-release.mjs`, `planifest-framework/scripts/promote-to-regression.sh`, `planifest-framework/scripts/refresh-delete-boot-files.sh`, `planifest-framework/scripts/refresh-delete-boot-files.ps1`, `planifest-framework/setup.sh`, or `planifest-framework/setup.ps1` to write files, and no other script counts. Each script counts only with the arguments its skill step shows. `setup.sh` and `setup.ps1` count only with one tool name that they accept, including `all`. The call may add none, either, or both of `--include-full-skill-library` and `--strict-orchestrator`. `add-skill` and every other subcommand or flag are not sanctioned.

## Operational Directives

- **Be succinct:** Minimal prose. Format answers in markdown with brevity.
- **Commit messages:** Never add `Co-Authored-By` or any AI attribution. The `commit-msg` hook is **blocking**: commits with AI attribution, affirmatory language, or >72-char subjects will be rejected. Follow `planifest-framework/standards/commit-standards.md`.
- **Do not invent APIs:** Only call endpoints that explicitly exist in the provided OpenAPI interfaces.
- **Check `.cursorindexingignore`:** The `standards/reference/` directory and guide files are deliberately excluded from your semantic search index to preserve your context window. If you need deep domain knowledge about frameworks or pitfalls, explicitly read those files using `@` mentions.

## Hook Enforcement

Planifest installs these deterministic enforcement hooks via `setup.sh`:

- **gate-write** (PreToolUse: Write, Edit): Blocks writes to `src/` unless `plan/current/design.md` exists AND the target path matches a declared component. Writes to `plan/`, `docs/`, and other always-permitted paths are never blocked. Paths outside the repository are never gated.
- **shell-write-guard** (PreToolUse: Bash, Claude Code only): Blocks common shell writers, such as `>`, `tee`, `sed -i`, `cp`, `mv`, and `rm`, when `gate-write` would block a **Write** to the same path. It is a heuristic and passes git commands and anything it can't parse, so Hard Limit 8 still applies.
- **auto-trigger-orchestrator** (UserPromptSubmit): At the start of every session in a Planifest project (`planifest-framework/` present and `plan/.orchestrator-active` absent), automatically loads the `planifest-orchestrator` skill before the first prompt is processed. This is the primary trigger mechanism for Claude Code. For tools without `UserPromptSubmit` hook support (Cursor, Windsurf, Cline, etc.): **at the start of every session in a Planifest project, load the `planifest-orchestrator` skill** before doing any other work.
- **check-design** (UserPromptSubmit): Injects active component scope from `design.md` as additional context.
- **commit-msg** (git hook): Blocks commits with AI attribution, affirmatory language, or >72-char subjects. Exit 1 on violation; use `git commit --no-verify` to bypass intentionally.
- **ratchet-check** (PreToolUse: Write, Edit): While a loop/reversal is active (a `plan/current/loop-state-*.md` with `status: active`), blocks writes that remove acceptance-criteria or in-scope lines from `plan/current/` artifacts. Strengthening passes; intentional weakening needs a human-written `plan/current/.ratchet-approve` line (single-use). Agents must never write that marker.

Enforcement failures exit 2 and surface a human-readable message. Each blocking hook writes its block reason to stderr, so the agent sees why a write was blocked. All unexpected errors exit 0; hooks never block your session unexpectedly.

## Escalation

If you are blocked, unable to resolve tests after 5 attempts, or confused by conflicting requirements, **STOP**. Do not guess. State clearly what is blocking you and ask the human for direction.
