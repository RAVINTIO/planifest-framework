---
title: "Backlog Entry: 0000150 - set-product-release keeps other bytes"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000150 - set-product-release keeps other bytes

**Source feature:** 0000035-write-gate-scope-and-path-hardening
**Source phase:** P5
**Deferral source:** discovered mid-flight
**Date filed:** 2026-10-22

---

## Problem

`planifest-framework/scripts/set-product-release.mjs` reads `product.yml` with `readFileSync(fd, "utf-8")`. Invalid UTF-8 becomes U+FFFD, and the script then writes the whole file back. A line the script should leave alone changes. For example, the bytes `ff fe 00` became `ef bf bd ef bf bd 00`. The script header promises to leave every other line as it is.

A NEL (U+0085) inside a key line also passes and stays in the file. A YAML 1.1 reader treats NEL as a line break.

## Suggested Action

Refuse a `product.yml` that isn't valid UTF-8 with exit 2, or work on bytes and rewrite only the target lines. Treat NEL as a line break in the key-line checks. Add suite cases for both.

## Why Deferred

The P5 final re-review found it. It is Low, and a valid `product.yml` never holds these bytes.
