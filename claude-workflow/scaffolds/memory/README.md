# Memory Vault

Extended memory system for Claude Code sessions. Obsidian-compatible.

## Structure

```
memory/
├── context/         # Project background and fundamentals
├── entities/        # System/component documentation
├── patterns/        # Established conventions
├── sessions/        # Session summaries and decisions
├── templates/       # Templates for new entries
├── prompts/         # Tracked prompts and team configs
│   ├── team-configs/
│   ├── agents/
│   ├── tasks/
│   └── workflows/
├── index.md         # Main vault index
└── memory-log.md    # Activity log
```

## Skills

- `/memory` - Add entities, patterns, sessions
- `/context` - Load relevant context before implementing

## Usage

### On Session Start

Read relevant context:
- `memory/context/project-overview.md`
- `memory/context/tech-stack.md`
- `memory/memory-log.md` (recent activity)

### During Work

When discovering something important:
- Add entities to `memory/entities/`
- Document patterns in `memory/patterns/`

### On Session End

For significant sessions:
- Create summary in `memory/sessions/`
- Update `memory/memory-log.md`

## Wikilinks

Use Obsidian wikilink syntax:
```markdown
[[context/project-overview]]
[[entities/some-component]]
[[patterns/some-pattern]]
```
