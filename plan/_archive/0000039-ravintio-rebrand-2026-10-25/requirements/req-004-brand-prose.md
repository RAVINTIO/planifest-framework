---
title: "Requirement: req-004 - brand-prose"
summary: "Reader-facing prose and repo links say RAVINTIO Framework, with RAVINTIO always in block capitals."
status: "draft"
version: "0.1.0"
---
# Requirement: req-004 - brand-prose

**Skill:** [spec-agent](../skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000039-ravintio-rebrand
**Source:** US-001
**Priority:** must-have

## User Story

As a human on the loop, I read "RAVINTIO Framework" in every doc, skill, template, and message, so that the product name is consistent after the rename.

## Functional Requirements
- Replace the brand in prose in these places:
  - `README.md` and `docs/`.
  - Skills, standards, and templates.
  - `pipeline-reference.md` and `tool-setup-reference.md`.
  - Live backlog entries. The `_reference/` documents stay as written.
  - The prose of hook messages and setup messages.
- Apply these replacements in order:
  - "Planifest Framework" becomes "RAVINTIO Framework".
  - A bare "Planifest" becomes "RAVINTIO Framework" on its first use in a file or a message. Later uses in the same file or message become "RAVINTIO". Log prefixes and headings that name only the brand also use "RAVINTIO".
- Write RAVINTIO in block capitals in prose. Identifiers keep lowercase `ravintio`, per req-001.
- Move repo links to `github.com/RAVINTIO/ravintio-framework`. Find the current forms with `git grep -n 'github.com/planifest'`.
- Leave the `planifest-docs` sibling links as they are. The brand guard allowlists them.
- Leave history, vendored upstream text, and `_reference/` documents untouched, per req-005.
- Handle mojibake in the `setup.sh` heredoc, around lines 788 to 957, with the safer rule below.
  - The heredoc holds corrupted copies of an old dash, such as `Ã¢â‚¬â€`.
  - RAVINTIO Zero 0000160 req-004 kept the same kind of sequence in `setup.ps1` byte-identical and allowed only the brand token to change.
  - Adopt that rule. On a mojibake line, change only the brand word, and leave every other byte as it is.
  - Make each change with a byte-exact tool, never an editor that re-encodes the file.
  - If a line cannot change without touching those bytes, leave the whole line unchanged and add a brand-guard allowlist entry for it.
- Path tokens inside those lines, such as `planifest-framework/`, belong to req-001. This requirement covers the brand word only.
- Split step, in two answers. At drafting the answer was keep: prose and links come from the same replace rules and the same guard check. At the fourth criterion the answer was split: the version bump is its own outcome, so req-010 takes it.
- The version clause and the version criterion moved to req-010 once the P1 critic loop closed.
- The heredoc range in req-005 governs. It runs from line 811 to 958 and writes `plan/feature-structure.md`. Line 1322 also holds a banner bar. Lines 788 and 957 hold stale links, which backlog 0000251 tracks.

## Acceptance Criteria
- [ ] After the pass, no brand-word "Planifest" remains in prose outside history, `_reference/` documents, vendored text, and the allowlist. The brand guard from req-007 passes. Verified by: integration
- [ ] `git grep -n 'github.com/planifest'` lists only `planifest-docs` links and allowlisted history. Every repo link points to `github.com/RAVINTIO/ravintio-framework`. Verified by: integration
- [ ] A diff of the `setup.sh` heredoc, lines 811 to 958, plus line 1322, changes only brand words, and every mojibake byte matches the previous commit. Verified by: execution

## Dependencies
- req-001 (pack-paths-and-identifiers) provides the renamed paths that links and layout text refer to.
- req-005 (history-and-split-name-protection) defines the protected list that this pass skips.
- req-007 (brand-guard) is the check that proves this requirement.
