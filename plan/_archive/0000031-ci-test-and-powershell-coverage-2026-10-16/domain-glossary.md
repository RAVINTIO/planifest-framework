---
title: "Domain Glossary - CI test and PowerShell coverage"
summary: "Definitions of domain terms used within this feature."
status: "active"
version: "0.1.0"
---
# Domain Glossary - CI test and PowerShell coverage

**Skill:** [spec-agent](../../planifest-framework/skills/planifest-spec-agent/SKILL.md)
**Feature:** 0000031-ci-test-and-powershell-coverage
**Version:** 0.30.0

## Terms

| Term | Definition | Aliases | Used In |
|------|-----------|---------|---------|
| Suite | One `test-*.sh` file under `planifest-framework/tests/` or its `regression/` folder. `run-tests.sh` runs every suite it finds. | test suite | planifest-framework |
| Feature suite | A suite directly under `planifest-framework/tests/`. | none | planifest-framework |
| Regression suite | A suite under `planifest-framework/tests/regression/`. | regression pack | planifest-framework |
| Suite job | The CI job that runs `run-tests.sh` as a matrix over Linux and macOS. | none | repository CI |
| Windows job | The CI job that runs `test_setup.ps1` under PowerShell 7 on `windows-latest`. | PowerShell job | repository CI |
| Setup-flags marker | The `.planifest-setup-flags` JSON file that setup writes in each tool folder. It records the tool, the flags passed, `writtenAt`, and `attemptStatus`. | marker | planifest-framework |
| Consumer workflow copy | `planifest-framework/hooks/planifest.yml`, the workflow that setup installs in downstream repos. | none | planifest-framework |
| Human on the loop | The person who reviews and merges pull requests and confirms gates. | none | all |
