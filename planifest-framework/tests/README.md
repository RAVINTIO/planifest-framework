# Planifest Tests

This directory contains integration tests for the confirmed design framework setup scripts (`setup.sh` and `setup.ps1`).

These tests verify that running the setup process for an AI coding agent (like Claude Code or Cursor) correctly generates the expected folders, copies the skill files, and creates necessary configuration (like boot files or rules).

## Running the Tests

To run the tests, execute the scripts from the root of the repository or from within this directory. The scripts will create an isolated, temporary workspace, run the setup process inside it, and clean up afterward.

### PowerShell (Windows)

```powershell
# From the repository root
& .\planifest-framework\tests\test_setup.ps1
```

### Bash (macOS / Linux / WSL)

```bash
# From the repository root
./planifest-framework/tests/test_setup.sh
```

## How It Works

1. **Isolation**: The test script automatically generates a temporary directory (e.g., `planifest_test_XXXXXX`).
2. **Context Creation**: The entire `planifest-framework` source is copied into the temporary directory to simulate a real project environment.
3. **Execution**: The respective setup script (`setup.sh` or `setup.ps1`) is called for various target tools (e.g., `claude-code`, `cursor`).
4. **Validation**: The test script checks if the expected tool-specific files and folders are created:
   - Tool-specific skill folders (e.g., `.claude/skills` or `.cursor/skills`).
   - Copied `SKILL.md` files (e.g., `planifest-orchestrator/SKILL.md`).
   - Boot files for tools that require them (e.g., `CLAUDE.md`).
   - Workflows/Commands for tools that support them (e.g., `/feature-pipeline`).
5. **Cleanup**: Even if a test fails, `finally` blocks ensure the temporary folder is deleted, leaving your actual workspace unaffected.

## Adding New Tests

If you add a new setup target (e.g., a new AI coding tool) to `setup.sh`/`setup.ps1`, you should verify it by adding a section to both `test_setup.sh` and `test_setup.ps1`. 

A basic template for a new test block:

```powershell
Write-Host "--- Testing: [tool-name] ---"
& .\planifest-framework\setup.ps1 [tool-name]

if (-not (Test-Path ".[tool-dir]\skills")) {
    throw "FAIL: .[tool-dir]\skills directory not created"
}
```

## Windows skip table

A suite that cannot run under Git Bash on `windows-latest` returns exit 0 early on Windows only. It prints `SKIP (windows): {reason}` first. Each guard tests the platform (`uname -s` reports `MINGW*`, `MSYS*`, or `CYGWIN*`). Each guard has one row here, and each row has one guard.

| Suite | Reason | Date |
|-------|--------|------|
| `test-0000030-req-004-install-clean-up-and-retired-flags.sh` | Three checks only: the linked-parent refusal (`ln -s` copies under Git Bash), the undeletable-folder warning (`chmod 555` does not block deletes on NTFS), and the 0600 mode check (NTFS has no mode bits). The other checks run. Backlog 0000210 and 0000211. | 2026-10-24 |
| `test-0000033-req-001-run-mode-script.sh` | The three symlinked-record checks only: `ln -s` makes a copy under Git Bash. The other checks run. Backlog 0000210. | 2026-10-24 |
| `test-0000033-req-012-archive-script-without-glob-delete.sh` | The symlink cases (`ln -s` makes a copy under Git Bash) and the forced-stop resume case (Node does not find an extensionless `git` shim on Windows). The other checks run. Backlog 0000210 and 0000211. | 2026-10-24 |
| `test-0000033-req-017-join-owner-and-reconciliation.sh` | The symlinked changed-file check only: `ln -s` makes a copy under Git Bash. The regression copy has the same guard. The other checks run. Backlog 0000210. | 2026-10-24 |
| `test-0000036-req-002-skill-drift-check.sh` | The newline-in-a-name check only: NTFS rejects a newline in a folder name. The other checks run. Backlog 0000211. | 2026-10-24 |
| `test-0000025-req-004-setup-config-relocation.sh` | Check (e) only: `chmod 555` does not block writes on NTFS, so the unwritable-folder case cannot be built. The other checks in the suite run. | 2026-10-24 |
| `test-0000037-req-003-credential-scan.sh` | The gitleaks stand-in checks only: the stand-in is a shell script, and node starts only a `gitleaks.exe` without a shell. The other checks run on the runner `PATH`. Backlog 0000212. | 2026-10-24 |
| `test-0000037-req-007-wired-command.sh` | The bare-path negative check only: Git Bash runs a bare `.mjs` path through its node shebang, so the missing node prefix does not fail. The other checks run. Backlog 0000212. | 2026-10-24 |
| `test-0000035-req-004-root-when-cwd-deleted.sh` | Two groups only: the checks that delete a process's cwd (Windows cannot) and the EACCES block (`chmod 000` sets no NTFS block). The other checks run. Backlog 0000208. | 2026-10-24 |
| `test-0000035-req-005-ratchet-check-shared-root.sh` | Three groups only: the 10-link chain and link loop (`ln -s` copies under Git Bash), and the forged-name and forged-approval checks (a Windows file name cannot hold a newline or a colon). The other checks run. Backlog 0000208. | 2026-10-24 |
| `test-0000035-req-008-sanctioned-scripts.sh` | The link checks only (`ln -s` copies under Git Bash), the kept-mode check, and the unwritable-root and unreadable-file checks (NTFS has no POSIX mode bits). The regression copy has the same guards. The other checks run. Backlog 0000208. | 2026-10-24 |
| `test-0000036-req-008-non-regular-design-md.sh` | The FIFO case (Git Bash `mkfifo` makes no file that Node reports as non-regular) and the swap-to-link case (Windows has no `O_NOFOLLOW`, an enforcement gap). The other checks run. Backlog 0000208 and 0000209. | 2026-10-24 |

