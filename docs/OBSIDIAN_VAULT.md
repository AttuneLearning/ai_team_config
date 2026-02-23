# Obsidian Vault Maintenance (`./memory/`)

This project standardizes on:
- `./memory/` for local team memory/context
- `./dev_communication/` for shared communication and architecture artifacts

The `ai_team_config` installer treats `./memory/` as an Obsidian-friendly vault and keeps a stable folder layout.

## Required Vault Layout

```text
memory/
├── index.md
├── memory-log.md
├── context/
│   ├── index.md
│   └── project-overview.md
├── entities/
│   └── index.md
├── patterns/
│   └── index.md
├── sessions/
│   └── index.md
├── prompts/
│   ├── index.md
│   ├── prompt-registry.md
│   ├── agents/index.md
│   ├── tasks/index.md
│   ├── workflows/index.md
│   └── team-configs/index.md
├── templates/
│   ├── context-template.md
│   ├── entity-template.md
│   ├── pattern-template.md
│   ├── prompt-template.md
│   └── session-template.md
└── team-configs/
    ├── _template.json
    └── index.md
```

## Maintenance Rules

1. Do not store `dev_communication` data in `memory/`; keep cross-team artifacts in `./dev_communication/`.
2. Do not remove index files; they are navigation anchors for Obsidian and agents.
3. Use templates in `memory/templates/` for new entities, patterns, sessions, and context notes.
4. Update `memory/memory-log.md` when adding durable entries (entity/pattern/session/context/team-config).
5. Keep names lowercase with hyphens for file slugs.
6. Preserve existing files during re-install; installer may seed missing scaffold files but will not overwrite existing notes.

## Installer Behavior

- Fresh install: copies the full scaffold from `ai_team_config/scaffolds/memory/`.
- Existing `memory/`: creates missing directories and seeds missing baseline files from the scaffold.

