# Migration: re-run setup for the shell-write guard (0.31.0)

**Target:** a downstream project's installed Planifest enforcement hooks and its tool settings files
**Scope:** files that `setup.sh` or `setup.ps1` installed. This migration never edits `plan/`, `docs/`, or application code.
**Safe to skip:** No. Without a re-run, Claude Code can still write gated paths through Bash, and block reasons stay hidden.

---

## Background

Feature `0000032-governance-continuity-and-write-gate-scope` (framework version 0.31.0) adds two gains that reach a project only when setup runs again.

- **A Bash hook (req-008).** The new `hooks/enforcement/shell-write-guard.mjs` runs on Claude Code's Bash PreToolUse event. It finds common shell writers, such as `>`, `tee`, `sed -i`, `cp`, and `rm`, and judges their targets with the same rules as `gate-write.mjs`. Before this, an agent in auto mode could write `src/` through Bash with no design.
- **Block reasons on stderr (req-007).** Every enforcement hook that blocks now writes its reason to stderr. Claude Code shows the agent a block reason from stderr, so agents can now see why a write was blocked.

Setup copies every `*.mjs` file in `hooks/enforcement/`. It also registers the Bash group in `.claude/settings.json`. Only Claude Code runs the guard. Other tools rely on the boot-file rule that code changes go through **Write** or **Edit**.

---

## What This Migration Does

It refreshes the installed enforcement hooks and settings for each tool the project uses. For Claude Code, it adds one `Bash` PreToolUse group that runs `shell-write-guard.mjs`. Hand-added `Bash` groups stay in place. Setup removes only the group whose command runs `shell-write-guard`, then adds it again, so repeated runs leave exactly one.

---

## Migrator Instructions

1. Confirm that `planifest-framework/component.yml` reports version `0.31.0` or later. If it's older, stop and ask the human on the loop to refresh `planifest-framework/` first. Setup from an older framework doesn't install the guard.
2. Re-run setup for each tool the project uses, with the flags it normally uses. If you use `planifest-refresh-setup`, it rebuilds those flags for you.
3. For Claude Code, check that `.claude/settings.json` holds exactly one PreToolUse group with matcher `Bash` whose command runs `shell-write-guard.mjs`. Also check that `.claude/hooks/enforcement/shell-write-guard.mjs` and `path-rules.mjs` exist.
   - If setup reported that the settings file isn't valid JSON, it skipped the wiring. Fix the JSON, then re-run setup.
   - If setup warned that Node is missing, it skipped the wiring. Install Node, then re-run setup.
4. Archive this migration to `planifest-framework/migrations/_done/`.

---

## Present Findings

Report to the human on the loop:
- each tool that setup ran for, and the flags it used
- whether `.claude/settings.json` holds exactly one `shell-write-guard` Bash group
- anything left for a person to fix, such as malformed JSON or missing Node

---

## Archive

Move this file to `planifest-framework/migrations/_done/` once the human on the loop confirms the findings.
