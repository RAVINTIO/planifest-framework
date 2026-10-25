# Agentic Tool Setup Reference

> How each supported coding tool discovers skills, and what the setup script creates for each.

---

## Agent Skills Specification

RAVINTIO Framework fully supports the [Agent Skills specification](https://agentskills.io/specification). Each skill is deployed as a directory whose name matches the `name` field in YAML frontmatter - the requirement the spec mandates. The framework is designed for tools that implement the Agent Skills standard: skills are discoverable, frontmatter-driven, and portable across any compliant tool.

---

## Scripts

Two setup scripts are provided - use whichever matches your OS:

| OS | Script | Interpreter |
|----|--------|-------------|
| macOS / Linux | `setup.sh` | Bash (pre-installed) |
| Windows | `setup.ps1` | PowerShell (pre-installed) |

**Zero dependencies.** Both scripts use only built-in OS capabilities - no Node.js, Python, or anything else required.

### Optional Flags

| Flag | Purpose |
|------|---------|
| `--strict-orchestrator` | Makes the orchestrator sentinel strict: writes to `plan/current/` need an active orchestrator run. |
| `--include-full-skill-library` | Installs the full third-party skill library alongside the RAVINTIO skills. |

---

## What the Script Does

For each tool, the script:

1. **Creates the tool's skill directory** (e.g., `.claude/skills/`)
2. **Copies each skill** as `{skill-name}/SKILL.md` with the required YAML frontmatter (`name` + `description`)
3. **Copies supporting files** (templates, standards, schemas) into the skill directory as `_ravintio-*` folders
4. **Copies workflows** (feature-pipeline, change-pipeline, retrofit) into the tool's workflow directory
5. **Creates a boot file** (e.g., `CLAUDE.md`) if one doesn't already exist
6. **Copies capability skills** from `ravintio-overrides/capability-skills/` directly into the tool's skill directory — no separate registry file needed; the tool discovers them the same way it discovers built-in skills
7. **Appends override instructions** from `ravintio-overrides/instructions/*.md` to the boot file — idempotent, replaces the previous block on re-run

---

## Tool Reference

### Claude Code (Anthropic)

| Item | Detail |
|------|--------|
| **Skill discovery** | `.claude/skills/{name}/SKILL.md` |
| **Workflow discovery** | `.claude/commands/{name}.md` (becomes `/name` slash command) |
| **Boot file** | `CLAUDE.md` (project root) |
| **Personal skills** | `~/.claude/skills/` |
| **Frontmatter** | `name` + `description` required |
| **Progressive disclosure** | Yes - reads frontmatter first, loads body on demand |
| **Setup command** | `./ravintio-framework/setup.sh claude-code` or `.\ravintio-framework\setup.ps1 claude-code` |

**Creates:**
```
.claude/
├── skills/
│   ├── ravintio-orchestrator/SKILL.md
│   ├── ravintio-spec-agent/SKILL.md
│   ├── ravintio-adr-agent/SKILL.md
│   ├── ravintio-codegen-agent/SKILL.md
│   ├── ravintio-validate-agent/SKILL.md
│   ├── ravintio-security-agent/SKILL.md
│   ├── ravintio-change-agent/SKILL.md
│   ├── ravintio-docs-agent/SKILL.md
│   ├── _ravintio-templates/
│   ├── _ravintio-standards/
│   ├── _ravintio-schemas/
└── commands/
    ├── feature-pipeline.md
    ├── change-pipeline.md
    └── retrofit.md
CLAUDE.md
```

---

### Cursor

| Item | Detail |
|------|--------|
| **Skill discovery** | `.cursor/skills/{name}/SKILL.md` |
| **Workflow discovery** | Embedded in `.cursor/rules/*.mdc` (no dedicated workflow dir) |
| **Rules** | `.cursor/rules/*.mdc` |
| **Compat paths** | Also scans `.claude/skills/`, `.codex/skills/` |
| **Personal skills** | `~/.cursor/skills/` |
| **Frontmatter** | `name` + `description` required |
| **Progressive disclosure** | Yes |
| **Setup command** | `./ravintio-framework/setup.sh cursor` or `.\ravintio-framework\setup.ps1 cursor` |

**Creates:**
```
.cursor/
├── skills/
│   ├── ravintio-orchestrator/SKILL.md
│   ├── ravintio-spec-agent/SKILL.md
│   ├── ... (all 8 skills)
│   ├── _ravintio-templates/
│   ├── _ravintio-standards/
│   └── _ravintio-schemas/
└── rules/
    └── ravintio.mdc
```

---

### Codex (OpenAI)

| Item | Detail |
|------|--------|
| **Skill discovery** | `.agents/skills/{name}/SKILL.md` (walks up to repo root) |
| **Workflow discovery** | `.agents/workflows/{name}.md` |
| **Boot file** | `AGENTS.md` (project root) |
| **Compat paths** | Also scans `.claude/skills/`, `.github/skills/` |
| **Personal skills** | `~/.codex/skills/` or `$CODEX_HOME/skills/` |
| **Frontmatter** | `name` + `description` required |
| **Progressive disclosure** | Yes |
| **Setup command** | `./ravintio-framework/setup.sh codex` or `.\ravintio-framework\setup.ps1 codex` |

**Creates:**
```
.agents/
├── skills/
│   ├── ravintio-orchestrator/SKILL.md
│   ├── ravintio-spec-agent/SKILL.md
│   ├── ... (all 8 skills)
│   ├── _ravintio-templates/
│   ├── _ravintio-standards/
│   └── _ravintio-schemas/
└── workflows/
    ├── feature-pipeline.md
    ├── change-pipeline.md
    └── retrofit.md
AGENTS.md
```

---

### Antigravity (Google)

| Item | Detail |
|------|--------|
| **Skill discovery** | `.gemini/skills/{name}/SKILL.md` or `.agent/skills/{name}/SKILL.md` |
| **Workflow discovery** | `.agent/workflows/{name}.md` (becomes `/name` slash command) |
| **Boot file** | `GEMINI.md` (project root) |
| **Personal skills** | `~/.gemini/antigravity/skills/` |
| **Frontmatter** | `name` + `description` required |
| **Progressive disclosure** | Yes |
| **Link command** | `gemini skills link ./ravintio-framework/skills/<name>` |
| **Setup command** | `./ravintio-framework/setup.sh antigravity` or `.\ravintio-framework\setup.ps1 antigravity` |

**Creates:**
```
.gemini/
└── skills/
    ├── ravintio-orchestrator/SKILL.md
    ├── ravintio-spec-agent/SKILL.md
    ├── ... (all 8 skills)
    ├── _ravintio-templates/
    ├── _ravintio-standards/
    └── _ravintio-schemas/
.agent/
└── workflows/
    ├── feature-pipeline.md
    ├── change-pipeline.md
    └── retrofit.md
GEMINI.md
```

---

### GitHub Copilot

| Item | Detail |
|------|--------|
| **Skill discovery** | `.github/skills/{name}/SKILL.md` |
| **Workflow discovery** | `.github/copilot-workflows/{name}.md` (natural language workflows - avoids GitHub Actions conflict) |
| **Boot file** | `.github/copilot-instructions.md` |
| **Personal skills** | `~/.copilot/skills/` |
| **Frontmatter** | `name` + `description` + optional `license` |
| **Progressive disclosure** | Yes |
| **Setup command** | `./ravintio-framework/setup.sh copilot` or `.\ravintio-framework\setup.ps1 copilot` |

**Creates:**
```
.github/
├── skills/
│   ├── ravintio-orchestrator/SKILL.md
│   ├── ravintio-spec-agent/SKILL.md
│   ├── ... (all 8 skills)
│   ├── _ravintio-templates/
│   ├── _ravintio-standards/
│   └── _ravintio-schemas/
├── copilot-workflows/
│   ├── feature-pipeline.md
│   ├── change-pipeline.md
│   └── retrofit.md
├── hooks/
│   └── copilot.mjs          ← gate-write + check-design adapter
└── copilot-instructions.md
```

---

### Windsurf (Codeium)

| Item | Detail |
|------|--------|
| **Skill discovery** | `.windsurf/skills/{name}/SKILL.md` |
| **Workflow discovery** | None - rules are embedded in `.windsurfrules` |
| **Boot file** | `.windsurfrules` (project root - always applied by Cascade) |
| **Frontmatter** | `name` + `description` required |
| **Progressive disclosure** | Yes |
| **Setup command** | `./ravintio-framework/setup.sh windsurf` or `.\ravintio-framework\setup.ps1 windsurf` |

**Creates:**
```
.windsurf/
└── skills/
    ├── ravintio-orchestrator/SKILL.md
    ├── ravintio-spec-agent/SKILL.md
    ├── ... (all 8 skills)
    ├── _ravintio-templates/
    ├── _ravintio-standards/
    └── _ravintio-schemas/
.windsurfrules
```

---

### Cline

> **Note:** Roo Code support has been dropped. Roo Code was sunset on 02 May 2026 and had no hook API. Use `cline` for Cline-based setups.

| Item | Detail |
|------|--------|
| **Skill discovery** | `.clinerules/skills/{name}/SKILL.md` |
| **Workflow discovery** | None - instructions are embedded in `.clinerules` |
| **Boot file** | `.clinerules` (project root - always loaded as persistent context) |
| **Frontmatter** | `name` + `description` required |
| **Progressive disclosure** | Yes |
| **Setup command** | `./ravintio-framework/setup.sh cline` or `.\ravintio-framework\setup.ps1 cline` |

**Creates:**
```
.clinerules/
└── skills/
    ├── ravintio-orchestrator/SKILL.md
    ├── ravintio-spec-agent/SKILL.md
    ├── ... (all 8 skills)
    ├── _ravintio-templates/
    ├── _ravintio-standards/
    └── _ravintio-schemas/
.clinerules
```

## Common Patterns Across All Tools

All seven tools share these conventions:
- Skills are folders containing a `SKILL.md` file
- `SKILL.md` must have YAML frontmatter with `name` and `description`
- Tools use **progressive disclosure** - they read frontmatter first, then load the full body on demand
- Personal/global skills in `~/.<tool>/skills/` override project skills
- No tool supports custom scan paths - only their hardcoded directories

---

## After Setup

1. **Commit the generated files** to version control if your team uses the same tool
2. **Re-run the script** after updating any skills, templates, or standards in `ravintio-framework/`
3. **Add to `.gitignore`** if you don't want tool-specific files committed:
   ```
   .claude/
   .cursor/
   .agents/
   .gemini/
   .github/skills/
   .windsurf/
   .clinerules/
   ```

---

---

*Source of truth: `ravintio-framework/` - the generated files are copies.*

