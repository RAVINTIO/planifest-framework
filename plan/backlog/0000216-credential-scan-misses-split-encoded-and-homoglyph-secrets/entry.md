---
title: "Backlog Entry: 0000216 - credential scan misses split, encoded, and homoglyph secrets"
summary: "credential-scan.mjs matches plain ASCII patterns only, so a split, base64, or look-alike-character secret passes when gitleaks is absent."
status: "open"
---
# Backlog Entry: 0000216 - credential scan misses split, encoded, and homoglyph secrets

**Source feature:** 0000037-green-ci-before-ship
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-24

---

## Problem

`ravintio-framework/scripts/credential-scan.mjs` applies regular expressions to decoded text. Three inputs pass in regex-only mode. A key split across two lines or string pieces. A key held in base64 or another encoding. A key whose prefix uses a homoglyph character. The P5 fix for F-01 closed NUL-byte and UTF-16 bypasses only. The credentials review (F-11) lists these three as not detected.

## Suggested Action

Document the three cases as out of scope in the req-003 spec, and state that only `gitleaks` narrows them. Optionally add a normalisation pass (Unicode NFKC, line joining) for the highest-risk rules.

## Why Deferred

A regex scan cannot close these cases. Narrowing them needs a design decision on false-positive cost, which is outside feature 0000037.
