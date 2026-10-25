---
title: "Backlog Entry: 0000253 - Credential scan key rule matches words ending in sk"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000253 - Credential scan key rule matches words ending in sk

**Source feature:** 0000039-ravintio-rebrand
**Source phase:** P3
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-25

---

## Problem

`ravintio-framework/scripts/credential-scan.mjs` has the rule `api-secret-key` with the pattern `sk-[A-Za-z0-9_-]{20,}`. The pattern has no left boundary, so it matches inside an ordinary hyphenated word such as the vendored skill name for risk requirements analysis. In 0000039 P3 the pass moved that skill's folder. The scan then held back two files whose only hit was the skill's own name. The same match fires on any build-log line that names the path, so the log has to spell the path with brackets.

## Suggested Action

Anchor the rule so a letter can't come before `sk-`, for example `(?<![A-Za-z0-9])sk-[A-Za-z0-9_-]{20,}`. Add a test with a hyphenated word that ends in `sk` and a real-shaped key.

## Why Deferred

Out of scope. 0000039 renames the pack and doesn't change scan rules. The autonomous rules also bar the run from loosening its own guard mid-run.
