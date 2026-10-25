---
title: "Backlog Entry: 0000250 - Stale copied-folder docs in tool-setup-reference"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000250 - Stale copied-folder docs in tool-setup-reference

**Source feature:** 0000039-ravintio-rebrand
**Source phase:** P1
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-25

---

## Problem

`ravintio-framework/tool-setup-reference.md` says setup copies supporting files into each skill directory as `_ravintio-*` folders, such as `_ravintio-templates/` and `_ravintio-standards/` (around lines 39 and 73). `setup.sh` never creates these folders. The 0000039 rename changes the folder names in the text, but the text stays wrong.

## Suggested Action

Rewrite that part of `tool-setup-reference.md` to describe what setup copies today. Check `setup.ps1` too.

## Why Deferred

Out of scope. 0000039 renames names and doesn't correct pre-existing doc errors.
