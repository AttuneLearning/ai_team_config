# Procedures

Universal, platform-agnostic development procedures for all AI agent roles.

These documents define **what to do** and **in what order**. They are referenced by
platform-specific instruction files (CLAUDE.md for Claude Code, AGENTS.md for Codex)
so that the procedures live in one place and are never duplicated.

## Files

| File | Audience | Purpose |
|------|----------|---------|
| `polling-workflow.md` | All roles | Routes "start polling" to the correct lifecycle by role |
| `dev-lifecycle.md` | Dev roles (backend-dev, frontend-dev) | Full development lifecycle: poll → assess → plan → contracts → implement → verify → document → QA handoff |
| `qa-lifecycle.md` | QA roles (backend-qa, frontend-qa) | Full QA lifecycle: poll → validate → verify → review → verdict → complete/iterate |
| `comms-protocol.md` | All roles | Cross-team communication rules, contract ownership, message flow |

## How These Are Used

1. **Install script** renders platform files (CLAUDE.md / AGENTS.md) from `templates/`
2. The renderer fills in known values from install context:
   - `{{PROJECT_NAME}}` — from project root directory name
   - `{{COMPLETION_GATE_CHECKS}}` — from the role yaml's `dev_gate` or `qa_gate` list
   - `{{FILE_PATHS}}` — from team_id and role_id paths
3. Remaining `{{PLACEHOLDER}}` tokens (e.g., `{{PROJECT_DESCRIPTION}}`,
   `{{ARCHITECTURE_OVERVIEW}}`) are replaced with `<!-- TODO -->` markers for the
   user to fill in with project-specific content
4. AI agents read the platform file first, then follow the referenced procedures
5. Role-specific details (commands, paths, issue prefixes) come from `roles/*.yaml`
6. Use `--force-refresh-links` to regenerate platform docs (existing files are backed up)

## Relationship to Checklists

The `teams/checklists/*.yaml` files are the **machine-readable** workflow definitions
with exact commands, paths, and automation hooks. The procedure docs here are the
**human-readable** equivalents that AI agents follow conversationally.

Both must stay in sync. If a checklist changes, update the corresponding procedure.
