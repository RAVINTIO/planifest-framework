---
title: "Backlog Entry: 0000354 - CAPA and defect source links in templates"
summary: "Add an optional Source record field so a backlog entry, Story, or defect report can name the CAPA or Bug key it came from."
status: "open"
---
# Backlog Entry: 0000354 - CAPA and defect source links in templates

**Source feature:** none (Zero comparison review)
**Source phase:** none (P0 triage)
**Deferral source:** human request
**Date filed:** 2026-10-31

**Suggested route:** Fast Path or Change Pipeline
**Related:** 0000295, 0000331

---

## Problem

A regulated team often starts work from a corrective and preventive action (CAPA) or a Bug in its tracker. An auditor then expects to follow the CAPA to the change that closed it. Framework's backlog entry and defect report templates have no field for that source. The link lives only in prose, if anyone writes it.

## Suggested Action

- Add an optional `**Source record:**` field to these templates:
  - `ravintio-framework/templates/backlog-entry.template.md`
  - `ravintio-framework/templates/defect-report.template.md`
- The field holds a CAPA or Bug key, such as a Jira issue key.
- With `--jira-planning` (0000295), carry the key onto the Story as a link.
- Leave the field blank when no source record exists.

## Wanted outcome

A backlog entry, Story, or defect report can name its source CAPA or Bug key. A test proves that both templates hold the optional field.

## Why Deferred

Filed from the Zero comparison review on 2026-10-31. It is small, but it touches shared templates and pairs with 0000295.
