---
title: "Backlog Entry: 0000111 - confirm the Windows shell tool name for the shell guard"
summary: "A discovered-but-out-of-scope item deferred for pickup at a future P0."
status: "open"
---
# Backlog Entry: 0000111 - confirm the Windows shell tool name for the shell guard

**Source feature:** 0000032-governance-continuity-and-write-gate-scope
**Source phase:** P5
**Deferral source:** deliberate scope decision
**Source finding:** S-3 in the 0000032 P5 security report (`plan/_archive/0000032-governance-continuity-and-write-gate-scope/security-report.md` once archived)
**Severity:** Low
**Priority:** Low
**Date filed:** 2026-10-17

---

## Problem

Setup registers the shell-write guard under the `Bash` matcher only. If Claude Code on Windows runs shell commands through a tool with another name, such as a PowerShell tool, those writes skip the guard.

## Suggested Action

Confirm the shell tool name Claude Code uses on Windows. If it differs from `Bash`, register the guard under that name too, and teach the guard the PowerShell writer forms.

## Why Deferred

At the P5 gate, the human on the loop chose to fix the Medium findings and the cheap Low ones in 0000032. This Low finding went to the backlog. The decision is in the 0000032 build log.
