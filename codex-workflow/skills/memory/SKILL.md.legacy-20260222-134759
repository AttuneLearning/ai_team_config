---
name: memory
description: Manage the project memory vault for notes, entities, patterns, and session summaries.
---

# Memory Skill

Use this skill when the user asks to capture knowledge, search prior context, or maintain memory artifacts.

## Team-awareness

Read active team config from `.codex-workflow/config/active-team.json` when present.
Use team `default_paths.memory_root` as the memory base path.

## Actions

### 1. Note (default quick capture)

1. Append timestamped bullet to `<memory_root>/notes.md`:
   - `- **YYYY-MM-DD**: text`
2. Create file if missing.

### 2. Search

1. Search across `<memory_root>/` for keywords.
2. Check memory indexes.
3. Return matching files with one-line relevance.

### 3. Add Entity

1. Use `<memory_root>/templates/entity-template.md`.
2. Create `<memory_root>/entities/{slug}.md`.
3. Update `<memory_root>/entities/index.md` and `<memory_root>/memory-log.md`.

### 4. Add Pattern

1. Use `<memory_root>/templates/pattern-template.md`.
2. Create `<memory_root>/patterns/{slug}.md`.
3. Update `<memory_root>/patterns/index.md` and `<memory_root>/memory-log.md`.

### 5. Add Session Summary

1. Use `<memory_root>/templates/session-template.md`.
2. Create `<memory_root>/sessions/YYYY-MM-DD-{slug}.md`.
3. Update `<memory_root>/memory-log.md`.

### 6. Status

1. Read `<memory_root>/memory-log.md`.
2. Count entities, patterns, and sessions.
3. Show recent additions.

## Conventions

- Prefer concise entries.
- Use lowercase hyphenated slugs.
- Use wiki links where the project already uses them.
