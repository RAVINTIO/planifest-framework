# Cursor - tool configuration
# https://docs.cursor.com
#
# Skills:    .cursor/skills/{name}/SKILL.md       (auto-discovered)
# Workflows: embedded in .cursor/rules/*.mdc      (Cursor uses rules, not separate workflows)
# Boot file: .cursor/rules/ravintio.mdc

@{
    SkillsDir        = '.cursor\skills'
    WorkflowsDir     = ''
    BootFile         = '.cursor\rules\ravintio.mdc'
    BootTemplate     = 'ravintio-framework/templates/cursor-boot.md'

    # Enforcement — Tier 1: native hooks adapter (REQ-009)
    Tier             = 1
    HookAdapterSrc   = 'hooks\adapters\cursor.mjs'
    HookAdapterDest  = '.cursor\hooks\adapters\cursor.mjs'
    HooksInstallDir  = '.cursor\hooks'
    SettingsFile     = '.cursor\settings.json'

    # Register check-design for beforeSubmitPrompt in addition to gate-write for PreToolUse (REQ-018)
    BeforeSubmitHook = $true
}
