---
title: "ADR 012: Commit subjects without placeholders"
summary: "No commit subject template in a framework skill or workflow holds a placeholder. Subjects name the phase and action only, and the feature ID moves to the body through a second -m. A suite runs each subject through the commit-msg hook."
status: "accepted"
version: "0.1.0"
---
# ADR-012 - Commit subjects without placeholders

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000036-pipeline-friction-and-gate-fixes
**Component:** planifest-framework
**Date:** 2026-10-22

## Context

This ADR serves [req-003](../requirements/req-003-ship-commit-subjects.md) (US-003, backlog 0000160).

`hooks/commit-msg` blocks any commit whose subject runs past 72 characters. `standards/commit-standards.md` sets that limit.

Three ship-agent subject templates embed `{feature-id}`, and the orchestrator quotes one of them. A feature ID can run to 80 characters, so the subject length depends on the feature. 0000035 hit the block at P9 and needed a workaround commit.

Two close-out leftover commits in the ship agent already keep the ID out of the subject. They pass it as a second `-m`, so the body carries it.

## Decision

- **No placeholders in subjects:** No commit subject template in any skill or workflow holds `{`, `}`, `<`, or `>`.
- **Phase and action only:** Each subject names the phase and the action. The new subjects are these:
  - P7 Step 7: `plan(p7): archive plan/current`
  - P9 marker step: `plan(p9): clear session markers`
  - P9 Step 11: `plan(p9): add final report`
- **ID in the body:** Each of those commits passes `-m "{feature-id}"` as a second message. In commands that name paths, it sits before the `--` path list.
- **Steps otherwise unchanged:** Each command keeps its paths, its `git diff --cached --quiet` guard, and its order. The tag message `git tag v{version} -m "{feature-id}"` is not a subject and stays.
- **Suite:** A new suite scans every `SKILL.md` under `skills/` and every file under `workflows/`. It reads each `git commit` subject and each `type(scope): description` span in prose. It fails on a placeholder or a subject past 72 characters. It runs `hooks/commit-msg` on each subject and expects exit 0.
- **Existing suites:** Suites that assert the old subjects take the new text. Each also asserts the `-m "{feature-id}"` body, so the ID stays traceable.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Keep `{feature-id}` and truncate it to fit 72 characters | Subject still names the feature | Truncation rules differ by agent. A cut ID can match two features or none. Every skill must state the rule. | It makes the subject ambiguous and adds a rule every agent must apply by hand |
| Raise the hook limit for `plan(p7)` and `plan(p9)` subjects | No skill change | It weakens a blocking hook for one type and breaks `commit-standards.md`. Tools that show 72 characters would cut the subject. | It moves the problem into the hook and the standard |
| Use the short numeric ID, such as `0000036`, in the subject | Short and still traceable | A seven-digit ID plus the longest action still needs a length check per subject. A second placeholder form invites new long ones. | A subject with no placeholder can't grow, so no per-feature check is needed |
| Fix only the three ship subjects with no suite | Smallest change | A new skill could add a placeholder subject, and nothing would catch it before a ship run | The block hit at P9, the most costly place to find it |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | `skills/planifest-ship-agent/SKILL.md` changes three subjects and adds the body `-m`. `skills/planifest-orchestrator/SKILL.md` quotes the new P9 marker subject. A new suite, `test-0000036-req-003-ship-commit-subjects.sh`, scans skills and workflows. Four existing suites and their regression copies take the new text. |

## Consequences

**Positive:**
- No ship commit can fail the 72-character limit, whatever the feature ID length.
- The suite stops a new placeholder subject before it reaches a ship run.
- The feature ID stays in each commit's body, so `git log` still links the commit to its feature.

**Negative:**
- Every archive commit now has the same subject, `plan(p7): archive plan/current`. `git log --oneline` no longer shows which feature each archive commit belongs to. A reader must open the body or the tag.
- Any tool that reads only the subject line loses the feature link. That covers one-line log views and PR commit lists. `git log --grep` still finds the commits, because it reads the body.

**Risks:**
- The suite's scan misses a subject written in a form it doesn't parse, such as a heredoc. Such a subject would pass unchecked.
- An agent drops the body `-m` while copying the command. The updated suites assert it in the ship agent, but not in other skills that copy the pattern.

## Related ADRs

- 0000033 ADR 011 (close-out commit and leftovers) - related-to. Its leftover commits set the body `-m` pattern this ADR follows.

## Supersedes

- None

## Superseded By

- None
