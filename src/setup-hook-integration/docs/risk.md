# Risk — setup-hook-integration

Derived from `plan/_archive/0000030-context-mode-and-telemetry-mcp-removal-2026-10-14/risk-register.md` — component-scoped items only.

| ID | Risk | Severity | Mitigation | Status |
|---|---|---|---|---|
| R-008 | Hook scripts execute Node.js with filesystem access — a corrupted hook in `.claude/settings.json` could run attacker code | Low likelihood / High impact | Hooks are framework-shipped; setup writes only framework-relative paths; hooks dir is version-controlled | Open |
| TD-001 | Path traversal via malicious skill name in `rm -rf` | Medium | Add `validate_skill_name()` — see tech-debt.md | Open (TD-001) |
| TD-002 | JS injection via `$name` in `node -e` | Medium | Use env-var pattern — see tech-debt.md | Open (TD-002) |
| TD-003 | `--from` URL accepts non-HTTPS schemes | Low-Medium | Validate `https://` prefix — see tech-debt.md | Open (TD-003) |
| TD-006 | `setup.ps1` missing skill subcommand routing | Low | Add equivalent to setup.ps1 | Open (TD-006) |
| R-010 | `setup.sh`/`setup.ps1` marker-write addition (0000020) could drift out of parity between the two scripts | Medium likelihood / Low impact | Parity acceptance criteria (REQ-008) and a live test suite for the bash side; PowerShell side runs live in the Windows CI job since 0000031, see quirks.md Q-006 | Mitigated |
| R-011 | `.ravintio-setup-flags` written outside a gitignored directory for `copilot`/`opencode`, risking accidental commit (0000020 P5 security finding) | Was Medium, now mitigated | Global `.ravintio-setup-flags` gitignore pattern added and verified live for all affected tools | Mitigated |
| R-003 | Clean-up over-reach removes a file a person stored in a stale hook folder (0000030) | Low | Entries match by command path, setup prints each removal, and the folder deletion is accepted as F6 (Q-012, backlog 0000090) | Partly mitigated |
| R-004 | PowerShell drift with no live run (0000030) | Low likelihood / Low impact | Since 0000031, the Windows CI job runs `test_setup.ps1` under PowerShell 7 on every pull request. Since 0000037, a second job runs the same test under Windows PowerShell 5.1, and a live section seeds a stale install and passes a retired flag, see Q-013. The `-LiteralPath` and reparse-point paths stay checked by source text only. | Mitigated |
| R-012 | Replay of a retired flag from an old marker (0000030) | Low | Notice only, never recorded, value never echoed or stored (0000030-ADR-003) | Mitigated |
| R-013 | Settings file corrupted by a crash or a malformed parse (0000030) | Low | Malformed files stay byte-identical. Writes use an exclusive temporary file and a rename, including `opencode.json` (F1) | Mitigated |
| R-014 | Node missing during clean-up (0000030) | Low | The pass skips with a warning and setup exits 0 | Mitigated |
