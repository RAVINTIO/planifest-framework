---
title: "ADR 008: Run-mode anchor as a bare line or one list item"
summary: "run-mode.mjs accepts the autonomous anchor as a whole bare line at column 1 or with one leading hyphen and space, with a real UTC timestamp. Every other form counts as no anchor. The one-commit rule, the removal rule, and the design Confirmation check stay strict, so the wider match costs no integrity."
status: "accepted"
version: "0.1.0"
---
# ADR-008 - Run-mode anchor as a bare line or one list item

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000036-pipeline-friction-and-gate-fixes
**Component:** planifest-framework
**Date:** 2026-10-22

## Context

This ADR serves [req-004](../requirements/req-004-run-mode-anchor-format.md) (US-004, backlog 0000127).

`planifest-framework/scripts/run-mode.mjs` restores `autonomous` after P0 from one anchor line in the build log. The script trusts the line only under strict rules from 0000033 req-001:

- Exactly one commit adds the line.
- No commit removes or edits it.
- The same commit sets the design Confirmation line to `yes`.

The script matches the line only when it starts at column 1 with `LINE_PREFIX`. An orchestrator that writes the anchor as a Markdown list item fails both the working-tree check and the history check. The script then prints `interactive`, and the run needs a repair commit. The orchestrator skill quotes the line inline, and the build-log template shows no line at all, so the slip is easy to make.

The anchor is an integrity control. Any agent can write the build log, so the script treats it as untrusted text. A wider match widens what the script trusts. The design risk register rates that risk as low likelihood and high impact.

## Decision

- **Two forms:** A line counts as an anchor only when it matches `^(- )?` followed by `LINE_PREFIX` at column 1. That means the bare form, or one hyphen and one space, then the bare form.
- **Whole line, real timestamp (P5 S-1, S-2):** The whole line must match `^(- )?Run mode confirmed: autonomous \((\d{4}-\d\d-\d\dT\d\d:\d\d:\d\dZ)\)\r?$`. The timestamp must be a real UTC time, so an impossible date fails. A placeholder such as `{ISO-8601 timestamp}` never counts. Trailing text never counts. The working-tree count and the history check both use this rule.
- **Every other form is no anchor:** Leading spaces or tabs, `* `, `+ `, `> `, `1. `, `-- `, `- - `, and a hyphen with two spaces or a tab all count as no anchor line.
- **One line in total:** The working-tree check counts both forms together. One bare line plus one list line reads as two, and the check fails.
- **History reads both forms:** The history check reads `+` or `-` followed by either form. A removal of either form still fails.
- **Exact match to the anchor commit:** The working-tree line must equal the line the anchor commit added, prefix included. A commit that turns a bare line into a list item removes one form and adds the other, so the removal rule rejects it.
- **Rules that stay strict:** The one-commit rule, the removal rule, and `CONFIRM_RE` don't change. The merge rule, the rename rule, the symlink checks, and the 1 MB read cap don't change.
- **Fallback:** A forged, uncommitted, or missing anchor prints `interactive` with one reason line on stderr, as today.
- **Preferred form:** The orchestrator skill shows the bare line in a fenced code block. The skill calls it the preferred form and says the script also accepts one `- ` list item.
- **Template form (P5 S-1):** P0 copies `templates/build-log.template.md` into every build log. So the template never holds a line that starts like an anchor. It quotes the line inline in backticks, with the `{ISO-8601 timestamp}` placeholder. It says the orchestrator writes the real line itself, bare at column 1, with the real timestamp. The first version showed the line at column 1 in a fenced block. Every copied build log then held an anchor, which broke genuine restores and let a run with no orchestrator anchor read as `autonomous`.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Keep the bare form only and fix the skill and template text | No change to what the script trusts | A format slip still costs a repair commit. Text guidance has already failed to stop it. | It leaves US-004 unmet, because a list-item anchor still reads as `interactive` |
| Strip any Markdown list or quote prefix before matching | Tolerates every format an agent might write | Each new prefix is a new form to reason about. Indented lines could hide inside nested lists or code blocks. | It widens the trusted input far beyond the one slip seen in practice |
| Match the prefix anywhere in the line | Shortest matching code | A sentence that quotes the anchor would count as an anchor. Prose in the build log could forge or double it. | It turns quoting into forging and breaks the one-line count |
| Relax the one-commit rule so a later commit can fix the format | Lets the run repair a slip without a new anchor | A later commit could then add or reshape the anchor after the design was confirmed | It removes the tie between the anchor and the design confirmation, which is the core integrity rule |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | `scripts/run-mode.mjs` matches two whole-line forms with a real timestamp in both checks and names them in its header rule 3. `skills/planifest-orchestrator/SKILL.md` shows the bare line in a code block. `templates/build-log.template.md` quotes it inline. `tests/test-0000033-req-001-run-mode-script.sh` and its regression copy gain the req-004 fixture cases and the P5 S-1 and S-2 cases. |

## Consequences

**Positive:**
- A list-item anchor written in the design-confirm commit restores `autonomous`, so the slip from backlog 0000127 needs no repair commit.
- Every rule that ties the anchor to the confirmed design stays as strict as before.
- The skill and template show the exact line, so fewer agents make the slip at all.

**Negative:**
- The script now trusts two line shapes instead of one. Every future change to the anchor rules must reason about both, and each suite case must cover both.
- An agent that writes the anchor in any third form, such as an indented list item, still falls back to `interactive`. That run still needs a repair commit, and the human on the loop gets no warning beyond one stderr line.

**Risks:**
- A future edit loosens the regular expression by accident and admits a third form. The suite's negative cases for indented and other-prefix lines catch that.
- An agent learns that `- ` works and stops using the preferred bare form. Both forms pass, so the only cost is inconsistent build logs.

## Related ADRs

- 0000033 ADR 002 - depends-on. It defines `autonomous`. The anchor rules this ADR keeps come from 0000033 req-001, which no ADR records.
- ADR-009 - related-to. It changes another default that depends on the run mode the anchor restores.

## Supersedes

- None

## Superseded By

- None
