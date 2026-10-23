---
title: "ADR 004: shown() cuts at whole units, and two more hook outputs use it"
summary: "shown() cuts only between whole escapes and whole code points. ratchet-check and em-dash-guard print quoted text through shown() with a 200-character cap, and em-dash-guard imports shown from path-rules.mjs."
status: "accepted"
version: "0.1.0"
---
# ADR-004 - shown() cuts at whole units, and two more hook outputs use it

**Skill:** [adr-agent](../../../planifest-framework/skills/planifest-adr-agent/SKILL.md)
**Feature:** 0000036-pipeline-friction-and-gate-fixes
**Component:** planifest-framework
**Date:** 2026-10-22

## Context

0000035 req-001 added `shown()` to `path-rules.mjs`. It escapes each control, format, and separator character, then calls `escaped.slice(0, max)`. Backlog 0000149 found three gaps:

- The cut can fall inside an escape, leaving a bare `\u{20` (risk R-009).
- The cut can fall between the halves of a surrogate pair, leaving a lone surrogate.
- Two hooks print quoted text raw. `ratchet-check.mjs` prints each removed criterion as it is. `em-dash-guard.mjs` prints its target as it is and imports nothing from `path-rules.mjs`.

A criterion that holds U+202E can reorder the block message on display. A target that holds a newline can forge a second `[Planifest]` line. Either can hide why a hook blocked.

req-011 serves US-011. Risk R-003 records that a new cut can shift text that existing suites match.

## Decision

- **Units:** `shown(p, max)` builds its output from whole units. A unit is one escape sequence, such as `\n`, `\x1b`, or `\u{202E}`, or one unescaped code point.
- **Cut:** It appends units in order while the output stays within `max` UTF-16 code units. It stops before the first unit that would pass `max`. The output is always a prefix of the full escaped text and never ends inside an escape or a surrogate pair.
- **Unchanged parts:** The escape forms, `CONTROL_RE`, and the default `max` of 80 stay as they are. Output under the cap is unchanged. `shown()` adds no ellipsis. Callers that add their own marker keep it.
- **ratchet-check:** It prints each removed criterion as `  removed: "${shown(l, 200)}"`.
- **em-dash-guard:** It imports `shown` from `./path-rules.mjs` and prints the target as `'${shown(relTarget, 200)}'`. The line-number list holds only numbers the hook makes, so it stays as it is.
- **Cap:** Both new outputs use 200, the cap of the Fast Path notice (0000035 req-001). A criterion line runs longer than a path, and 80 would cut most of them.
- **Install:** `setup.sh` and `setup.ps1` copy every `.mjs` file in `hooks/enforcement/`, so the installed `em-dash-guard.mjs` finds `path-rules.mjs` beside it.

## Alternatives Considered

| Alternative | Pros | Cons | Why Rejected |
|-------------|------|------|-------------|
| Cut the raw text at `max` code points first, then escape | Never splits an escape | Output length is unbounded, since each code point can grow to ten characters. A 200-point cut could print 2,000 characters. | Breaks the cap that keeps block messages short |
| Keep `slice` and trim a trailing partial escape with a regular expression | Small diff | Needs a second rule for lone surrogates. Two fixes for one cut invite a third gap. | A unit loop covers both cases with one rule |
| Strip control and format characters, not escape them | Shorter output | Hides what the input held, so the human on the loop can't see a planted U+202E. Req-011 says nothing is stripped. | Loses evidence of the attack |
| Copy an escape function into `em-dash-guard.mjs` | The hook keeps no import | Two escape rules drift, and 0000032 ADR 004 made `path-rules.mjs` the one home | Shared code is the fix |
| Use the default cap of 80 for both new outputs | One cap everywhere | Cuts most criterion lines, so the block message no longer shows which criterion went | 200 already serves long values in the Fast Path notice |

## Affected Components

| Component | Impact |
|-----------|--------|
| planifest-framework | `shown()` changes its cut. `ratchet-check.mjs` and `em-dash-guard.mjs` print through it, and `em-dash-guard.mjs` gains one import. Every other caller in `gate-write`, `shell-write-guard`, and `path-rules.mjs` gets the new cut with no change. The req-011 suite covers both hooks and the cut. |
| setup-hook-integration | No change. Setup already installs `path-rules.mjs` beside `em-dash-guard.mjs`. |

## Consequences

**Positive:**
- No hook output can carry a raw control character, a bidirectional override, or a broken escape.
- Every enforcement hook escapes through one function, so a later fix lands in all of them.

**Negative:**
- `em-dash-guard.mjs` now fails to load if `path-rules.mjs` is missing or broken. A partial install that copies only `em-dash-guard.mjs` makes Node exit 1 on every call, not 0. Claude Code treats exit 1 as non-blocking, so the guard still does nothing.
- A cut value can be a few characters shorter than before, so suites that assert a cut value need updating with the change (risk R-003).

**Risks:**
- A future escape form longer than `max` would make `shown()` return an empty string for that input. The longest form today is `\u{10FFFF}`, at 10 characters.
- The unit loop is slower than one `slice` on a long value. The req-008 timed case bounds the hook call at 500 ms (NFR-001).

## Related ADRs

- ADR-001 - depends-on. The new import keeps `em-dash-guard.mjs` on Node built-ins with no spawn.
- 0000032 ADR 004 (shared path rules and repository root) - extends. `em-dash-guard.mjs` joins the importers.
- 0000003 ADR 005 (exit zero failure mode) - related-to. A load failure of the new import exits 1, which Claude Code treats as non-blocking.

## Supersedes

- None

## Superseded By

- None
