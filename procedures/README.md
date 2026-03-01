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
2. The renderer reads two data sources:
   - **`roles/{role_id}.yaml`** — completion gate checks (`dev_gate` / `qa_gate`)
   - **`project.yaml`** (project root) — project-specific content for all 8 placeholders
3. All placeholders are filled from these sources:
   | Placeholder | Source |
   |-------------|--------|
   | `{{PROJECT_NAME}}` | `project.yaml` → `project_name` (falls back to directory name) |
   | `{{PROJECT_DESCRIPTION}}` | `project.yaml` → `project_description` |
   | `{{SPEC_DOCUMENTS}}` | `project.yaml` → `spec_documents` |
   | `{{ARCHITECTURE_OVERVIEW}}` | `project.yaml` → `architecture_overview` |
   | `{{CODE_CONVENTIONS}}` | `project.yaml` → `code_conventions` |
   | `{{QUICK_REFERENCE}}` | `project.yaml` → `quick_reference` |
   | `{{COMPLETION_GATE_CHECKS}}` | `roles/{role_id}.yaml` → `dev_gate` list |
   | `{{FILE_PATHS}}` | Computed from `team_id` and `role_id` |
4. If `project.yaml` is missing, the installer seeds one from `scaffolds/project.yaml`
5. Any field left empty in `project.yaml` produces a `<!-- TODO -->` marker
6. AI agents read the platform file first, then follow the referenced procedures
7. Use `--force-refresh-links` to regenerate platform docs (existing files are backed up)

## Relationship to Checklists

The `teams/checklists/*.yaml` files are the **machine-readable** workflow definitions
with exact commands, paths, and automation hooks. The procedure docs here are the
**human-readable** equivalents that AI agents follow conversationally.

Both must stay in sync. If a checklist changes, update the corresponding procedure.
