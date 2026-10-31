---
title: "Backlog Entry: 0000328 - writing standard and prose checks at filing"
summary: "Align the formatting standard with the owner's style variant, add a prose linter with a ratchet and a P6 edit pass, and run wording tests when someone files a backlog entry."
status: "open"
---
# Backlog Entry: 0000328 - writing standard and prose checks at filing

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31

**Suggested route:** Feature Pipeline
**Related:** 0000065

---

## Problem

Framework's writing rules conflict with the owner's style variant, and nothing checks prose when someone files a backlog entry.

`ravintio-framework/standards/formatting-standards.md` conflicts with the variant in two places:

- Line 11 requires `DD MMM YYYY` dates and lists `2026-05-02` as incorrect. The variant uses ISO dates, and backlog headers already do.
- Line 78 offers the semicolon as a replacement for the em dash. The variant bans semicolons.

Prose checks run late. A RAVINTIO Zero postmortem, `2026-10-31-step-4-content-test-failed-on-coordinator-entry.md`, records the cost. A coordinator committed a backlog entry with a blocked word. No test ran on that commit. The next feature's Zero P2 Implement ran the full suite and stopped on the entry. The step waited about five hours for the human.

Controlled documents need a consistent style that a tool can check.

RAVINTIO Zero backlogs 0000300 to 0000303 plan a writing standard, a prose linter with a ratchet, and a docs edit pass.

## Suggested Action

- Align `formatting-standards.md` with the owner's variant. Use ISO dates and drop the semicolon from the em dash advice.
- Add a prose linter for the banned words and marks. Give it a ratchet, so the count of known breaches can only fall.
- Add an edit pass on new and changed docs at P6 Documentation.
- Run the wording tests on each new or changed entry before its commit. A `pre-commit` hook check on `plan/backlog/` would do it.

## Wanted outcome

- `formatting-standards.md` names ISO dates and never offers the semicolon.
- A backlog entry with a banned word fails at commit, not in a later run.
- The linter's breach count never rises between releases.

## Why Deferred

The human asked for it on 2026-10-31 after the Zero comparison review. It changes a standard that many skills bundle, so it needs its own design.
