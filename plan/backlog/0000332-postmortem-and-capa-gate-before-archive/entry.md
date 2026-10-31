---
title: "Backlog Entry: 0000332 - a postmortem and CAPA gate before archive"
summary: "A read-only check at P7 refuses to archive a run whose stops and failures lack a postmortem, or whose corrective CAPAs are still open."
status: "open"
---
# Backlog Entry: 0000332 - a postmortem and CAPA gate before archive

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31
**Suggested route:** Feature Pipeline. Ship it with 0000330 and 0000331.
**Related:** 0000085, 0000312

---

## Problem

RAVINTIO Zero enforces its postmortem rule in text only. Zero retrospective `0000238-backlog-clearance-two-initiative-2026-10-29.md` records stops at steps 4 and 6. It also says "`plan/postmortems/` doesn't exist. The stops at steps 4 and 6 have no postmortem." Those postmortems arrived two days later.

Zero's lessons repeat the same way. One lesson recurred six times. Entry 0000264 appears in nine retrospectives, and each one restates it as prose. A rule that lives only in text gets skipped under pressure.

If Framework adopts 0000330 and 0000331 without a gate, the same gap will open.

## Suggested Action

Add a read-only script, `ravintio-framework/scripts/postmortem-check.mjs`, and run it at P7 before the archive step. It refuses to archive when any of these lacks a linked postmortem:

- a `Blocked:` and `Resolved:` pair in the build log
- a granted defect report
- a failed CI run
- an avoidable P4 self-correction, one a P3 test should have caught

It also refuses when a corrective CAPA raised in this run is still `open`. A CAPA in `implemented` or `effectiveness-pending` passes, because its check falls after the run.

P8's build report lists each postmortem and the status of each CAPA.

Add a rule to the postmortem skill: if a lesson appears in two records, it must become a check, not text. The action for that lesson is a test, a hook, or a script, never a new sentence in a skill.

## Wanted outcome

- `postmortem-check.mjs` exits non-zero for each missing-postmortem case and each open corrective CAPA.
- It exits zero for a clean run, and it writes no file.
- P7 stops on a non-zero exit and names each gap.
- The P8 build report lists every postmortem and CAPA status for the run.
- A test seeds each case and checks the exit code.

## Open questions

- Can a 0000287 waiver let P7 archive with a missing postmortem, and who signs it?
- How does the script tell an avoidable P4 self-correction from an expected one?

## Why Deferred

The human asked for it during the Zero comparison review. It can't work before 0000330 and 0000331 define the records it checks.
