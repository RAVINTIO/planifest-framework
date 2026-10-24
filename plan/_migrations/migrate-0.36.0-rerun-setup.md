---
migration: "migrate-0.36.0-rerun-setup.md"
outcome: "applied"
date: "2026-10-24"
framework-version: "0.36.0"
corrections-applied: 1
corrections-skipped: 0
---
Setup re-ran for claude-code with `--strict-orchestrator` and exited 0 with no warning line. The drift check reported all 21 skills matching. The installed orchestrator holds both reference files, and the moved Phase 0 text holds no `../standards/` link. The installed `SKILL.md` is 40,788 bytes. The regenerated `CLAUDE.md` carries the partial-read directive.
