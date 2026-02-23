---
name: memory
description: Manage the extended memory vault
argument-hint: "[search|add|note|status]"
---

# Memory Vault Management

Manage the extended memory vault at `./memory/`.

## Actions

### 1. Quick Note (most common)
**Trigger:** `/memory note <text>` or `/memory add <text>`

Append a timestamped note to `memory/notes.md` (create if missing):
```markdown
- **YYYY-MM-DD**: <text>
```
No index updates needed. Fast, low-ceremony capture.

### 2. Search Memory
**Trigger:** `/memory search <keywords>` or `/memory <keywords>`

- Search across `memory/` using Grep for keywords
- Check index files (`memory/entities/index.md`, `memory/patterns/index.md`)
- Return matching files with summaries

### 3. Add Entity
**Trigger:** `/memory entity <name>`

- Use template: `memory/templates/entity-template.md`
- Create: `memory/entities/[slug].md`
- Update: `memory/entities/index.md` and `memory/memory-log.md`

### 4. Add Pattern
**Trigger:** `/memory pattern <name>`

- Use template: `memory/templates/pattern-template.md`
- Create: `memory/patterns/[slug].md`
- Update: `memory/patterns/index.md` and `memory/memory-log.md`

### 5. Add Session Summary
**Trigger:** `/memory session`

- Use template: `memory/templates/session-template.md`
- Create: `memory/sessions/YYYY-MM-DD-[slug].md`
- Update: `memory/memory-log.md`

### 6. Show Status
**Trigger:** `/memory status`

- Read `memory/memory-log.md`, count files per category, show recent additions

## Wikilink Format

Use Obsidian syntax for cross-references: `[[entities/entity-name]]`, `[[patterns/pattern-name]]`

## Guidelines

- Keep entries concise but complete
- Use consistent naming (lowercase, hyphens)
- For quick captures, use `/memory note` — promote to entity/pattern later if needed
