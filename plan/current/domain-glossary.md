---
title: "Domain Glossary - Context Mode and Telemetry MCP removal"
summary: "Definitions of domain terms used within this feature."
status: "active"
version: "0.1.0"
---
# Domain Glossary - Context Mode and Telemetry MCP removal

**Skill:** [spec-agent](../skills/spec-agent-SKILL.md) (updated by any agent that introduces a new domain term)
**Feature:** 0000030-context-mode-and-telemetry-mcp-removal
**Version:** 0.29.0

> The ubiquitous language for this feature. If the glossary says "Order", the code says `Order` - not "Purchase" or "Transaction". Never invent new terms without adding them here.

## Terms

| Term | Definition | Aliases | Used In |
|------|-----------|---------|---------|
| Context Mode | The optional MCP integration whose three hooks (`block-bash.mjs`, `block-grep.mjs`, `block-webfetch.mjs`) route tool calls. Removed by this feature. | context-mode, Context Mode MCP | context-mode-hooks, planifest-framework |
| Telemetry | The optional MCP integration that emits phase events through hooks. Removed by this feature. | Telemetry MCP, structured-telemetry-mcp | planifest-framework, setup-hook-integration |
| Retired flag | A setup flag that no longer installs anything. Setup accepts it as a no-op, prints a one-line notice, exits 0, and never writes it to the install marker. The retired flags are `--context-mode-mcp`, `--structured-telemetry-mcp`, and `--backend-url`. | removed flag | setup-hook-integration |
| Clean-up | The always-on setup step that removes stale Context Mode and Telemetry settings entries, hook folders, and sentinel files. It matches on command path and lists each removal. | install clean-up | setup-hook-integration |
| Install marker | The flags-used marker file that setup writes so `planifest-refresh-setup` can rebuild the flags in effect. | flags-used marker | setup-hook-integration, planifest-refresh-setup |
| Sentinel | A marker file whose presence signals state. Here: `.claude/telemetry-enabled`. The clean-up removes it. | marker file | setup-hook-integration |
| Failure marker | A file under `plan/.telemetry-failures/` recording a failed emission. The clean-up removes the folder. | telemetry failure marker | setup-hook-integration |
| Receipt | A file under `plan/.telemetry-receipts/` recording an emitted event, used by the receipts backstop. The clean-up removes the folder. | telemetry receipt | setup-hook-integration |
| Backstop | An enforcement hook that checks work the agent should have done. Removed here: `check-telemetry-failures.mjs` and `check-telemetry-receipts.mjs`. | enforcement backstop | planifest-framework |
| Hook event | A tool lifecycle point that triggers hooks, such as PreToolUse or UserPromptSubmit. The clean-up checks entries under every one. | | setup-hook-integration |
| Hook entry | One command registration for a hook event in a tool's settings file. | settings entry | setup-hook-integration |
| Hand-added hook | A hook entry a person wrote whose command path does not point at a removed Planifest hook. The clean-up keeps it. | | setup-hook-integration |
| Tier 1 adapter | A tool-specific installer for a non-Claude tool: `cursor.mjs`, `cline.mjs`, and `opencode/index.ts`. Cursor, Windsurf, and Cline installs are in scope. | | setup-hook-integration |
| Path-matched | Matching a hook entry by the exact command path of a removed Planifest hook, not by name or substring. | | setup-hook-integration |
| Migration file | A file under `planifest-framework/migrations/` that `planifest-migrator` runs in downstream installs. This one is downstream-only and committed last. | | planifest-framework |
| Product ID | The `id` field in `product.yml`. The P0 hard-stop stays, and its rationale is now versioning and archive attribution. | declared product ID | planifest-framework |
| Retired-flag notice | The one-line message setup prints when it receives a retired flag. | removal notice | setup-hook-integration |
| Allowlist | The exact set of paths where the removed names may still appear, defined in the residual-reference NFR. | | planifest-framework |
| Self-hosting | This repo wiring its own hooks into its own `.claude/settings.json`. Removed in req-005's final step. | | planifest-framework |

## Unnamed concepts

- The final step in req-005 that removes this repo's own wiring has no established name in the repo. This glossary calls it "final step" and does not coin a term for it.
- The set of removed Planifest hook paths that the clean-up matches has no established name in the repo. The design says "removed Planifest hook" and this glossary keeps that wording.
