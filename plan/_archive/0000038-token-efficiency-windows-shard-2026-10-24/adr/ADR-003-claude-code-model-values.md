---
title: "ADR 003: Claude Code model values are sonnet, opus, haiku, and fable"
summary: "The Claude Code column, the dispatch skeleton, and any skill model line hold only sonnet, opus, haiku, or fable. Primary maps to sonnet and cheaper maps to haiku. A Bash test enforces the set."
status: "accepted"
version: "0.1.0"
---
# ADR-003 - Claude Code model values are sonnet, opus, haiku, and fable

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000038-token-efficiency-windows-shard
**Component:** planifest-framework
**Date:** 2026-10-24

## Context

The Claude Code Agent tool `model` parameter accepts the aliases `sonnet`, `opus`, `haiku`, and `fable`. The dispatch standard names full ids instead: `claude-sonnet-4-6` and `claude-haiku-4-5` in the tier table, and `model: "claude-haiku-4-5"` in the dispatch skeleton. The ship-agent and `pipeline-reference.md` repeat full ids. Backlog 0000230 found that subagents then ran on the parent model, Opus, so cheap work paid the Opus rate.

Other tool rows (Cursor, Codex, Copilot, Windsurf, Cline) need their own ids and stay as they are. Windsurf shares the Claude ids but is not Claude Code.

Assumption A-001 (the tool honours `haiku` and `sonnet`) cannot be proved inside this run.

## Decision

1. The allowed value set for Claude Code is exactly `sonnet`, `opus`, `haiku`, and `fable`.
2. The Claude Code row of the tier table reads `sonnet` for primary and `haiku` for cheaper. No task type changes tier (A-004). `opus` and `fable` are allowed values but no tier maps to them today.
3. The dispatch skeleton passes `model: "haiku"`.
4. The ship-agent example (line 186) and the Claude Code row of `pipeline-reference.md` (line 111) change to the aliases.
5. A new test, `test-0000038-req-002-model-values.sh`, extracts four things and fails on any value outside the set:
   - the Claude Code cell of each row in the tier table, including the text "or latest Sonnet"
   - every `model:` value in the dispatch skeleton (both calls)
   - every line that matches `^[[:space:]]*(recommended_)?model:` in `planifest-framework/skills/*/SKILL.md` and `planifest-framework/standards/*.md`, indented or not, including `recommended_model:` and the indented `model:` in the ship-agent code block
   - every `model:` line in `planifest-framework/pipeline-reference.md`, which the test reads so the Claude Code row cannot drift again
   Fixture runs prove it fails on `claude-haiku-4-5`.
6. The check is an allowlist, not a blocklist of full ids. A future id with a new prefix fails by default.
7. P4 verifies by execution. It dispatches one `haiku` subagent and checks the model it reports.

Decision (P2): the Claude Code value set is `sonnet`, `opus`, `haiku`, `fable`, checked by allowlist / reason: it matches the values the Agent tool accepts, and an allowlist catches ids the team has not seen yet.

Decision (P2): Windsurf and other tool rows keep their full ids / reason: they are not Claude Code, and the requirement keeps those rows as they are.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Keep full ids and document "or latest" | No edits | Ids rot, and the tool may ignore them | The bug stays |
| Pin dated model ids | Exact | Breaks on each release | Needs edits on every release |
| Blocklist `claude-*` ids | Small test | Misses other bad values | Allowlist is stricter |
| Set `model` in each skill's frontmatter | Per-skill control | Skills do not select the dispatch model today | Out of scope |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | Edits to the standard, ship-agent skill, pipeline reference, and one new test |

## Consequences

**Positive:**
- Cheap tasks can run on Haiku, which is the saving that backlog 0000230 estimated at 19.9% to 26.1%.
- A future bad value fails the suite.

**Negative:**
- Aliases follow the tool's idea of "latest", so the exact model can change under the framework.

**Risks:**
- If the tool ignores aliases, savings stay at zero. P4 execution and the one-week re-run catch it.
- Installed copies under `.claude/skills/*/references/` stay stale until setup re-runs (ADR-007).

## Related ADRs

- ADR-006 - related-to (both edit `agent-dispatch-standards.md`, so they run in sequence)
- ADR-007 - depends-on (installed copies refresh through the migration)
- The model tier abstraction that feature 0000006 set - extends. The tier names stay and the Claude Code values change.

## Supersedes

- None.

## Superseded By

- None.
