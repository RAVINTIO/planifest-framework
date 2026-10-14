# Security Report - 0000030-context-mode-and-telemetry-mcp-removal

A fresh-context reviewer examined the new retired-flag handling and setup clean-up in `setup.sh`, `setup.ps1`, `setup/opencode.*`, and the Tier 1 adapters. It found no Critical or High issues. Five of six findings are fixed on the branch, each with a test, and one is accepted with a backlog entry. The overall risk after fixes is **Low**.

## Threat Model (STRIDE)

| Threat | Category | Severity | Mitigation |
|---|---|---|---|
| F1: a malformed `opencode.json`, or a missing `jq`, truncated the file to one byte in `setup/opencode.sh`. The 0000030 path fix made this hit the real project file. | Tampering / DoS | Medium | Fixed in `d38a183`. Node parses first, a bad file stays byte-identical with a warning, and writes go through a temporary file and rename. |
| F2: `Remove-Item -Path -Recurse` in the `setup.ps1` clean-up follows directory links on Windows PowerShell 5.1, and treats `[` `]` in the project path as wildcards. | Tampering | Medium | Fixed in `0ee9cee`. The clean-up uses `-LiteralPath`, removes a reparse point with `.Delete()`, and finds dangling links with `Get-Item -Force`. |
| F3: `rm -rf` in the `setup.sh` clean-up followed a linked parent folder such as `plan` out of the project. | Tampering | Low | Fixed in `7b31fbb`. The parent is resolved with `cd -P`, and setup refuses a path outside the physical project root. `setup.ps1` refuses any reparse point between the path and the root. |
| F4: a failed delete or rename aborted the whole install under `set -e` or `ErrorActionPreference = Stop`, against ADR-004. | DoS | Low | Fixed in `6ab403a`. Each failure warns and setup carries on. A failed rename removes the temporary file and leaves the original untouched. |
| F5: settings temporary files used the default umask, a predictable name, and a write that follows a planted link. | Information Disclosure / Tampering | Low | Fixed in `00ddc06`. The name is random, the file is created exclusively (`wx`, `CreateNew`), and it copies the target's mode. |
| F6: the clean-up deletes the whole stale hook folder, including any file a person put there. It also removes the `emit_event` matcher group by matcher alone. | Tampering | Low | Accepted. The folders are Planifest install locations, and setup prints every removal. ADR-004 records the deviation, and backlog 0000090 holds the narrower design. |
| A setup run replays a retired flag from an old marker. | Tampering | Low | Mitigated (ADR-003). The flag prints a notice and is never written back. The `--backend-url` value is never echoed, stored, or run. |

## Dependency Audit

No dependency was added. The change removes code. `opencode.sh` no longer needs `jq`, because Node does the JSON work through the shared helpers. No action needed.

## Secrets Management

No secret is introduced. Removing telemetry deletes the only place setup wrote a URL into settings (`PLANIFEST_TELEMETRY_URL`). The reviewer confirmed that no URL or token is written to settings, markers, or logs. This repo's own `planifest-overrides/setup-config/claude-code.md` no longer stores `backendUrl`. The F5 fix keeps a `0600` settings file at `0600`, so `env` values in Claude settings stay private.

## Authentication & Authorisation Review

Not applicable. The feature has no API and no auth surface.

## Input Validation Review

Not applicable as an API. The untrusted inputs are existing settings files and project paths:
- Settings files are parsed as JSON. A parse failure leaves the file byte-identical, as REQ-004 requires.
- Paths and values reach the inline Node scripts through `PLANIFEST_*` environment variables, never by string interpolation. The reviewer found no shell or JavaScript injection.
- Entries are compared by path, never executed.

## Network Policy

Egress shrinks. The telemetry hooks posted to a local MCP server, and the CI job posted to `PLANIFEST_TELEMETRY_URL`. Both are gone. The reviewer confirmed that no network call remains in the changed adapters. No ingress exists.

## Infrastructure as Code Review

Not applicable. The stack declares no IaC. The only CI change removes the `validate-telemetry-schema` job, which read a secret and called an external URL.

## Risk Register Cross-Reference

| Risk | Status |
|---|---|
| R-001 self-hosting order | Mitigated. Entries went first, then files, and the req-005 test checks this repo's settings |
| R-003 clean-up over-reach | Partly mitigated. Hand-added hooks outside the stale folders stay. Files inside them are F6 (accepted) |
| R-004 and R-008 PowerShell drift with no `pwsh` | Open. Static checks only. Backlog 0000091 adds a CI PowerShell job |
| R-012 retired-flag replay | Mitigated |
| R-013 corrupt settings on a crash | Mitigated for `settings.json` and, after F1, `opencode.json` |
| R-014 Node missing | Mitigated. Setup warns and exits 0 |

## Summary

Overall risk rating: **Low** (after fixes). Before the fixes it was Medium, because of F1 and F2.

Top actions before production:
1. Run `setup.ps1` under Windows PowerShell 5.1 and PowerShell 7 against a fixture with both integrations installed. Nothing has exercised the F2 and F5 PowerShell code live (backlog 0000091).
2. Decide on the narrower clean-up in backlog 0000090 before a downstream project keeps its own files in `hooks/telemetry/`.
3. Track the boot-file write that follows links (backlog 0000074). That issue predates this feature, and this feature leaves it unchanged.
